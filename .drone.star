config = {
  'acceptance': {
    'suites': {
      'phoenixWebUI1': [
        'webUICreateFilesFolders',
        'webUIDeleteFilesFolders',
        'webUIFavorites',
        'webUIFiles',
        'webUILogin',
        'webUINotifications',
      ],
      'phoenixWebUI2': [
        'webUIPrivateLinks',
        'webUIRenameFiles',
        'webUIRenameFolders',
        'webUITrashbin',
        'webUIUpload',
        'webUIAccount',
        # All tests in the following suites are skipped currently
        # so they won't run now but when they are enabled they will run
        'webUIRestrictSharing',
        'webUISharingAutocompletion',
        'webUISharingInternalGroups',
        'webUISharingInternalUsers',
        'webUISharingPermissionsUsers',
        'webUISharingFilePermissionsGroups',
        'webUISharingFolderPermissionsGroups',
        'webUISharingFolderAdvancedPermissionsGroups',
        'webUIResharing',
        'webUISharingPublic',
        'webUISharingPublicDifferentRoles',
        'webUISharingAcceptShares',
        'webUISharingFilePermissionMultipleUsers',
        'webUISharingFolderPermissionMultipleUsers',
        'webUISharingFolderAdvancedPermissionMultipleUsers',
        'webUISharingNotifications',
      ],
    }
  }
}

def getUITestSuiteNames():
  return config['acceptance']['suites'].keys()

def getUITestSuites():
  return config['acceptance']['suites']

def main(ctx):
  before = [
    linting(ctx),
    unitTests(ctx),
    apiTests(ctx, 'master', 'a3cac3dad60348fc962d1d8743b202bc5f79596b'),
    eosTests(ctx, 'master', 'a3cac3dad60348fc962d1d8743b202bc5f79596b'),
  ] + acceptance(ctx, 'master', 'f9a0874dc016ee0269c698914ef3f2c75ce3e2e6')

  stages = [
    docker(ctx, 'amd64'),
    docker(ctx, 'arm64'),
    docker(ctx, 'arm'),
    binary(ctx, 'linux'),
    binary(ctx, 'darwin'),
    binary(ctx, 'windows'),
  ]

  after = [
    manifest(ctx),
    changelog(ctx),
    readme(ctx),
    badges(ctx),
    website(ctx),
  ]

  return before + stages + after

def linting(ctx):
  return {
    'kind': 'pipeline',
    'type': 'docker',
    'name': 'linting',
    'platform': {
      'os': 'linux',
      'arch': 'amd64',
    },
    'steps':
      generate() + [
      {
        'name': 'vet',
        'image': 'webhippie/golang:1.13',
        'pull': 'always',
        'commands': [
          'make vet',
        ],
        'volumes': [
          {
            'name': 'gopath',
            'path': '/srv/app',
          },
        ],
      },
      {
        'name': 'staticcheck',
        'image': 'webhippie/golang:1.13',
        'pull': 'always',
        'commands': [
          'make staticcheck',
        ],
        'volumes': [
          {
            'name': 'gopath',
            'path': '/srv/app',
          },
        ],
      },
      {
        'name': 'lint',
        'image': 'webhippie/golang:1.13',
        'pull': 'always',
        'commands': [
          'make lint',
        ],
        'volumes': [
          {
            'name': 'gopath',
            'path': '/srv/app',
          },
        ],
      },
    ],
    'trigger': {
      'ref': [
        'refs/heads/master',
        'refs/tags/**',
        'refs/pull/**',
      ],
    },
  }

def unitTests(ctx):
  return {
    'kind': 'pipeline',
    'type': 'docker',
    'name': 'unitTests',
    'platform': {
      'os': 'linux',
      'arch': 'amd64',
    },
    'steps':
      generate() +
      build() + [
      {
        'name': 'test',
        'image': 'webhippie/golang:1.13',
        'pull': 'always',
        'commands': [
          'make test',
        ],
        'volumes': [
          {
            'name': 'gopath',
            'path': '/srv/app',
          },
        ],
      },
      {
        'name': 'codacy',
        'image': 'plugins/codacy:1',
        'pull': 'always',
        'settings': {
          'token': {
            'from_secret': 'codacy_token',
          },
        },
      },
    ],
    'trigger': {
      'ref': [
        'refs/heads/master',
        'refs/tags/**',
        'refs/pull/**',
      ],
    },
  }
  
def getEosSetup():
  return [
    {
      'name': 'quark-1',
      'image': 'owncloud/eos-qdb',
      'pull': 'always',
      'detach': True,
      'environment': {
        'EOS_QDB_DIR': "/var/lib/quarkdb/eosns",
        'EOS_QDB_PORT': "7777",
        'EOS_QDB_MODE': "raft",
        'EOS_QDB_CLUSTER_ID': "3d659c1a-e70f-43f0-bed4-941a2ca0765b",
        'EOS_QDB_NODES': "quark-1.testnet:7777,quark-2.testnet:7777,quark-3.testnet:7777",
      },

      'volumes': [
        {
          'name': 'qdb1',
          'path': '/var/lib/quarkdb'
        },
      ]
    },
    {
      'name': 'quark-2',
      'image': 'owncloud/eos-qdb',
      'pull': 'always',
      'detach': True,
      'environment': {
        'EOS_QDB_DIR': "/var/lib/quarkdb/eosns",
        'EOS_QDB_PORT': "7777",
        'EOS_QDB_MODE': "raft",
        'EOS_QDB_CLUSTER_ID': "3d659c1a-e70f-43f0-bed4-941a2ca0765b",
        'EOS_QDB_NODES': "quark-1.testnet:7777,quark-2.testnet:7777,quark-3.testnet:7777",
      },

      'volumes': [
        {
          'name': 'qdb2',
          'path': '/var/lib/quarkdb'
        },
      ]
    },
    {
      'name': 'quark-3',
      'image': 'owncloud/eos-qdb',
      'pull': 'always',
      'detach': True,
      'environment': {
        'EOS_QDB_DIR': "/var/lib/quarkdb/eosns",
        'EOS_QDB_PORT': "7777",
        'EOS_QDB_MODE': "raft",
        'EOS_QDB_CLUSTER_ID': "3d659c1a-e70f-43f0-bed4-941a2ca0765b",
        'EOS_QDB_NODES': "quark-1.testnet:7777,quark-2.testnet:7777,quark-3.testnet:7777",
      },

      'volumes': [
        {
          'name': 'qdb3',
          'path': '/var/lib/quarkdb'
        },
      ]
    },
    {
      'name': 'mgm-master',
      'image': 'owncloud/eos-mgm',
      'pull': 'always',
      'detach': True,
      'environment': {
        'EOS_SET_MASTER': 1,
        'EOS_MQ_URL': 'mq-master.testnet',
        'EOS_MGM_ALIAS': 'mgm-master.testnet',
        'EOS_QDB_NODES': 'quark-1.testnet:7777 quark-2.testnet:7777 quark-3.testnet:7777',
        'EOS_LDAP_HOST': 'ldap.testnet:389',
        'EOS_GEOTAG': 'test',
        'EOS_INSTANCE_NAME': 'eostest',
        'EOS_MAIL_CC': 'eos@localhost',
        'EOS_USE_QDB': 1,
        'EOS_USE_QDB_MASTER': 1,
        'EOS_NS_ACCOUNTING': 1,
        'EOS_SYNCTIME_ACCOUNTING': 1,
        'EOS_UTF8': 1,
      },
      'volumes': [
        {
          'name': 'eoslogs',
          'path': '/var/eos/logs'
        },
        {
          'name': 'eosconfig',
          'path': '/var/eos/config'
        },
        {
          'name': 'eosnq',
          'path': '/var/eos/ns-queue'
        },
      ]
    },
    {
      'name': 'mq-master',
      'image': 'owncloud/eos-mq',
      'pull': 'always',
      'detach': True,
      'environment': {
        'EOS_SET_MASTER': 1,
        'EOS_MQ_URL': 'mq-master.testnet',
        'EOS_MGM_ALIAS': 'mgm-master.testnet',
        'EOS_QDB_NODES': 'quark-1.testnet:7777 quark-2.testnet:7777 quark-3.testnet:7777',
        'EOS_LDAP_HOST': 'ldap.testnet:389',
        'EOS_GEOTAG': 'test',
        'EOS_INSTANCE_NAME': 'eostest',
        'EOS_MAIL_CC': 'eos@localhost',
        'EOS_USE_QDB': 1,
        'EOS_USE_QDB_MASTER': 1,
        'EOS_NS_ACCOUNTING': 1,
        'EOS_SYNCTIME_ACCOUNTING': 1,
        'EOS_UTF8': 1,
      },
      'volumes': [
        {
          'name': 'eoslogs',
          'path': '/var/eos/logs'
        },
        {
          'name': 'eosconfig',
          'path': '/var/eos/config'
        },
        {
          'name': 'eosnq',
          'path': '/var/eos/ns-queue'
        },
      ]
    },
    {
      'name': 'eos-fst',
      'image': 'owncloud/eos-fst',
      'pull': 'always',
      'detach': True,
      'environment': {
        'EOS_SET_MASTER': 1,
        'EOS_MQ_URL': 'mq-master.testnet',
        'EOS_MGM_ALIAS': 'mgm-master.testnet',
        'EOS_QDB_NODES': 'quark-1.testnet:7777 quark-2.testnet:7777 quark-3.testnet:7777',
        'EOS_LDAP_HOST': 'ldap.testnet:389',
        'EOS_GEOTAG': 'test',
        'EOS_INSTANCE_NAME': 'eostest',
        'EOS_MAIL_CC': 'eos@localhost',
        'EOS_USE_QDB': 1,
        'EOS_USE_QDB_MASTER': 1,
        'EOS_NS_ACCOUNTING': 1,
        'EOS_SYNCTIME_ACCOUNTING': 1,
        'EOS_UTF8': 1,
        'EOS_MGM_URL': "root://mgm-master.testnet",
        'LUKSPASSPHRASE': "just-some-rubbish-to-make-sure-fst-entrypoint-does-not-crash",
      },
      'volumes': [
        {
          'name': 'eoslogs',
          'path': '/var/eos/logs'
        },
        {
          'name': 'eosdisks',
          'path': '/disks'
        },
      ]
    },
    {
      'name': 'ocis',
      'image': 'owncloud/eos-ocis',
      'pull': 'always',
      'detach': True,
      'environment': {
        'EOS_MGM_URL': "root://mgm-master.testnet:1094",
        'KONNECTD_IDENTIFIER_REGISTRATION_CONF': "/etc/ocis/identifier-registration.yml",
        'KONNECTD_ISS': "https://ocis:9200",
        'KONNECTD_LOG_LEVEL': "debug",
        'KONNECTD_TLS': '0',
        'PHOENIX_OIDC_AUTHORITY': "https://ocis:9200",
        'PHOENIX_OIDC_METADATA_URL': "https://ocis:9200/.well-known/openid-configuration",
        'PHOENIX_WEB_CONFIG_SERVER': "https://ocis:9200",
        'PROXY_HTTP_ADDR': "0.0.0.0:9200",
        'REVA_OIDC_ISSUER': "https://ocis:9200",
        'OCIS_LOG_LEVEL': "debug",
        'REVA_TRANSFER_EXPIRES': 86400,
        #for reva-storage-eos use eos as storage driver the reason is that we cannot set REVA_STORAGE_EOS_LAYOUT to empty
        #but also we don't want to have it set to anything to remove one layer in the eos folder structure
        #default is `REVA_STORAGE_EOS_LAYOUT="{{substr 0 1 .Username}}/{{.Username}}"` for reva-storage-home
        #and `REVA_STORAGE_EOS_LAYOUT="{{substr 0 1 .Username}}"` for reva-storage-eos
        #but that gives us an extra layer in the eos file-system: /eos/dockertest/reva/users/e/einstein/file.txt
        #and that again is annoying when the tests try to delete user data
        'REVA_STORAGE_EOS_DRIVER': "eos",
        'REVA_STORAGE_EOS_DATA_DRIVER': "eos",
        'REVA_STORAGE_HOME_DRIVER': "eoshome",
        'REVA_STORAGE_HOME_MOUNT_ID': "1284d238-aa92-42ce-bdc4-0b0000009158",
        'REVA_STORAGE_HOME_DATA_DRIVER': "eoshome",
        'REVA_STORAGE_EOS_MASTER_URL': "root://mgm-master.testnet:1094",
        'REVA_STORAGE_EOS_SLAVE_URL': "root://mgm-master.testnet:1094",
        'REVA_STORAGE_EOS_NAMESPACE': "/eos/dockertest/reva/users",
        'REVA_STORAGE_EOS_LAYOUT': "{{.Username}}",
        'DAV_FILES_NAMESPACE': "/eos/",
        'REVA_LDAP_HOSTNAME': 'ldap',
        'REVA_LDAP_PORT': 636,
        'REVA_LDAP_BIND_PASSWORD': 'admin',
        'REVA_LDAP_BIND_DN': 'cn=admin,dc=owncloud,dc=com',
        'REVA_LDAP_BASE_DN': 'dc=owncloud,dc=com',
        'REVA_LDAP_SCHEMA_UID': 'uid',
        'REVA_LDAP_SCHEMA_MAIL': 'mail',
        'REVA_LDAP_SCHEMA_DISPLAYNAME': 'displayname',
        'LDAP_URI': 'ldap://ldap',
        'LDAP_BINDDN': 'cn=admin,dc=owncloud,dc=com',
        'LDAP_BINDPW': 'admin',
        'LDAP_BASEDN': 'dc=owncloud,dc=com'
      },
      'volumes': [
        {
          'name': 'config',
          'path': '/config'
        },
      ]
    },
  ]

def eosTests(ctx, coreBranch = 'master', coreCommit = ''):
  return {
    'kind': 'pipeline',
    'type': 'docker',
    'name': 'eos-apiTests',
    'platform': {
      'os': 'linux',
      'arch': 'amd64',
    },
    'steps':
      getEosSetup() +
      [{
        'name': 'oC10APIAcceptanceTests',
        'image': 'owncloudci/php:7.2',
        'pull': 'always',
        'environment' : {
          'TEST_SERVER_URL': 'http://ocis-server:9140',
          'OCIS_REVA_DATA_ROOT': '/srv/app/tmp/reva/',
          'SKELETON_DIR': '/srv/app/tmp/testing/data/apiSkeleton',
          'TEST_EXTERNAL_USER_BACKENDS':'true',
          'REVA_LDAP_HOSTNAME':'ldap',
          'TEST_OCIS':'true',
          'BEHAT_FILTER_TAGS': '~@skipOnOcis&&~@skipOnOcis-OC-Storage',
        },
        'commands': [
          'git clone -b master --depth=1 https://github.com/owncloud/testing.git /srv/app/tmp/testing',
          'git clone -b %s --single-branch --no-tags https://github.com/owncloud/core.git /srv/app/testrunner' % (coreBranch),
          'cd /srv/app/testrunner',
        ] + ([
          'git checkout %s' % (coreCommit)
        ] if coreCommit != '' else []) + [
          'make test-acceptance-api',
        ],
        'volumes': [{
          'name': 'gopath',
          'path': '/srv/app',
        }]
      },
    ],
    'volumes': [
      {
        'name': 'gopath',
        'temp': {},
      },
      {
        'name': 'eoslogs',
        'host': {
          'path': '/e/master/var/log/eos'
        }
      },
      {
        'name': 'eosconfig',
        'host': {
          'path': '/e/master/var/eos/config'
        }      
      },
      {
        'name': 'eosnq',
        'host': {
          'path': '/e/master/var/eos/ns-queue'
        } 
      },
      {
        'name': 'eosdisks',
        'host': {
          'path': '/e/disks'
        }
      },
      {
        'name': 'qdb1',
        'host': {
          'path': '/e/quark-1/var/lib/quarkdb'
        }
      },
      {
        'name': 'qdb2',
        'host': {
          'path': '/e/quark-2/var/lib/quarkdb'
        }      },
      {
        'name': 'qdb3',
        'host': {
          'path': '/e/quark-3/var/lib/quarkdb'
        }
      },
    ],
    'trigger': {
      'ref': [
        'refs/heads/master',
        'refs/tags/**',
        'refs/pull/**',
      ],
    },
  }

def apiTests(ctx, coreBranch = 'master', coreCommit = ''):
  return {
    'kind': 'pipeline',
    'type': 'docker',
    'name': 'apiTests',
    'platform': {
      'os': 'linux',
      'arch': 'amd64',
    },
    'steps':
      generate() +
      build() +
      ocisServer() + [
      {
        'name': 'oC10APIAcceptanceTests',
        'image': 'owncloudci/php:7.2',
        'pull': 'always',
        'environment' : {
          'TEST_SERVER_URL': 'http://ocis-server:9140',
          'OCIS_REVA_DATA_ROOT': '/srv/app/tmp/reva/',
          'SKELETON_DIR': '/srv/app/tmp/testing/data/apiSkeleton',
          'TEST_EXTERNAL_USER_BACKENDS':'true',
          'REVA_LDAP_HOSTNAME':'ldap',
          'TEST_OCIS':'true',
          'BEHAT_FILTER_TAGS': '~@skipOnOcis&&~@skipOnOcis-OC-Storage',
        },
        'commands': [
          'git clone -b master --depth=1 https://github.com/owncloud/testing.git /srv/app/tmp/testing',
          'git clone -b %s --single-branch --no-tags https://github.com/owncloud/core.git /srv/app/testrunner' % (coreBranch),
          'cd /srv/app/testrunner',
        ] + ([
          'git checkout %s' % (coreCommit)
        ] if coreCommit != '' else []) + [
          'make test-acceptance-api',
        ],
        'volumes': [{
          'name': 'gopath',
          'path': '/srv/app',
        }]
      },
    ],
    'services':
      ldap() +
      redis(),
    'volumes': [
      {
        'name': 'gopath',
        'temp': {},
      },
    ],
    'trigger': {
      'ref': [
        'refs/heads/master',
        'refs/tags/**',
        'refs/pull/**',
      ],
    },
  }

def acceptance(ctx, phoenixBranch, phoenixCommit):
  names = getUITestSuiteNames()
  return [acceptanceTests(name, phoenixBranch, phoenixCommit) for name in names]

def acceptanceTests(suiteName, phoenixBranch = 'master', phoenixCommit = ''):
  suites = getUITestSuites()
  paths = ""
  for path in suites[suiteName]:
    paths = paths + "tests/acceptance/features/" + path + " "

  return {
    'kind': 'pipeline',
    'type': 'docker',
    'name': suiteName,
    'platform': {
      'os': 'linux',
      'arch': 'amd64',
    },
    'steps':
      generate() +
      build() +
      ocisServer() + [
      {
        'name': 'webUITests',
        'image': 'owncloudci/nodejs:11',
        'pull': 'always',
        'environment': {
          'SERVER_HOST': 'https://ocis-server:9200',
          'BACKEND_HOST': 'https://ocis-server:9200',
          'RUN_ON_OCIS': 'true',
          'OCIS_REVA_DATA_ROOT': '/srv/app/tmp/reva',
          'OCIS_SKELETON_DIR': '/srv/app/testing/data/webUISkeleton',
          'PHOENIX_CONFIG': '/drone/src/tests/config/drone/ocis-config.json',
          'LDAP_SERVER_URL': 'ldap://ldap',
          'TEST_TAGS': 'not @skipOnOCIS and not @skip',
          'LOCAL_UPLOAD_DIR': '/uploads',
          'NODE_TLS_REJECT_UNAUTHORIZED': 0,
          'TEST_PATHS': paths,
        },
        'commands': [
          'git clone -b master --depth=1 https://github.com/owncloud/testing.git /srv/app/testing',
          'git clone -b %s --single-branch --no-tags https://github.com/owncloud/phoenix.git /srv/app/phoenix' % (phoenixBranch),
          'cp -r /srv/app/phoenix/tests/acceptance/filesForUpload/* /uploads',
          'cd /srv/app/phoenix',
        ] + ([
          'git checkout %s' % (phoenixCommit)
        ] if phoenixCommit != '' else []) + [
          'yarn install-all',
          'yarn dist',
          'cp -r /drone/src/tests/config/drone/ocis-config.json /srv/app/phoenix/dist/config.json',
          'yarn run acceptance-tests-drone'
        ],
        'volumes': [{
          'name': 'gopath',
          'path': '/srv/app',
        },
        {
          'name': 'uploads',
          'path': '/uploads'
        }]
      },
    ],
    'services':
      ldap() +
      redis() +
      selenium(),
    'volumes': [
      {
        'name': 'gopath',
        'temp': {},
      },
      {
        'name': 'uploads',
        'temp': {}
      }
    ],
    'trigger': {
      'ref': [
        'refs/heads/master',
        'refs/tags/**',
        'refs/pull/**',
      ],
    },
  }

def docker(ctx, arch):
  return {
    'kind': 'pipeline',
    'type': 'docker',
    'name': arch,
    'platform': {
      'os': 'linux',
      'arch': arch,
    },
    'steps':
      generate() +
      build() + [
      {
        'name': 'dryrun',
        'image': 'plugins/docker:18.09',
        'pull': 'always',
        'settings': {
          'dry_run': True,
          'tags': 'linux-%s' % (arch),
          'dockerfile': 'docker/Dockerfile.linux.%s' % (arch),
          'repo': ctx.repo.slug,
        },
        'when': {
          'ref': {
            'include': [
              'refs/pull/**',
            ],
          },
        },
      },
      {
        'name': 'docker',
        'image': 'plugins/docker:18.09',
        'pull': 'always',
        'settings': {
          'username': {
            'from_secret': 'docker_username',
          },
          'password': {
            'from_secret': 'docker_password',
          },
          'auto_tag': True,
          'auto_tag_suffix': 'linux-%s' % (arch),
          'dockerfile': 'docker/Dockerfile.linux.%s' % (arch),
          'repo': ctx.repo.slug,
        },
        'when': {
          'ref': {
            'exclude': [
              'refs/pull/**',
            ],
          },
        },
      },
    ],
    'volumes': [
      {
        'name': 'gopath',
        'temp': {},
      },
    ],
    'depends_on': [
      'linting',
      'unitTests',
      'apiTests',
    ] + getUITestSuiteNames(),
    'trigger': {
      'ref': [
        'refs/heads/master',
        'refs/tags/**',
        'refs/pull/**',
      ],
    },
  }

def binary(ctx, name):
  if ctx.build.event == "tag":
    settings = {
      'endpoint': {
        'from_secret': 's3_endpoint',
      },
      'access_key': {
        'from_secret': 'aws_access_key_id',
      },
      'secret_key': {
        'from_secret': 'aws_secret_access_key',
      },
      'bucket': {
        'from_secret': 's3_bucket',
      },
      'path_style': True,
      'strip_prefix': 'dist/release/',
      'source': 'dist/release/*',
      'target': '/ocis/%s/%s' % (ctx.repo.name.replace("ocis-", ""), ctx.build.ref.replace("refs/tags/v", "")),
    }
  else:
    settings = {
      'endpoint': {
        'from_secret': 's3_endpoint',
      },
      'access_key': {
        'from_secret': 'aws_access_key_id',
      },
      'secret_key': {
        'from_secret': 'aws_secret_access_key',
      },
      'bucket': {
        'from_secret': 's3_bucket',
      },
      'path_style': True,
      'strip_prefix': 'dist/release/',
      'source': 'dist/release/*',
      'target': '/ocis/%s/testing' % (ctx.repo.name.replace("ocis-", "")),
    }

  return {
    'kind': 'pipeline',
    'type': 'docker',
    'name': name,
    'platform': {
      'os': 'linux',
      'arch': 'amd64',
    },
    'steps':
      generate() + [
      {
        'name': 'build',
        'image': 'webhippie/golang:1.13',
        'pull': 'always',
        'commands': [
          'make release-%s' % (name),
        ],
        'volumes': [
          {
            'name': 'gopath',
            'path': '/srv/app',
          },
        ],
      },
      {
        'name': 'finish',
        'image': 'webhippie/golang:1.13',
        'pull': 'always',
        'commands': [
          'make release-finish',
        ],
        'volumes': [
          {
            'name': 'gopath',
            'path': '/srv/app',
          },
        ],
      },
      {
        'name': 'upload',
        'image': 'plugins/s3:1',
        'pull': 'always',
        'settings': settings,
        'when': {
          'ref': [
            'refs/heads/master',
            'refs/tags/**',
          ],
        },
      },
      {
        'name': 'changelog',
        'image': 'toolhippie/calens:latest',
        'pull': 'always',
        'commands': [
          'calens --version %s -o dist/CHANGELOG.md' % ctx.build.ref.replace("refs/tags/v", "").split("-")[0],
        ],
        'when': {
          'ref': [
            'refs/tags/**',
          ],
        },
      },
      {
        'name': 'release',
        'image': 'plugins/github-release:1',
        'pull': 'always',
        'settings': {
          'api_key': {
            'from_secret': 'github_token',
          },
          'files': [
            'dist/release/*',
          ],
          'title': ctx.build.ref.replace("refs/tags/v", ""),
          'note': 'dist/CHANGELOG.md',
          'overwrite': True,
          'prerelease': len(ctx.build.ref.split("-")) > 1,
        },
        'when': {
          'ref': [
            'refs/tags/**',
          ],
        },
      },
    ],
    'volumes': [
      {
        'name': 'gopath',
        'temp': {},
      },
    ],
    'depends_on': [
      'linting',
      'unitTests',
      'apiTests',
    ] + getUITestSuiteNames(),
    'trigger': {
      'ref': [
        'refs/heads/master',
        'refs/tags/**',
        'refs/pull/**',
      ],
    },
  }

def manifest(ctx):
  return {
    'kind': 'pipeline',
    'type': 'docker',
    'name': 'manifest',
    'platform': {
      'os': 'linux',
      'arch': 'amd64',
    },
    'steps': [
      {
        'name': 'execute',
        'image': 'plugins/manifest:1',
        'pull': 'always',
        'settings': {
          'username': {
            'from_secret': 'docker_username',
          },
          'password': {
            'from_secret': 'docker_password',
          },
          'spec': 'docker/manifest.tmpl',
          'auto_tag': True,
          'ignore_missing': True,
        },
      },
    ],
    'depends_on': [
      'amd64',
      'arm64',
      'arm',
      'linux',
      'darwin',
      'windows',
    ],
    'trigger': {
      'ref': [
        'refs/heads/master',
        'refs/tags/**',
      ],
    },
  }

def changelog(ctx):
  repo_slug = ctx.build.source_repo if ctx.build.source_repo else ctx.repo.slug
  return {
    'kind': 'pipeline',
    'type': 'docker',
    'name': 'changelog',
    'platform': {
      'os': 'linux',
      'arch': 'amd64',
    },
    'clone': {
      'disable': True,
    },
    'steps': [
      {
        'name': 'clone',
        'image': 'plugins/git-action:1',
        'pull': 'always',
        'settings': {
          'actions': [
            'clone',
          ],
          'remote': 'https://github.com/%s' % (repo_slug),
          'branch': ctx.build.source if ctx.build.event == 'pull_request' else 'master',
          'path': '/drone/src',
          'netrc_machine': 'github.com',
          'netrc_username': {
            'from_secret': 'github_username',
          },
          'netrc_password': {
            'from_secret': 'github_token',
          },
        },
      },
      {
        'name': 'generate',
        'image': 'webhippie/golang:1.13',
        'pull': 'always',
        'commands': [
          'make changelog',
        ],
      },
      {
        'name': 'diff',
        'image': 'owncloud/alpine:latest',
        'pull': 'always',
        'commands': [
          'git diff',
        ],
      },
      {
        'name': 'output',
        'image': 'owncloud/alpine:latest',
        'pull': 'always',
        'commands': [
          'cat CHANGELOG.md',
        ],
      },
      {
        'name': 'publish',
        'image': 'plugins/git-action:1',
        'pull': 'always',
        'settings': {
          'actions': [
            'commit',
            'push',
          ],
          'message': 'Automated changelog update [skip ci]',
          'branch': 'master',
          'author_email': 'devops@owncloud.com',
          'author_name': 'ownClouders',
          'netrc_machine': 'github.com',
          'netrc_username': {
            'from_secret': 'github_username',
          },
          'netrc_password': {
            'from_secret': 'github_token',
          },
        },
        'when': {
          'ref': {
            'exclude': [
              'refs/pull/**',
            ],
          },
        },
      },
    ],
    'depends_on': [
      'manifest',
    ],
    'trigger': {
      'ref': [
        'refs/heads/master',
        'refs/pull/**',
      ],
    },
  }

def readme(ctx):
  return {
    'kind': 'pipeline',
    'type': 'docker',
    'name': 'readme',
    'platform': {
      'os': 'linux',
      'arch': 'amd64',
    },
    'steps': [
      {
        'name': 'execute',
        'image': 'sheogorath/readme-to-dockerhub:latest',
        'pull': 'always',
        'environment': {
          'DOCKERHUB_USERNAME': {
            'from_secret': 'docker_username',
          },
          'DOCKERHUB_PASSWORD': {
            'from_secret': 'docker_password',
          },
          'DOCKERHUB_REPO_PREFIX': ctx.repo.namespace,
          'DOCKERHUB_REPO_NAME': ctx.repo.name,
          'SHORT_DESCRIPTION': 'Docker images for %s' % (ctx.repo.name),
          'README_PATH': 'README.md',
        },
      },
    ],
    'depends_on': [
      'changelog',
    ],
    'trigger': {
      'ref': [
        'refs/heads/master',
        'refs/tags/**',
      ],
    },
  }

def badges(ctx):
  return {
    'kind': 'pipeline',
    'type': 'docker',
    'name': 'badges',
    'platform': {
      'os': 'linux',
      'arch': 'amd64',
    },
    'steps': [
      {
        'name': 'execute',
        'image': 'plugins/webhook:1',
        'pull': 'always',
        'settings': {
          'urls': {
            'from_secret': 'microbadger_url',
          },
        },
      },
    ],
    'depends_on': [
      'readme',
    ],
    'trigger': {
      'ref': [
        'refs/heads/master',
        'refs/tags/**',
      ],
    },
  }

def website(ctx):
  return {
    'kind': 'pipeline',
    'type': 'docker',
    'name': 'website',
    'platform': {
      'os': 'linux',
      'arch': 'amd64',
    },
    'steps': [
      {
        'name': 'prepare',
        'image': 'owncloudci/alpine:latest',
        'commands': [
          'make docs-copy'
        ],
      },
      {
        'name': 'test',
        'image': 'webhippie/hugo:latest',
        'commands': [
          'cd hugo',
          'hugo',
        ],
      },
      {
        'name': 'list',
        'image': 'owncloudci/alpine:latest',
        'commands': [
          'tree hugo/public',
        ],
      },
      {
        'name': 'publish',
        'image': 'plugins/gh-pages:1',
        'pull': 'always',
        'settings': {
          'username': {
            'from_secret': 'github_username',
          },
          'password': {
            'from_secret': 'github_token',
          },
          'pages_directory': 'docs/',
          'target_branch': 'docs',
        },
        'when': {
          'ref': {
            'exclude': [
              'refs/pull/**',
            ],
          },
        },
      },
      {
        'name': 'downstream',
        'image': 'plugins/downstream',
        'settings': {
          'server': 'https://cloud.drone.io/',
          'token': {
            'from_secret': 'drone_token',
          },
          'repositories': [
            'owncloud/owncloud.github.io@source',
          ],
        },
        'when': {
          'ref': {
            'exclude': [
              'refs/pull/**',
            ],
          },
        },
      },
    ],
    'depends_on': [
      'badges',
    ],
    'trigger': {
      'ref': [
        'refs/heads/master',
        'refs/pull/**',
      ],
    },
  }

def generate():
  return [
    {
      'name': 'generate',
      'image': 'webhippie/golang:1.13',
      'pull': 'always',
      'commands': [
        'make generate',
      ],
      'volumes': [
        {
          'name': 'gopath',
          'path': '/srv/app',
        },
      ],
    }
  ]

def build():
  return [
    {
      'name': 'build',
      'image': 'webhippie/golang:1.13',
      'pull': 'always',
      'commands': [
        'make build',
      ],
      'volumes': [
        {
          'name': 'gopath',
          'path': '/srv/app',
        },
      ],
    },
  ]

def ocisServer():
  return [
    {
      'name': 'ocis-server',
      'image': 'webhippie/golang:1.13',
      'pull': 'always',
      'detach': True,
      'environment' : {
        'REVA_LDAP_HOSTNAME': 'ldap',
        'REVA_LDAP_PORT': 636,
        'REVA_LDAP_BIND_PASSWORD': 'admin',
        'REVA_LDAP_BIND_DN': 'cn=admin,dc=owncloud,dc=com',
        'REVA_LDAP_BASE_DN': 'dc=owncloud,dc=com',
        'REVA_LDAP_SCHEMA_UID': 'uid',
        'REVA_LDAP_SCHEMA_MAIL': 'mail',
        'REVA_LDAP_SCHEMA_DISPLAYNAME': 'displayName',
        'REVA_STORAGE_HOME_DATA_TEMP_FOLDER': '/srv/app/tmp/',
        'REVA_STORAGE_LOCAL_ROOT': '/srv/app/tmp/reva/root',
        'REVA_STORAGE_OWNCLOUD_DATADIR': '/srv/app/tmp/reva/data',
        'REVA_STORAGE_OC_DATA_TEMP_FOLDER': '/srv/app/tmp/',
        'REVA_STORAGE_OWNCLOUD_REDIS_ADDR': 'redis:6379',
        'REVA_OIDC_ISSUER': 'https://ocis-server:9200',
        'REVA_STORAGE_OC_DATA_SERVER_URL': 'http://ocis-server:9164/data',
        'REVA_DATAGATEWAY_URL': 'https://ocis-server:9200/data',
        'REVA_FRONTEND_URL': 'https://ocis-server:9200',
        'PHOENIX_WEB_CONFIG': '/drone/src/tests/config/drone/ocis-config.json',
        'PHOENIX_ASSET_PATH': '/srv/app/phoenix/dist',
        'KONNECTD_IDENTIFIER_REGISTRATION_CONF': '/drone/src/tests/config/drone/identifier-registration.yml',
        'KONNECTD_ISS': 'https://ocis-server:9200',
        'KONNECTD_TLS': 'true',
        'LDAP_URI': 'ldap://ldap',
        'LDAP_BINDDN': 'cn=admin,dc=owncloud,dc=com',
        'LDAP_BINDPW': 'admin',
        'LDAP_BASEDN': 'dc=owncloud,dc=com'
      },
      'commands': [
        'apk add mailcap', # install /etc/mime.types
        'mkdir -p /srv/app/tmp/reva',
        'bin/ocis server'
      ],
      'volumes': [
        {
          'name': 'gopath',
          'path': '/srv/app'
        },
      ]
    },
  ]

def ldap():
  return [
    {
      'name': 'ldap',
      'image': 'osixia/openldap',
      'pull': 'always',
      'environment': {
        'LDAP_DOMAIN': 'owncloud.com',
        'LDAP_ORGANISATION': 'ownCloud',
        'LDAP_ADMIN_PASSWORD': 'admin',
        'LDAP_TLS_VERIFY_CLIENT': 'never',
      },
    }
  ]

def redis():
  return [
    {
      'name': 'redis',
      'image': 'webhippie/redis',
      'pull': 'always',
      'environment': {
        'REDIS_DATABASES': 1
      },
    }
  ]

def selenium():
  return [
    {
      'name': 'selenium',
      'image': 'selenium/standalone-chrome-debug:3.141.59-20200326',
      'pull': 'always',
      'volumes': [{
          'name': 'uploads',
          'path': '/uploads'
      }],
    }
  ]
