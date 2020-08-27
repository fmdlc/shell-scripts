#!/bin/bash
#------------------------------------------------------------
# Run as a cron job and creates an AMI of the current host
#------------------------------------------------------------

AMI_NAME="bastion-amzn-linux-hvm"
AMI_DECRIPTION="Automatically created by a programmed task"
INSTANCE_ID=$(curl -s http://169.254.169.254/1.0/meta-data/instance-id)

aws ec2 create-image --instance-id ${INSTANCE_ID} --name "${AMI_NAME}-$(date +%Y-%m-%d)-${RANDOM}" --description "${AMI_DESCRIPTION}" --no-reboot
logger -t create_bastion_ami.sh -p local1.info "Creating bastion (${INSTANCE_ID}) AMI backup."

exit $?
