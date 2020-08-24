#!/bin/bash

SERVER=${1}

if [ ! -z ${SERVER} ]; then
  ( echo | openssl s_client -connect ${SERVER} 2> /dev/null |  openssl x509 -text ) || printf "Error getting SSL certificate\n" && exit 1
  exit 0
else
  printf "Usage: x509-remote.sh <HOST:PORT>\n\n" 
  exit 1
fi
