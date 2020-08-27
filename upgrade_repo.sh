#!/bin/bash

createrepo --update $HOME/repo/noarch/
s3cmd sync $HOME/repo/* s3://my-rpm-s3-bucket/
exit $?
