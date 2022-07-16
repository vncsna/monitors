#!/usr/bin/bash
set -euo pipefail

wd=$HOME/collab/monitors

token_uri=$(jq --compact-output --raw-output '.token_uri' $wd/service_account.json)
private_key=$(jq --compact-output --raw-output '.private_key' $wd/service_account.json)
client_email=$(jq --compact-output --raw-output '.client_email' $wd/service_account.json)

if [ ! -f $wd/private.pem ]; then
    echo "$private_key" > $wd/private_key.pem
fi

if [ ! -f $wd/jwt_token.json ] || [ $(cat $wd/jwt_token.json | jq '.payload.exp') -le $(date +%s) ]; then
    jwt_token=$(
        jwt encode\
        --secret @$wd/private_key.pem\
        --alg RS256\
        --aud $token_uri\
        --iss $client_email\
        --payload exp=$(date --date '+1 hour' '+%s')\
        --payload scope=https://www.googleapis.com/auth/spreadsheets
    )
    echo $jwt_token | jwt decode --json - | jq > $wd/jwt_token.json

    access_token=$(
        curl\
        --data "grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer"\
        --data "assertion=$jwt_token"\
        --url "$token_uri"
    )
    echo "$access_token" | jq > $wd/access_token.json
fi

cat $wd/access_token.json | jq --raw-output '.access_token'
