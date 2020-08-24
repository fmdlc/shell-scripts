#!/bin/bash
#---------------------------------------------------------------------------------------------
# This script check public IP addresses SSL certificates expiration for a given AWS account.
# Author: Facundo de la Cruz (@_tty0)
#
# Requeriments: 
# - AWS Command line interface: https://aws.amazon.com/cli/
# - nmap: https://nmap.org/ 
# - OpenSSL suite: https://www.openssl.org/
# - Exported AWS_KEY, AWS_SECRET environment variables or ~/.aws/credentials in place.
#---------------------------------------------------------------------------------------------
# Configure OUTFILE and PORTS to scan.
# 
# USAGE:
# ./$0 "<region> "<name filter>"
# i.e.: ./$0 eu-west-1 "*" 
##---------------------------------------------------------------------------------------------
OUTFILE="/tmp/results-$$"
IPLIST="/tmp/ip-list-$$"
PORT="443" 
#----------------------------------------------------------------------------------------------
# List all the public Elastic IP address based on a tag Name filter and region. 
aws ec2 describe-instances --region ${1} --filters "Name=instance-state,Values=running,Name=tag:Name,Values=${2}" \
    --output json | awk '/PublicIp/ {gsub("\"",""); gsub("\,",""); print $2}' | uniq > ${IPLIST}

# Scan Elastic IP address list for open SSL ports
nmap -T3 -sV -iL ${IPLIST} -p ${PORT} -oG ${OUTFILE} &> /dev/null

# Connect against each IP address in list, looking for certificates expiration dates.
for host in $(awk ' {print $2}' ${OUTFILE} | uniq ); do
    SSL=$(echo | openssl s_client -connect ${host}:${PORT} 2>/dev/null | openssl x509 -noout -dates 2> /dev/null)
    [[ ! -z $SSL ]] && echo $host - $SSL
done

rm ${OUTFILE} ${IPLIST}
#-EOF-
