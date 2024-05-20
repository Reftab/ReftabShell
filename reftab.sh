#!/bin/sh

Help()
{
  echo "Reftab API script"
  echo "Make sure api.conf is filled out properly."
  echo "This script requires curl and openssl to work."
  echo
  echo "Syntax: reftab.sh [-m|e|b|h]"
  echo "options:"
  echo "  -m <method>    Method to use: GET, POST, PUT, DELETE"
  echo "  -e <endpoint>  Endpoint: assets, loans"
  echo "  -b <body>      Body: JSON string of data to send via PUT or POST"
  echo "  -h             Print this Help."
  echo
}

while getopts m:e:b:h flag
do
  case "${flag}" in
    m) METHOD=${OPTARG};;
    e) ENDPOINT=${OPTARG};;
    b) BODY=${OPTARG};;
    h) Help
       exit;;
  esac
done

if ! [ -x "$(command -v openssl)" ]; then
  echo 'Error: openssl is not installed.' >&2
  exit 1
fi

if ! [ -x "$(command -v curl)" ]; then
  echo 'Error: curl is not installed.' >&2
  exit 1
fi

eval $(grep '^\[\|^#' "api.conf" -v | while read line
  do echo $line
done)

if [ -z "$PUBLICKEY" ] || [ -z "$SECRETKEY" ]; then
  echo "Missing keys" >&2
  exit 1
fi

if [ -p /dev/stdin ] && [ -z "$BODY" ]; then
  BODY=$(cat /dev/stdin)
fi

if [ -z $ENDPOINT ]; then
  echo "Missing Endpoint" >&2
  exit 1
fi
if [ -z $METHOD ]; then
  METHOD="GET"
fi
if [ "$METHOD" = "PUT" ] || [ "$METHOD" = "POST" ] && [ -z "$BODY" ]; then
  echo "PUT and POST require a body" >&2
  exit 1
fi

URL="https://www.reftab.com/api/$ENDPOINT"
DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

if [ -z "$BODY" ]; then
  CONTENTHASH=""
  CONTENTTYPE=""
else
  CONTENTHASH=$(printf "%s" "$BODY" | openssl md5)
  CONTENTHASH=${CONTENTHASH##* }
  CONTENTTYPE="application/json"
fi

SIGNATURETOSIGN="$METHOD
$CONTENTHASH
$CONTENTTYPE
$DATE
$URL"

TOKEN=$(printf "%s" "$SIGNATURETOSIGN" | openssl dgst -sha256 -hmac "$SECRETKEY")
TOKEN=${TOKEN##* }
TOKEN=$(printf "%s" "$TOKEN" | openssl base64 -A)

curl "$URL" \
  -H "x-rt-date: $DATE" \
  -H "authorization: RT $PUBLICKEY:$TOKEN" \
  -H "Cache-Control: no-cache" \
  -X "$METHOD" \
  -H "content-type: $CONTENTTYPE" \
  --data-raw "$BODY" \
  --compressed \
  -s

wait
