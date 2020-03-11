package svc

import (
	"context"
	"net/http"
	"strconv"

	"github.com/go-chi/chi"
	"github.com/owncloud/ocis-pkg/v2/log"
	"github.com/owncloud/ocis-thumbnails/pkg/config"
	"github.com/owncloud/ocis-thumbnails/pkg/thumbnails"
	"github.com/owncloud/ocis-thumbnails/pkg/thumbnails/imgsource"
	"github.com/owncloud/ocis-thumbnails/pkg/thumbnails/storage"
)

// Service defines the extension handlers.
type Service interface {
	ServeHTTP(http.ResponseWriter, *http.Request)
	Thumbnails(http.ResponseWriter, *http.Request)
}

// NewService returns a service implementation for Service.
func NewService(opts ...Option) Service {
	options := newOptions(opts...)

	m := chi.NewMux()
	m.Use(options.Middleware...)

	svc := Thumbnail{
		config: options.Config,
		mux:    m,
		manager: thumbnails.NewSimpleManager(
			storage.NewFileSystemStorage(
				options.Config.FileSystemStorage,
				options.Logger,
			),
			options.Logger,
		),
		source: imgsource.NewWebDavSource(options.Config.WebDavSource),
		logger: options.Logger,
	}

	m.Route(options.Config.HTTP.Root, func(r chi.Router) {
		r.Get("/thumbnails", svc.Thumbnails)
	})

	return svc
}

// Thumbnail implements the business logic for Service.
type Thumbnail struct {
	config  *config.Config
	mux     *chi.Mux
	manager thumbnails.Manager
	source  imgsource.Source
	logger  log.Logger
}

// ServeHTTP implements the Service interface.
func (g Thumbnail) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	g.mux.ServeHTTP(w, r)
}

// Thumbnails provides the endpoint to retrieve a thumbnail for an image
func (g Thumbnail) Thumbnails(w http.ResponseWriter, r *http.Request) {
	query := r.URL.Query()
	width, _ := strconv.Atoi(query.Get("width"))
	height, _ := strconv.Atoi(query.Get("height"))
	fileType := query.Get("type")
	filePath := query.Get("file_path")
	etag := query.Get("etag")

	encoder := thumbnails.EncoderForType(fileType)
	if encoder == nil {
		// TODO: better error responses
		w.WriteHeader(http.StatusBadRequest)
		w.Write([]byte("can't encode that"))
		return
	}
	ctx := thumbnails.Context{
		Width:     width,
		Height:    height,
		ImagePath: filePath,
		Encoder:   encoder,
		ETag:      etag,
	}

	thumbnail := g.manager.GetStored(ctx)
	if thumbnail != nil {
		w.Write(thumbnail)
		return
	}

	auth := r.Header.Get("Authorization")
	sCtx := context.WithValue(r.Context(), imgsource.WebDavAuth, auth)
	// TODO: clean up error handling
	img, err := g.source.Get(sCtx, ctx.ImagePath)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte(err.Error()))
		return
	}
	if img == nil {
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("img is nil"))
		return
	}
	thumbnail, err = g.manager.Get(ctx, img)
	if err != nil {
		w.Write([]byte(err.Error()))
		return
	}

	w.WriteHeader(http.StatusCreated)
	w.Write(thumbnail)
}
