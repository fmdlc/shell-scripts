#!/bin/bash
#--------------------------------------------------------------------------------------------
# This script needs to have all environment keys imported in your keychain.
#--------------------------------------------------------------------------------------------

ENVIRONMENT=$1
DATA=$2

case $ENVIRONMENT in
	prod|PROD)
		GPGID=GPG_KEY_ID
		;;

	stgx|STGX)
		GPGID=GPG_KEY_ID
		;;

	devx|DEVX)
		GPGID=GPG_KEY_ID
		;;
	*)
		printf "Encrypt a secret with a given GPG public key\n\n"
		printf "USAGE: $0 <environment> <data>\n\n"
		printf "Environments:\n\t- prod\n\t- stgx\n\t- qax\n\t- devx\n\t- prod-eu\n\t- perf\n\t- stgxdr\n"
		exit 1
		;;
esac


if [[ -f "$DATA" ]]; then
	cat "$DATA" | gpg --armor --encrypt --trust-model always -r $GPGID
else
	echo -n "$DATA" | gpg --armor --encrypt --trust-model always -r $GPGID
fi

exit $?
