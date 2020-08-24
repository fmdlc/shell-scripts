#!/bin/bash

##---------------------------------------------------------------
## Dump ElasticSearch indexes
## Author: Facu de la Cruz <fmdlc.unix@gmail.com>
##---------------------------------------------------------------
##
## Requires:
## elastricdump Node.js module:
##   - https://github.com/elasticsearch-dump/elasticsearch-dump

SOURCE_ENDPOINT="https://username:password@endpoint:9243"
TARGET_ENDPOINT="https://username:password@endpoint:9200"

PATH="$PATH:$HOME/node_modules/elasticdump/bin/elasticdump"

for indice in $(curl -XGET "https://${SOURCE_ENDPOINT}/_cat/indices?v"  -s | awk '{print $3}'); do
	elasticdump	\
		--input="${SOURCE_ENDPOINT}"/$indice \
		--output="${TARGET_ENDPOINT}"/$indice \
		--type=analyzer

	elasticdump	\
		--input="${SOURCE_ENDPOINT}"/$indice \
		--output="${TARGET_ENDPOINT}"/$indice \
		--type=mapping

	elasticdump	\
		--input="${SOURCE_ENDPOINT}"/$indice \
		--output="${TARGET_ENDPOINT}"/$indice \
		--type=data
done;

exit $?
