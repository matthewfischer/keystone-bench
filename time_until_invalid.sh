#!/bin/bash

echo "getting & revoking $1 tokens"
for i in $(eval echo "{1..$1}")
do
    TOKEN=`keystone token-get | grep id | grep -v tenant_id | grep -v user_id | awk '{ print $4 }'` 2> /dev/null
    sleep 1
    curl -s -X DELETE -i -H "X-Auth-Token: $2" "${OS_AUTH_URL}/tokens/${TOKEN}" > /dev/null
    SEC=0
    while true;
    do
      echo "trying for ${SEC} seconds..."
      curl -s -X GET -i -H "X-Auth-Token: $2" "${OS_AUTH_URL}/tokens/${TOKEN}" | grep "HTTP/1.1" | grep -q "04"
      if [ $? -eq 0 ]; then
        echo "finally invalid after ${SEC} seconds"
        break
      fi
      sleep 1
      SEC=$((SEC+1))
    done
done
