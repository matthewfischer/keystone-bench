import os
import sys

from keystoneclient.v3 import client

if len(sys.argv) != 3:
    print "need to pass in host & password"
    sys.exit(1)

KEYSTONE_ENDPOINT = os.environ.get('KEYSTONE_ENDPOINT', 'http://%s:35357/' % sys.argv[1])

try:
    project_scoped = client.Client(
        username='admin',
        password=sys.argv[2],
        project_name='admin',
        auth_url=KEYSTONE_ENDPOINT + 'v3')
except Exception as e:
    sys.exit(1)
print('%s' % project_scoped.auth_token)
sys.exit(0)
