#!/usr/bin/bash
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

set -ex

if [ ! "$(which sjr)" ]; then
   go install storj.io/storj-up@latest
fi

if [ ! "$(which uplink)" ]; then
   go install storj.io/storj/cmd/uplink@latest
fi

storj-up init minimal,db
storj-up scale storagenode 10

docker compose down -v
docker compose up -d

storj-up health
dd if=/dev/random of=data count=10240 bs=1024
sha256sum data > sha256.sum

eval $(storj-up credentials -e)

BUCKET=bucket$RANDOM
uplink mb sj://$BUCKET
uplink cp data sj://$BUCKET/data

rm data
uplink cp sj://$BUCKET/data data 
sha256sum -c sha256.sum
docker compose down
