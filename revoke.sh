#!/bin/bash

echo "getting & revoking $1 tokens"
for i in $(eval echo "{1..$1}")
do
    TOKEN=`keystone token-get | grep id | grep -v tenant_id | grep -v user_id | awk '{ print $4 }'`
    curl -X DELETE -i -H "X-Auth-Token: $2" "${OS_AUTH_URL}/tokens/${TOKEN}"
done
