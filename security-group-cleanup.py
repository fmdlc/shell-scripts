#!/usr/bin/env python
import sys
import boto
import pprint
from os import environ

# set credentials
ACCESS_KEY=environ['AWS_KEY']
SECRET_KEY=environ['AWS_SECRET']

# dry run or execute?
dry_run = True
if len(sys.argv) > 1 and sys.argv[1] == '--delete':
    dry_run = False

ec2 = boto.connect_ec2(ACCESS_KEY, SECRET_KEY)

# all security groups in the account
all_groups = {g.name for g in ec2.get_all_security_groups()}

# security groups that are attached to running/stopped instances
res = ec2.get_all_instances(filters={'instance-state-name': ['running', 'stopped']})
groups_in_use = {g.name for r in res for i in r.instances for g in i.groups}

# we'll get rid of these (excluding 'default' too)
delete_candidates = all_groups - groups_in_use.union({'default'})

pp = pprint.PrettyPrinter(indent=4)

if dry_run:
    print "The list of security groups to be removed is below."
    print "Run this again with `--delete` to remove them"
    pp.pprint(sorted(delete_candidates))
    print "Total of %d groups targeted for removal." % (len(delete_candidates))
else:
    print "We will now delete security groups identified to not be in use."
    for group in delete_candidates:
        if ec2.get_all_instances(filters={'security-group-name': group }):
            print "Security group %s exists", group
        else:
            #ec2.delete_security_group(group)
            print "We have deleted the following groups:"
            pp.pprint(sorted(delete_candidates))

# For each security group in the total list, if not in the "used" list, flag for deletion
# If running with a "--delete" flag, delete the ones flagged.
