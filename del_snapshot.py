#!/usr/bin/env python
#-----------------------------------------------------------------------------------------------------------------------
# Delete AWS Snapshots based on selection criterias
# ./$0 [time in days]
#
#-----------------------------------------------------------------------------------------------------------------------
# Set your own configuration criterias here.
# AWS_OWNER is your 12 digits account numerical ID, the AWS_DEFAULT_REGION parameter configure the region where your AWS
# instances are running
#-----------------------------------------------------------------------------------------------------------------------
AWS_OWNER='[AWS-ACCOUNT]'
AWS_DEFAULT_REGION='[AWS-REGION]

# Set selection filter here
filters = {
    #'description': 'Created by CreateImage*'
    'description': '*'
}
#-----------------------------------------------------------------------------------------------------------------------
import datetime
import sys
from dateutil import parser
from boto import ec2
from boto.exception import EC2ResponseError

try:
    days = int(sys.argv[1])
except IndexError:
    days = 300

snap_count = 0
error_count = 0

print "Deleting snapshots older than %d days\n" %(days)
connection=ec2.connect_to_region(AWS_DEFAULT_REGION)
ebsAllSnapshots=connection.get_all_snapshots(filters=filters,owner="self")
timeLimit=datetime.datetime.now() - datetime.timedelta(days)

for snapshot in ebsAllSnapshots:
    if parser.parse(snapshot.start_time).date() <= timeLimit.date():
        try:
            connection.delete_snapshot(snapshot.id,dry_run=False)
            print "[RUNNING] Deleting %s - Created: %s"  %(snapshot.id, snapshot.start_time)
            snap_count +=1 
        except EC2ResponseError:
            error_count +=1

print "[DONE] I deleted %d snapshots and I got %d errors." %(snap_count,error_count)
exit(0)
# EOF
