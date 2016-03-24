#!/bin/bash

set -e

function usage {
    echo "./benchmark.sh <Host> <Admin Password>"
    echo "<Host> should be the keystone host or LB endpoint you want to test without port or version"
    echo "<Admin Password> is the password for the admin user"
}

echo "Pre-cleaning"
rm -f auth.json

if [ $# -ne 2 ]; then
    usage
    exit 1
fi

HOST=$1
PASSWORD=$2

echo "Checking connectivity to $HOST"
ping -c1 $HOST
if [ $? -ne 0 ]; then
    echo "Could not reach $HOST, did you pass the right arguments"
    usage
    exit 1
fi

which ab > /dev/null
if [ $? -ne 0 ]; then
    echo "ab is not installed. apt-get install apache-utils"
    exit 1
fi

echo "Creating a token to run benchmarks with..."
ADMIN_TOKEN=`python authenticate.py $HOST $PASSWORD`
if [ $? -ne 0 ]; then
    echo "Failed to get admin token, bailing"
    exit 1
fi
SUBJECT_TOKEN=`python authenticate.py $HOST $PASSWORD`
if [ $? -ne 0 ]; then
    echo "Failed to get subject token, bailing"
    exit 1
fi
echo "Admin token: $ADMIN_TOKEN"
echo "Subject token: $SUBJECT_TOKEN"

echo "Setting up auth.json"
echo "{ \"auth\": { \"identity\": { \"methods\": [ \"password\" ], \"password\": { \"user\": { \"domain\": { \"id\": \"default\" }, \"password\": \"${PASSWORD}\", \"name\": \"admin\" } } }, \"scope\": { \"project\": { \"domain\": { \"id\": \"default\" }, \"name\": \"admin\" } } } }" > auth.json


echo "Warming up Apache..."
ab -c 100 -n 1000 -T 'application/json' http://$HOST:35357/ > /dev/null 2>&1

echo "Benchmarking token creation..."
ab -r -c 1 -n 200 -p auth.json -T 'application/json' http://$HOST:35357/v3/auth/tokens > latest_create_token
if grep -q 'Non-2xx' latest_create_token; then
    echo 'Non-2xx return codes! Aborting.'
fi

echo "Benchmarking token validation..."
ab -r -c 1 -n 1000 -T 'application/json' -H "X-Auth-Token: $ADMIN_TOKEN" -H "X-Subject-Token: $SUBJECT_TOKEN" http://$HOST:35357/v3/auth/tokens > latest_validate_token
if grep -q 'Non-2xx' latest_validate_token; then
    echo 'Non-2xx return codes! Aborting.'
fi

echo "Benchmarking token creation concurrently..."
ab -r -c 20 -n 1000 -p auth.json -T 'application/json' http://$HOST:35357/v3/auth/tokens > latest_create_token_concurrent
if grep -q 'Non-2xx' latest_create_token_concurrent; then
    echo 'WARNING: Non-2xx return codes!'
fi

echo "Benchmarking token validation concurrency..."
ab -r -c 20 -n 5000 -T 'application/json' -H "X-Auth-Token: $ADMIN_TOKEN" -H "X-Subject-Token: $SUBJECT_TOKEN" http://$HOST:35357/v3/auth/tokens > latest_validate_token_concurrent
if grep -q 'Non-2xx' latest_validate_token_concurrent; then
    echo 'WARNING: Non-2xx return codes!'
fi

echo "Cleaning up"
rm -f auth.json
