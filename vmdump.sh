#!/bin/bash
# vmdump.sh: Dump Virtual Machines XML configuration file
# Author: Facundo M. de la Cruz <fdelacruz@dc-solutions.com.ar>
VMLIST=$(/usr/bin/virsh -q list | awk '{print $2}')
XMLSTORE='/var/backup/VMdumps'
DATE=$(date +%Y-%m-%d)

[ -d $XMLSTORE/$DATE ] && mkdir $XMLSTORE/$DATE

for vm in ${VM_LIST[*]}; do 
        /usr/bin/virsh dumpxml $vm > $XMLSTORE/$DATE/dump-$vm.xml; \
                || logger -p local1.error "ERROR dumping $vm XML configuration to $XMLSTORE/$DATE"
        logger -p local1.info "Dumping $vm XML configuration to $XMLSTORE/$DATE"
done

exit $?
