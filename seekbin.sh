#!/bin/bash 
#--------------------------------------------------------------------
# Find for setuid binary. 
#
# Name    : seekbin.sh
# Version : 1.0
# License : BSD
# Author  : Facundo M. de la Cruz <fmdlc.unix@gmail.com>
# Date    : April 2012
#--------------------------------------------------------------------
# Install this script in your crontab for daily run. 
#--------------------------------------------------------------------

    _today="/var/log/setuid.today"
_yesterday="/var/log/setuid.yesterday"

hash() 
{
  /usr/bin/sha512sum $1 | awk '{print $1}'
}

if [[ -f $_yesterday ]]; then
  mv $_today $_yesterday
  find / -type f \( -perm -4000 -o -perm -2000 \) -exec ls {} \; 2>/dev/null 1> $_today

  if [[ $(hash $_today) = $(hash $_yesterday) ]]; then
    logger -i -p user.info "Binary check ready. $_today file is equal to $_yesterday file."
  else
    logger -i -p user.warn "Binary check ready. WARNING!!! $_today file differs to $_yesterday file."
  fi
else
  find / -type f \( -perm -4000 -o -perm -2000 \) -exec ls {} \; 2>/dev/null 1> $_today
  echo "---FILE EMPTY---" > $_yesterday
  logger -i -p user.info "Binary check ready. A empty $_yesterday file was created."
fi

exit $?
