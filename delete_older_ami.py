#!/usr/bin/env python
#-----------------------------------------------------------------------------------------------------------------------
# Delete AWS AMIS based on a time period
# ./$0 [time in days]
#-----------------------------------------------------------------------------------------------------------------------
AWS_OWNER='ACCOUNT_ID'
AWS_DEFAULT_REGION='us-east-1'
#-----------------------------------------------------------------------------------------------------------------------
import sys
from datetime import date
from boto import ec2

try:
    days = int(sys.argv[1])
except IndexError:
    days = 300

print "Deleting images older than %d days\n" %(days)

connection=ec2.connect_to_region(AWS_DEFAULT_REGION)
ebsAllImages=connection.get_all_images(filters={'name': 'bastion-amzn-linux-hvm-*'}, owners="self")
count = 0

for image in ebsAllImages:
    if image is None:
        pass

    creation_date = image.creationDate.split('T')[0].split('-')
    split_time = (date.today() - date(int(creation_date[0]), int(creation_date[1]), int(creation_date[2]))).days

    if split_time > days:
        print "{0}: is going to be deregistered".format(image.id)
        if image is not None:
            image.deregister(delete_snapshot=True)
            count = count + 1

print 'AMIs deleted: {0}'.format(count)
exit(0)
# EOF

