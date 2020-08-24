#!/bin/bash 

##############################################################################
#        Copyright (c) J.S Unix Consultants Ltd
##############################################################################
# FILE             : LINUXexplo
# Last Change Date : 03-18-2012
# Author(s)        : Joe Santoro
# Date Started     : 15th April, 2004
# Email            : linuxexplo [ at ] unix-consultants.com
# Web              : http://www.unix-consultants.com/examples/scripts/linux/linux-explorer 
#
# Usage            : ./LINUXexplo [-d] [-v] [-g] [-s] [-h] [-V]
#
# Purpose          : This script is a Linux version of the Solaris explorer 
#                    (SUNWexplo) script.
#
#		    Used to collect information about a linux system build for remote 
#		    support supposes. 
#		    This script is a general purpose script for ALL linux 
#		    systems and therefore NOT tied into any one distro.
#
#############################################################################
#
#############################################################################
#
# Changelog (bug fixes and new features):
#
#                   - SELiunx support improved by FMDLC - 03182012
#                   - Systemd support added by FMDLC    - 03182012
#                   - Added contact form by FMDLC       - 03182012
#                   - Added ARP gathering info by FMDLC - 03182012
#                   - Added kickstart copy by FMDLC     - 03182012
#                   - GPG support added by FMDLC        - 03182012
#                   - Improved release copy by FMDLC    - 03182012
#                   - Improved YUM support by FMDLC     - 03182012
#                   - Improved resolv.conf copy by FMDLC- 03182012
#                   - Added README file by FMDLC        - 03252012
#                   - Added DM discovery by FMDLC       - 04062012
#                   - Added netstat -in by FMDLC        - 04062012
#                   - Improved dmsetup support by FMDLC - 04102012
#                   - Fixed vmstat bug by FMDLC         - 04102012
# 
##############################################################################
#
# J.S UNIX CONSULTANTS LTD  MAKES NO REPRESENTATIONS OR WARRANTIES ABOUT THE 
# SUITABILITY OF THE SOFTWARE, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT 
# LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
# PARTICULAR PURPOSE, OR NON-INFRINGEMENT. J.S UNIX CONSULTANTS LTD SHALL 
# NOT BE LIABLE FOR ANY DAMAGES SUFFERED BY LICENSEE AS A RESULT OF USING,
# MODIFYING OR DISTRIBUTING THIS SOFTWARE OR ITS DERIVATIVES.
#
##############################################################################

  COPYRIGHT="Copyright (c) J.S Unix Consultants Ltd"
  MYVERSION="0.108"
     MYDATE="$(/bin/date +'%Y.%m.%d.%m.%H.%M')" # Date and time now
     MYNAME=$(basename $0)
     WHOAMI=$(/usr/bin/whoami)        # The user running the script
     HOSTID=$(/usr/bin/hostid)        # The Hostid of this server
 MYHOSTNAME=$(/bin/uname -n)          # The hostname of this server
MYSHORTNAME=$(echo $MYHOSTNAME | cut -f 1 -d'.')
    TMPFILE="/tmp/$(basename $0).$$"  # Tempory File
     TOPDIR="/opt/LINUXexplo"         # Top level output directory

VERBOSE=1           # Set to see the scripts progress used 
                    # only if connected  to a terminal session.

FULLSOFT=0          # Set to Verify Software installation
                    # this takes a very long time
              
GPG_ID="57260789"   # GPG/PGP Public key ID. Set to encrypt and 
                    # sing the tarball. 

SUPPORT="bofh@foobar.net" # Support email
#
# Ensure that we are the root user
#
[ ${UID} != 0 ] && echo "You must be root to run this program." && exit 1 

#
# Set the path for the script to run.
#
PATH=/bin:/usr/sbin:/sbin:/usr/sbin:/usr/local/bin:$PATH

if [ -d /opt/VRTSvcs/bin ] ; then
	PATH=$PATH:/opt/VRTSvcs/bin
fi

export PATH

# Remove any temporary files we create
trap '$RM -f $TMPFILE >/dev/null 2>&1; exit' 0 1 2 3 15

##############################################################################
#
#      Function : Usage
#
#         Notes : N/A
#
##############################################################################

function ShowUsage 
{
    	#-------------------------------------------------------------------
    	#   Show help message
    	#-------------------------------------------------------------------
	echo 
	echo "$MYNAME Version $MYVERSION - $COPYRIGHT " 
	echo 
	echo "	usage:   $MYNAME [option] "
	echo 
	echo "		-d      Target directory for explorer files"
  echo "    -g      GPG support"
	echo "		-v      Verbose output"
	echo "		-s      Verify Package Installation"
	echo "		-h      This help message"
	echo "		-V      Version Number of LINUXexplo"
	echo 
	exit 0
}

##############################################################################
#
#      Function : Echo
#
#    Parameters : String to display what function is about to run
#
#        Output : Print what section we are about to collect data for
#
#         Notes : N/A
#
##############################################################################

function Echo () 
{

	if [ -t 0 ] ; then

		if [ ${VERBOSE} -ne 0 ] ; then
			echo "$*"
		fi

		if [ ${VERBOSE} -gt 1 ] ; then
			echo "Press Return to Continue.........."
			read A 
		fi
	fi
}

##############################################################################
#
#      Function : mywhich
#
#    Parameters : name of program 
#
#        Output : path of executable
#
#         Notes : Return back the location of the executable
#		  I need this as not all linux distros have the files
#		  in the same location.
#
##############################################################################

function mywhich ()
{
	local command=$1
	local mypath=$(which $command 2>/dev/null)

	if [  "$mypath" =   "" ] ; then
#		echo "Command $command not found" >> $NOTFNDLOG 2> /dev/null
		echo "NOT_FOUND"
	elif [ ! -x "$mypath" ] ; then
		echo "Command $command not executable" >> $NOTFNDLOG 2> /dev/null
		echo "NOT_FOUND"
	else
		echo "$mypath"
	fi
}

##############################################################################
#
#      Function : findCmds
#
#    Parameters : None
#
#        Output : None 
#
#         Notes :       Goes and find each of the commands I want to use and 
#			stores the information into the various variables which 
#			is the uppercase version of the command itself. 
#
#			I need this as not all linux distros have the files
#			in the same location.
#
##############################################################################

function findCmds 
{
	# Standard commands
            AWK=$(mywhich awk       )
       BASENAME=$(mywhich basename  ) 
            CAT=$(mywhich cat       )
      CHKCONFIG=$(mywhich chkconfig ) 
             CP=$(mywhich cp        )
            CUT=$(mywhich cut       )
          CHMOD=$(mywhich chmod     )
           DATE=$(mywhich date      )
             DF=$(mywhich df        )  
          DMESG=$(mywhich dmesg     )
           ECHO=$(mywhich echo      ) 
           FILE=$(mywhich file      )
           FIND=$(mywhich find      )
           FREE=$(mywhich free      )
           GREP=$(mywhich grep      )
          EGREP=$(mywhich egrep     )
             LS=$(mywhich ls        )
          MKDIR=$(mywhich mkdir     )
           LAST=$(mywhich last      )
         LOCALE=$(mywhich locale    )
         PSTREE=$(mywhich pstree    )
             PS=$(mywhich ps        )
             RM=$(mywhich rm        )
          SLEEP=$(mywhich sleep     )
          MOUNT=$(mywhich mount     )
             MV=$(mywhich mv        )
           SORT=$(mywhich sort      )
             LN=$(mywhich ln        )
      SYSTEMCTL=$(mywhich systemctl )
           TAIL=$(mywhich tail      )
          UNAME=$(mywhich uname     )
         UPTIME=$(mywhich uptime    ) 
            WHO=$(mywhich who       )
            ZIP=$(mywhich zip       )
           GZIP=$(mywhich gzip      ) 
           GAWK=$(mywhich gawk      ) 
            SED=$(mywhich sed       ) 
         GUNZIP=$(mywhich gunzip    )
   # Selinux
       SESTATUS=$(mywhich sestatus  )
      GETSEBOOL=$(mywhich getsebool )
       SEMANAGE=$(mywhich semanage  )
  # Systemd
        SYSTEMD=$(mywhich systemd         )
      SYSTEMCTL=$(mywhich systemctl       )
    SYSTEMDCGLS=$(mywhich systemd-cgls    )
SYSTEMDLOGINCTL=$(mywhich systemd-loginctl)
   # GPG
        GPG_BIN=$(mywhich gpg)
   # Samba
      TESTPARM=$(mywhich testparm ) 
        WBINFO=$(mywhich wbinfo   ) 
   # Apache
     APACHECTL=$(mywhich apachectl  ) 
    APACHE2CTL=$(mywhich apache2ctl ) 
   # Packages
      APTCONFIG=$(mywhich apt-config  ) 
            RPM=$(mywhich rpm         )
         ZYPPER=$(mywhich zypper      )
           DPKG=$(mywhich dpkg        )
     DPKG_QUERY=$(mywhich dpkg-query  )
         EMERGE=$(mywhich emerge      )
            YUM=$(mywhich yum         )
   # Kernel Info
        MODINFO=$(mywhich modinfo     )
         SYSCTL=$(mywhich sysctl      )
          KSYMS=$(mywhich ksyms       )
	# H/W Info
           ACPI=$(mywhich acpi       )
        CARDCTL=$(mywhich cardclt    )  
       DUMPE2FS=$(mywhich dumpe2fs   )
      DMIDECODE=$(mywhich dmidecode  ) 
          FDISK=$(mywhich fdisk	     )	
          BLKID=$(mywhich blkid	     )	
         HDPARM=$(mywhich hdparm     )
       HOSTNAME=$(mywhich hostname   )
         HWINFO=$(mywhich hwinfo     ) 
        HWCLOCK=$(mywhich hwclock    )
          LSMOD=$(mywhich lsmod      ) 
          LSPCI=$(mywhich lspci      )
          LSPNP=$(mywhich lspnp      ) 
        IPVSADM=$(mywhich ipvsadm    ) 
          LSUSB=$(mywhich lsusb      ) 
          LSDEV=$(mywhich lsdev      )
          LSHAL=$(mywhich lshal      )	
         LSRAID=$(mywhich lsraid     )
          MDADM=$(mywhich mdadm      ) 
       PROCINFO=$(mywhich procinfo   )
        POWERMT=$(mywhich powermt    )
       SMARTCTL=$(mywhich smartclt   )
         SFDISK=$(mywhich sfdisk     )
         HWPARM=$(mywhich hwparm     )
        SCSI_ID=$(mywhich scsi_id    )	
       ISCSIADM=$(mywhich iscsiadm   )	
      MULTIPATH=$(mywhich multipath  )
        DMSETUP=$(mywhich dmsetup    )
           NTPQ=$(mywhich ntpq       )
           SYSP=$(mywhich sysp       ) 
        _3DDIAG=$(mywhich 3Ddiag     ) 
           LSHW=$(mywhich lshw       )
        SYSTOOL=$(mywhich systool    )
         SWAPON=$(mywhich swapon     )
	# Disks
            LVM=$(mywhich lvm           )
      LVDISPLAY=$(mywhich lvdisplay     )
            VGS=$(mywhich vgs           )
         PVSCAN=$(mywhich pvs           )
         VGSCAN=$(mywhich vgscan        )
      VGDISPLAY=$(mywhich vgdisplay     )
    LVMDISKSCAN=$(mywhich lvmdiskscan   )
         PVSCAN=$(mywhich pvscan        )
  DEBUGREISERFS=$(mywhich debugreiserfs )  
         HDPARM=$(mywhich hdparm        )  
       EXPORTFS=$(mywhich exportfs      )  
       REPQUOTA=$(mywhich repquota      )  
        TUNE2FS=$(mywhich tune2fs       ) 
	# Veritas FS
      PVDISPLAY=$(mywhich pvdisplay  )
           VXDG=$(mywhich vxdg       )
         VXDISK=$(mywhich vxdisk     )
        VXPRINT=$(mywhich vxprint    )
       VXLICREP=$(mywhich vxlicrep   )
	# Veritas Cluster
       HASTATUS=$(mywhich hastatus  )
          HARES=$(mywhich hares     )
          HAGRP=$(mywhich hagrp     )
         HATYPE=$(mywhich hatype    )
         HAUSER=$(mywhich hauser    )
        LLTSTAT=$(mywhich lltstat   )
      GABCONFIG=$(mywhich gabconfig )
           HACF=$(mywhich hacf      )
	# Redhat Cluster
        CLUSTAT=$(mywhich clustat   )
      CLUSVCADM=$(mywhich clusvcadm )
        MKQDISK=$(mywhich mkqdisk   )
	# CRM Cluster
            CRM=$(mywhich crm       )
        CRM_MON=$(mywhich crm_mon   )
     CRM_VERIFY=$(mywhich crm_verify)
       CIBADMIN=$(mywhich cibadmin  )
	# Network
       IFCONFIG=$(mywhich ifconfig  )
       IWCONFIG=$(mywhich iwconfig  )
        NETSTAT=$(mywhich netstat   )
        NFSSTAT=$(mywhich nfsstat   ) 
          ROUTE=$(mywhich route     ) 
        YPWHICH=$(mywhich ypwhich   )
            IP=$(mywhich ip         )
            ARP=$(mywhich arp       )
        MIITOOL=$(mywhich mii-tool  ) 
       IPTABLES=$(mywhich iptables  )
       IPCHAINS=$(mywhich ipchains  )
        ETHTOOL=$(mywhich ethtool   ) 
          BRCTL=$(mywhich brctl     ) 
	# Tuning
         IOSTAT=$(mywhich iostat   ) 
         VMSTAT=$(mywhich vmstat   ) 
           IPCS=$(mywhich ipcs     )	
       MODPROBE=$(mywhich modprobe )
         DEPMOD=$(mywhich depmod   )
	# Other
       RUNLEVEL=$(mywhich runlevel )
           LSOF=$(mywhich lsof 	   )
            LPQ=$(mywhich lpq      )	
            TAR=$(mywhich tar 	   )
         XVINFO=$(mywhich xvinfo   )
       POSTCONF=$(mywhich postconf )
	# Virtual Server
             XM=$(mywhich xm       )
          VIRSH=$(mywhich virsh    )
	# Gentoo 
      RC_UPDATE=$(mywhich rc-update)
}

##############################################################################
#                   Get the command line options
##############################################################################

while getopts "d:vhgV" OPT
do
    case "$OPT" in
      d)  if [ $OPTARG = "/" ] ; then
            echo "ERROR: root directory selected as target! "
            echo "Exiting."
            exit 1
		      elif [ $OPTARG != "" ] ; then
			      TOPDIR=${OPTARG%%/}
          fi 
		  ;;
      g)  
          GPG=1
      ;;
      v)  VERBOSE=1
      ;;
      s)  FULLSOFT=1
      ;;
      h)  ShowUsage
      ;;
      V)  echo 
	        echo "LINUXexplo Version : $MYVERSION" 
	        echo
	        exit 0
      ;;
    esac

done

##############################################################################
#                               MAIN 
##############################################################################

# Go away and find ALL my commands for this script
findCmds

if [[ ${GPG} -eq 1 ]] && [ ! -x ${GPG_BIN} ]; then
  echo "Sorry your system doesn't have GPG support. Install it before."
  exit 1
fi
   LOGTOP="${TOPDIR}/linux"
   LOGDIR="${LOGTOP}/explorer.${HOSTID}.${MYSHORTNAME}-${MYDATE}"
  TARFILE="${LOGDIR}.tgz"
NOTFNDLOG="${LOGDIR}/command_not_found.out"

if [ ! -d $LOGDIR ] ; then
	/bin/mkdir  -p $LOGDIR
fi

echo 
echo "$MYNAME - $MYVERSION"
echo 
echo "This program will gather system information and can take several"
echo "minutes to finish."
echo 
echo "You must complete some questions before start."
echo "It will produce a .tgz or .tgz.gpg file output and a directory"
echo "on your /opt/LINUXexplo/linux/ directory".
echo 
echo "Please follow the support instruction for submit this information"
echo "For contact the support please send a email to <$SUPPORT>"
echo 
echo "**********************************************************************"
echo "Personal information"
echo "**********************************************************************"
read -p "Company: " COMPANY
read -p "Your name: " NAME
read -p "Email: " EMAIL
read -p "Telephone: " TELEPHONE
read -p "Movil: " MOVIL
read -p "City: " CITY
read -p "Zipcode: " ZIPCODE
read -p "Country: " COUNTRY
echo 
echo "**********************************************************************"
echo "System information"
echo "**********************************************************************"
read -p "Server type (physical/virtual): " SERVER
read -p "Linux distribution: " LINUX
read -p "Problem description (small): " PROBLEM
read -p "System description (small): " SYSTEM
read -p "Enviroment (testing/production/workstation): " ENVIROMENT
echo 
read -p "Are you sure to continue? (Y/n)" REPLY 
if [[ "$REPLY"  = [Yy] ]]; then
    echo 
    Echo "Starting support gathering process."
else
    Echo "Aborting."
    exit 0
fi
echo 
cat << EOF > /tmp/README
-----------------------------------------------------------------------------
$MYNAME - $MYVERSION
-----------------------------------------------------------------------------
This directory contains system configuration information. 
Information was gathered on $MYDATE

Contact support made by: $NAME from $COMPANY
-----------------------------------------------------------------------------
CONTACT INFORMATION
-----------------------------------------------------------------------------
Company  : $COMPANY
Name     : $NAME
Email    : $EMAIL
Telephone: $TELEPHONE
Movil    : $MOVIL
City     : $CITY
Zipcode  : $ZIPCODE
Country  : $COUNTRY
----------------------------------------------------------------------------
SYSTEM INFORMATION
----------------------------------------------------------------------------
Date               : $($DATE "+%Y.%m.%d.%H.%M")
Command Line       : $0 $@
Hostname           : $MYHOSTNAME
Host Id            : $HOSTID 
System type        : $SERVER
Linux distribution : $LINUX
System platafform  : $($UNAME -m)
Kernel Version     : $($UNAME -r)
Eviroment          : $ENVIROMENT
System description : $SYSTEM

Problem description: $PROBLEM
----------------------------------------------------------------------------
Uptime:
$(${UPTIME})

swapon -s:
$($SWAPON -s | $GREP -v "Filename")

vmstat:
$($VMSTAT -t 2> /dev/null || $VMSTAT 2> /dev/null)
----------------------------------------------------------------------------
EOF

Echo "[*] Creating Explorer Directory: $LOGDIR"
if [ -d "$LOGTOP" ]; then
  if [[ "${LOGTOP}" != "/" && "${LOGTOP}" != "/var" && "${LOGTOP}" != "/usr" ]]; then
	  if [ ${VERBOSE} -gt 0 ]; then echo "[*] Removing ${LOGTOP}"; fi
    $RM -rf ${LOGTOP}
  fi
fi

#  make sure this is a linux system
if [ "$($UNAME -s)" != "Linux" ]; then
	echo "ERROR: This script is only for Linux systems "
	exit 1
fi

# Make the directory I'm going to store my files 
if [ ! -d $LOGDIR ]; then
	$MKDIR -p $LOGDIR
	
	if [ $? -ne 0 ]; then
		echo "ERROR: Creating directory $LOGDIR"
		exit 1
	else
		$CHMOD 750 $LOGDIR
	fi
fi

mv /tmp/README ${LOGDIR}/README
echo "$MYVERSION" > ${LOGDIR}/rev

# Create the default directories I'm going to use.
for Dir in etc system disks lp var logs hardware boot clusters virtual
do
	if [ ! -d ${LOGDIR}/${Dir} ]; then
		$MKDIR -p ${LOGDIR}/${Dir}
		if [ $? -ne 0 ]; then
			echo "ERROR: Creating directory $LOGDIR"
			exit 1
		else
			$CHMOD 750 ${LOGDIR}/${Dir}
		fi
	fi
done

##############################################################################
# We need the password file and the group file so that we can work out who 
# owns what file.  
# Notice we are not copying the shadow file !!
##############################################################################

$CP -p /etc/passwd ${LOGDIR}/etc/passwd
$CP -p /etc/group  ${LOGDIR}/etc/group
if [ -f /etc/sudoers ]; then
	$CP -p /etc/sudoers ${LOGDIR}/etc/sudoers
fi

##############################################################################
# Release Section
##############################################################################

Echo "[*] Release Section"

if [ -f "/etc/debian_version" ] || [ -f "/etc/redhat-release" ]; then
  $CP -p "/etc/debian_version" ${LOGDIR}/system 2> /dev/null || $CP -p /etc/redhat-release ${LOGDIR}/system 2> /dev/null
fi

if [ -f /etc/issue ]; then
  $CP -p "/etc/issue" ${LOGDIR}/system/issue
fi

if [ -f /etc/issue.net ]; then
	$CP -p "/etc/issue.net" ${LOGDIR}/etc/issue.net 
fi

if [ -f /etc/motd ]; then
	$CP -p "/etc/motd" ${LOGDIR}/etc/motd
fi

#############################################################################
# Installation kickstart and log copy
#############################################################################

if [ -f "/root/anaconda-ks.cfg" ]; then 
  $MKDIR -p "${LOGDIR}/Installation"
  $CP -p "/root/anaconda-ks.cfg" ${LOGDIR}/Installation/anaconda-ks.cfg
fi

##############################################################################
# Hardware/Proc Section
##############################################################################

Echo "[*] Hardware/Proc Section"

# Collecting information from the proc directory
$MKDIR -p ${LOGDIR}/proc
$FIND /proc -type f -print 2>/dev/null | \
        $GREP -v "/proc/kcore"    | \
        $GREP -v "/proc/bus/usb"  | \
        $GREP -v "/proc/xen/xenbus"  | \
        $GREP -v "/proc/acpi/event"  | \
        $GREP -v "pagemap"  | \
        $GREP -v "clear_refs"  | \
        $GREP -v "/proc/kmsg" > $TMPFILE  

for i in $($CAT $TMPFILE)
do
         Dirname=$(dirname $i)
        Filename=$(basename $i)

        if [ ! -d ${LOGDIR}${Dirname} ]; then
                $MKDIR -p ${LOGDIR}${Dirname}
        fi
        if [ -e "$i" ] ; then
			$CAT "$i" > ${LOGDIR}${Dirname}/${Filename} 2>&1
        fi
done

$RM -f $TMPFILE

##############################################################################
#           Device Information
##############################################################################

if [ -x $CARDCTL ]; then
	$CARDCTL info   > ${LOGDIR}/hardware/cardctl-info.out   2>&1
	$CARDCTL status > ${LOGDIR}/hardware/cardctl-status.out 2>&1
	# $CARDCTL ident> ${LOGDIR}/hardware/cardctl-ident.out 2>&1
fi

if [ -x $LSPCI ]; then 
	$LSPCI    > ${LOGDIR}/hardware/lspci.out   2>&1
	$LSPCI -n > ${LOGDIR}/hardware/lspci-n.out 2>&1

	$LSPCI | while read line
	do
        	Bus=$(/bin/echo $line 2>/dev/null | awk '{ print $1 }')
        	$LSPCI -vv -s $Bus > ${LOGDIR}/hardware/lspci_-vv_-s_${Bus}.out 2>&1
	done
fi

# Get the port names from the HDA cards
for i in /sys/class/scsi_host/host*/device/fc_host\:host*/port_name 
do
	if [ -f $i ]; then
		name=$( echo $i | sed 's/\//_/g' | sed 's/^_//g')
        	echo "Port Name : $(cat $i )" >> ${LOGDIR}/hardware/cat_${name}.out
	fi
done

# Get a listing of the /dev directory
$MKDIR ${LOGDIR}/dev

$LS -laR /dev  > ${LOGDIR}/dev/ls_-laR_dev.out

if [ -x "$LSUSB" ]; then
	$LSUSB -xv > ${LOGDIR}/hardware/lsusb_-xv.out 2>&1
	$LSUSB -tv > ${LOGDIR}/hardware/lsusb_-tv.out 2>&1
fi

if [ -x "$LSDEV" ]; then
	$LSDEV -type adaptor > ${LOGDIR}/hardware/lsdev_-type_adaptor.out 2>&1
fi

if [ -x "$ACPI" ]; then
	$ACPI -V > ${LOGDIR}/hardware/acpi-V.out 2>&1
fi

if [ -x $FREE ]; then 
	$FREE    > ${LOGDIR}/hardware/free.out
	$FREE -k > ${LOGDIR}/hardware/free_-k.out
fi

$LS -laR /dev > ${LOGDIR}/hardware/ls-laR_dev.out

if [ -d /udev ]; then
        $LS -laR /udev > ${LOGDIR}/hardware/ls-laR_udev.out
fi

# Tape information
if [ -f /etc/stinit.def ]; then 
	$CP -p /etc/stinit.def ${LOGDIR}/etc/stinit.def
fi

# Global Devices list
if [ -x "$LSHAL" ]; then
	$LSHAL > ${LOGDIR}/hardware/lshal.out
fi

if [ -x /usr/share/rhn/up2date_client/hardware.py ]; then
	/usr/share/rhn/up2date_client/hardware.py > ${LOGDIR}/hardware/hardware.py.out 2>&1
fi

if [ -x "$SMARTCTL" ]; then
	for device in $( $LS /dev/hd[a-z] /dev/sd[a-z] /dev/st[0-9] /dev/sg[0-9]  2> /dev/null)
	do
		name=$( echo $device | sed 's/\//_/g' )
		${SMARTCTL} -a $device 2>/dev/null 1> ${LOGDIR}/hardware/smartctl-a_${name}.out
	done
fi

##############################################################################
# Collect Hardware information from the hwinfo program if installed
##############################################################################

if [ -x $HWINFO ]; then
	$HWINFO                 > ${LOGDIR}/hardware/hwinfo.out                 2>&1
	$HWINFO  --isapnp       > ${LOGDIR}/hardware/hwinfo_--isapnp.out        2>&1
	$HWINFO  --scsi         > ${LOGDIR}/hardware/hwinfo_--scsi.out          2>&1 
	$HWINFO  --framebuffer  > ${LOGDIR}/hardware/hwinfo_--framebuffer.out   2>&1
fi

if [ -x "$PROCINFO"  ]; then
	$PROCINFO  > ${LOGDIR}/hardware/procinfo.out 2>&1
fi

if [ -x "$DMIDECODE" ]; then
	$DMIDECODE  > ${LOGDIR}/hardware/dmidecode.out 2>&1
fi

if [ -x $LSHW  ]; then
	$LSHW > ${LOGDIR}/hardware/lshw.out 2>&1
fi

##############################################################################
# Boot Section
##############################################################################

Echo "[*] Boot Section"

if [ -x "/sbin/lilo" ]; then
	/sbin/lilo -q > $LOGDIR/system/lilo_-q  2>&1
fi

$LS -alR /boot > ${LOGDIR}/system/ls-alR_boot.out 2>&1
$MKDIR -p ${LOGDIR}/boot/grub

for i in  /boot/grub/menu.lst /boot/grub/grub.conf \
		/boot/grub.conf /boot/grub/device.map 
do
	if [ -f ${i} ]; then
		$CP -p ${i} ${LOGDIR}/${i}
	fi
done

if [ -f /etc/inittab ]; then
	$CP -p /etc/inittab	${LOGDIR}/etc/inittab
fi

##############################################################################
# /etc Config Files Section
##############################################################################

Echo "[*] /etc Config Files Section"

for i in $( $FIND /etc -name "*.conf" -o -name "*.cf" -o -name "*.cnf" ) 
do
        dirname="$(dirname $i)"
        filename="$(basename $i)"

	if [ ! -d ${LOGDIR}/${dirname} ]; then
		$MKDIR -p ${LOGDIR}/${dirname}
	fi

	$CP -p $i ${LOGDIR}/${dirname}/${filename}
done

if [ -f /etc/nologin.txt ]; then
	$CP -p /etc/nologin.txt ${LOGDIR}/etc/nologin.txt
fi

$CP -p /etc/securetty ${LOGDIR}/etc/securetty
$CP -p /etc/shells ${LOGDIR}/etc/shells

if [ -f  /etc/krb.realms ]; then
	$CP -p /etc/krb.realms ${LOGDIR}/etc/krb.realms
fi

##############################################################################
# Copy the /etc/profile.d scripts 
##############################################################################

if [ -d /etc/profile.d ]; then
	$CP -Rp /etc/profile.d ${LOGDIR}/etc
fi

##############################################################################
# Copy the /etc/modprobe.d scripts 
##############################################################################

if [ -d /etc/profile.d ]; then
	$CP -Rp /etc/modprobe.d ${LOGDIR}/etc
fi

##############################################################################
# New in Fedora 9 
##############################################################################

if [ -d /etc/event.d ]; then
	$CP -Rp /etc/event.d ${LOGDIR}/etc
fi

##############################################################################
# Get all the pcmcia config information
##############################################################################

if [ -d /etc/pcmcia ]; then
	if [ ! -d ${LOGDIR}/pcmcia ]; then
		$MKDIR -p ${LOGDIR}/etc/pcmcia 
	fi
	$CP -R -p /etc/pcmcia/*.opts ${LOGDIR}/etc/pcmcia 
fi

##############################################################################
# Performance/System Section
##############################################################################

Echo "[*] Performance/System Section"

if [ -e /proc/loadavg ]; then
	$CAT /proc/loadavg > ${LOGDIR}/system/loadavg.out
fi

if [ -e /proc/stat ]; then
	$CAT /proc/stat > ${LOGDIR}/system/stat.out
fi

$DATE     > ${LOGDIR}/system/date.out
$FREE     > ${LOGDIR}/system/free.out
$PS auxw  > ${LOGDIR}/system/ps_auxw.out
$PS -lef  > ${LOGDIR}/system/ps_-elf.out
$PSTREE   > ${LOGDIR}/system/pstree.out
$HOSTNAME > ${LOGDIR}/system/hostname.out
$IPCS -a  > ${LOGDIR}/system/ipcs_-a.out
$IPCS -u  > ${LOGDIR}/system/ipcs_-u.out
$IPCS -l  > ${LOGDIR}/system/ipcs_-l.out
$UPTIME   > ${LOGDIR}/system/uptime.out
ulimit -a > ${LOGDIR}/system/ulimit_-a.out

if [ -x $VMSTAT ]; then
	$VMSTAT -s > ${LOGDIR}/system/vmstat_-s.out
fi

##############################################################################
# OK not sure where this should go so I've put it here instead
##############################################################################

if [ "$LSOF" != "" ]; then
	$LSOF > ${LOGDIR}/system/lsof.out	2>&1
fi

##############################################################################
# Kernel Section
##############################################################################

Echo "[*] Kernel Section"

$SYSCTL -A> ${LOGDIR}/etc/sysctl_-A.out   2>&1
$UNAME -a > ${LOGDIR}/system/uname_-a.out 2>&1
$RUNLEVEL > ${LOGDIR}/system/runlevel.out 2>&1
$WHO -r   > ${LOGDIR}/system/who_-r.out   2>&1

if [ -f /etc/conf.modules ]; then
	$CP -p /etc/conf.modules ${LOGDIR}/etc/conf.modules
fi

if [ ! -d ${LOGDIR}/kernel/info ]; then
	$MKDIR -p ${LOGDIR}/kernel/info
fi

$LSMOD | while read line
do 
	kernmod=$( echo $line | $AWK '{ print $1 }' )
	$MODINFO $kernmod  > ${LOGDIR}/kernel/info/${kernmod}.out 2>&1
done

$LSMOD > ${LOGDIR}/kernel/lsmod.out 2>&1

if [ -x $KSYMS ]; then 
	$KSYMS > ${LOGDIR}/kernel/ksyms.out 2>&1
fi

$CP -p /lib/modules/$($UNAME -r)/modules.dep ${LOGDIR}/kernel/modules.dep

$MODPROBE -n -l -v  > ${LOGDIR}/kernel/modprobe_-n-l-v.out  2>&1
$DEPMOD -av         > ${LOGDIR}/kernel/depmod_-av.out       2>&1
$CAT /proc/modules  > ${LOGDIR}/kernel/modules.out          2>&1

##############################################################################
# Just incase we have a debian system
##############################################################################

if [ -f /etc/kernel-pkg.conf ]; then
	$CP -p /etc/kernel-pkg.conf ${LOGDIR}/etc/kernel-pkg.conf
fi
                                                                                
if [ -f /etc/kernel-img.conf ]; then
	$CP -p /etc/kernel-img.conf ${LOGDIR}/etc/kernel-img.conf
fi

##############################################################################
# Get the kernel configuration details from a 2.6 kernel
##############################################################################

if [ -f /proc/config.gz ]; then
	gunzip -c /proc/config.gz > ${LOGDIR}/kernel/config 
fi

##############################################################################
# Hot Plug Section
##############################################################################

Echo "[*] Hot Plug Section"

if [ -d /etc/hotplug ]; then
	if [ ! -d ${LOGDIR}/etc/hotplug ]; then
		$MKDIR -p  ${LOGDIR}/etc/hotplug
	fi
	cd /etc/hotplug
	$CP -Rp * ${LOGDIR}/etc/hotplug/
fi

##############################################################################
# Disk Section
##############################################################################

Echo "[*] Disk Section"

# Check to see what is mounted
$DF -k    	> ${LOGDIR}/disks/df_-k.out     2>&1
$DF -h    	> ${LOGDIR}/disks/df_-h.out     2>&1
$DF -ki   	> ${LOGDIR}/disks/df_-ki.out    2>&1
$DF -aki  	> ${LOGDIR}/disks/df_-aki.out   2>&1
$DF -akih 	> ${LOGDIR}/disks/df_-akih.out  2>&1

if [ -x $SWAPON ]; then
	$SWAPON -s > ${LOGDIR}/disks/swapon_-s.out 2>&1
fi

$MOUNT 		> ${LOGDIR}/disks/mount.out     2>&1
$MOUNT -l	> ${LOGDIR}/disks/mount_-l.out  2>&1

$CAT /proc/mounts > ${LOGDIR}/disks/mounts.out 2>&1

# fstab Information
$CP -p /etc/fstab ${LOGDIR}/disks/fstab 2>&1

# Display any quotas that my have been set
$REPQUOTA -av	> ${LOGDIR}/disks/repquota_-av 2>&1

##############################################################################
# Disk Format Information
##############################################################################

DISKLIST=$($FDISK -l  2>/dev/null | grep "^/dev" | sed 's/[0-9]//g' | awk '{ print $1 }' | sort -u)

if [ -x $FDISK ]; then
	$FDISK -l > ${LOGDIR}/disks/fdisk_-l.out 2>&1
fi

if [ -x $SFDISK ]; then
  $SFDISK -d > ${LOGDIR}/disks/sfdisk_-d.out 2>&1
	$SFDISK -l > ${LOGDIR}/disks/sfdisk_-l.out 2>&1
	$SFDISK -s > ${LOGDIR}/disks/sfdisk_-s.out 2>&1
fi

if [ -x $BLKID ]; then
	$BLKID > ${LOGDIR}/disks/blkid.out 2>&1
fi

for DISK in $DISKLIST
do
	NEWDISK=$(/bin/echo $DISK |  sed s'/\/dev\///g' )
	if [ -x $HDPARM ]; then $HDPARM -vIi $DISK > ${LOGDIR}/disks/hdparm_-vIi_${NEWDISK}.out 2>&1; fi
	if [ -x $SFDISK ]; then $SFDISK  -l  $DISK > ${LOGDIR}/disks/sfdisk_-l_-${NEWDISK}.out  2>&1; fi
	if [ -x $FDISK  ]; then $FDISK   -l  $DISK > ${LOGDIR}/disks/fdisk_-l_-${NEWDISK}.out   2>&1; fi
done

if [ -x "$DUMPE2FS" ]; then
	PARTS=$($FDISK -l 2>/dev/null | grep "^/dev" | awk '{ print $1 }')
	for parts in $PARTS; do
    name=$(/bin/echo $parts | sed 's/\//_/g')
    $DUMPE2FS $parts > ${LOGDIR}/disks/dumpe2fs${name}.out 2>&1
	done
fi

##############################################################################
# Collect Detailed SCSI information about the disks
##############################################################################

if [ -x "$SCSI_ID" ]; then
    for i in $($LS sd[a-z] 2>/dev/null)
    do
        if [ -b /dev/${i} ] ; then
       		disk_name=$(/bin/echo /dev/${i} | sed 's/\//_/g')
            $SCSI_ID -g -p 0x80 -d /dev/${i} -s /block/${i} \
                 > ${LOGDIR}/disks/scsi_id_-g_-p_0x80_${disk_name}.out 2>&1

            $SCSI_ID  -g -p 0x83 -d /dev/${i} -s /block/${i} \
                 > ${LOGDIR}/disks/scsi_id_-g_-p_0x83_${disk_name}.out 2>&1
        fi
    done
fi

if [ -x $SYSTOOL ]; then
    $SYSTOOL -c scsi_host -v  > ${LOGDIR}/disks/systool_-c_scsi_host_-v.out 2>&1
fi

##############################################################################
# If we are using multi-pathings then print out the 
# multi-pathing information
##############################################################################

if [ -x "$MULTIPATH" ]; then
	 $MULTIPATH -ll  > ${LOGDIR}/disks/multipath_-ll.out 2>&1
	 $MULTIPATH -v2  > ${LOGDIR}/disks/multipath_-v2.out 2>&1
fi

if [ -x "$DMSETUP" ]; then
	$DMSETUP ls         > ${LOGDIR}/disks/dmsetup_ls.out        2>&1
  $DMSETUP ls --tree  > ${LOGDIR}/disks/dmsetup_ls--info.out  2>&1
  $DMSETUP info       > ${LOGDIR}/disks/dmsetup_info.out      2>&1
  $DMSETUP info       > ${LOGDIR}/disks/dmsetup_info-C.out    2>&1
  $DMSETUP deps       > ${LOGDIR}/disks/dmsetup_deps.out      2>&1
  $DMSETUP targets    > ${LOGDIR}/disks/dmsetup_targets.out   2>&1
fi

# Check to see what iscsi devices have
if [ -x "$ISCSIADM" ]; then
	$ISCSIADM -m session > ${LOGDIR}/disks/iscsiadm_-m_session.out 2>&1
fi

# Check to see what emc powerpath devices we have 
if [ -x "$POWERMT" ]; then
	mkdir -p ${LOGDIR}/disks/emcpower
	$POWERMT check_registration       >${LOGDIR}/disks/emcpower/powermt_check_registration.out 2>&1
	$POWERMT display path             >${LOGDIR}/disks/emcpower/powermt_display_path.out 2>&1
	$POWERMT display ports            >${LOGDIR}/disks/emcpower/powermt_display_ports.out 2>&1
	$POWERMT display paths class=all  >${LOGDIR}/disks/emcpower/powermt_display_paths_class=all.out 2>&1
	$POWERMT display ports dev=all    >${LOGDIR}/disks/emcpower/powermt_display_ports_dev=all.out 2>&1
	$POWERMT display dev=all          >${LOGDIR}/disks/emcpower/powermt_display_dev=all.out 2>&1

	# Get the partition details for the EMC devices
	for emcdevice in $(ls /dev/emcpower*)
	do
       		emc_disk_name=$(/bin/echo ${emcdevice} | sed 's/\//_/g')
		      $FDISK -l $emcdevice > ${LOGDIR}/disks/emcpower/fdisk_-l_${emc_disk_name}.out 2>&1
	done
fi

##############################################################################
# Veritas Volume Manager / Symantec Veritas Storage Foundation  Information
##############################################################################
#
# Changes - "Vincent S. Cojot"  - 04-11-2008 
#           added licence checks
#           VxVM/VxFS Configuration Backups
#           Some minor bug fixes
#
##############################################################################

if [ -d /etc/vx/licenses/lic ]; then
    Echo "[*] Veritas Volume Manager / Symantec Veritas Storage Foundation Section"
    Echo "[*] VxVM/VxFS/VCS/VVR licensing Section"
 
    if [ ! -d  ${LOGDIR}/etc/vx/licenses/lic ]; then
        $MKDIR -p ${LOGDIR}/etc/vx/licenses/lic
    fi
 
    $CP -Rp /etc/vx/licenses/lic ${LOGDIR}/etc/vx/licenses/ 
    $VXLICREP -e > ${LOGDIR}/system/vxlicrep_-e.out 2>&1
fi

if [ -d /etc/vx/cbr/bk ]; then
    Echo "[*] VxVM/VxFS Configuration Backups"

    if [ ! -d  ${LOGDIR}/etc/vx/cbr/bk ]; then
        $MKDIR -p ${LOGDIR}/etc/vx/cbr/bk
    fi

    $CP -Rp /etc/vx/cbr/bk ${LOGDIR}/etc/vx/cbr/
fi

if [ -d /dev/vx ]; then
    Echo "[*] VxVM live configuration"

	if [ ! -d  ${LOGDIR}/disks/vxvm ]; then
		$MKDIR -p ${LOGDIR}/disks/vxvm
		$MKDIR -p ${LOGDIR}/disks/vxvm/logs
		$MKDIR -p ${LOGDIR}/disks/vxvm/disk_groups
	fi

	$LS -laR /dev/vx >  ${LOGDIR}/disks/vxvm/ls-lR_dev_vx.out 2>&1

	if [ -x $VXDISK  ]; then
		$VXDISK list    > ${LOGDIR}/disks/vxvm/vxdisk_list.out    2>&1
		$VXDISK -o alldgs list > ${LOGDIR}/disks/vxvm/vxdisk_-o_alldgs_list.out 2>&1
		$VXPRINT -Ath   > ${LOGDIR}/disks/vxvm/vxprint_-Ath.out   2>&1
		$VXPRINT -h     > ${LOGDIR}/disks/vxvm/vxprint_-h.out     2>&1
		$VXPRINT -hr    > ${LOGDIR}/disks/vxvm/vxprint_-hr.out    2>&1
		$VXPRINT -th    > ${LOGDIR}/disks/vxvm/vxprint_-th.out    2>&1
		$VXPRINT -thrL  > ${LOGDIR}/disks/vxvm/vxprint_-thrL.out  2>&1
	fi

	if [ -x $VXDG ]; then
		$VXDG -q list > ${LOGDIR}/disks/vxvm/vxdg_-q_-list.out 2>&1
	fi

    #------------------------------------------------------------------------
    # Collect individual volume information
    #------------------------------------------------------------------------

	for i in $($VXDG -q list|awk '{print $1}')
	do
		$VXDG list $i     > ${LOGDIR}/disks/vxvm/disk_groups/vxdg_list_${i}.out
		$VXDG -g $i free  > ${LOGDIR}/disks/vxvm/disk_groups/vxdg_-g_free_${i}.out
		$VXPRINT -vng $i  > ${LOGDIR}/disks/vxvm/disk_groups/vxprint_-vng_${i}.out
		VOL=$(cat ${LOGDIR}/disks/vxvm/disk_groups/vxprint_-vng_${i}.out)

		$VXPRINT -hmQqg $i $VOL  \
			> ${LOGDIR}/disks/vxvm/disk_groups/vxprint_-hmQqg_4vxmk=${i}.out 2>&1
		$VXPRINT -hmQqg $i   \
			> ${LOGDIR}/disks/vxvm/disk_groups/vxprint_-hmQqg=${i}.out 2>&1
	done
fi

##############################################################################
# Get the filesystems Characteristics
##############################################################################

for i in $($DF -kl | grep ^/dev | awk '{ print $1 }')
do
	if [ -x $TUNE2FS  ]; then 
    name=$(/bin/echo $i | sed 's/\//_/g')
		$TUNE2FS  -l $i > ${LOGDIR}/disks/tunefs_-l_${name}.out 2>&1 
	fi
done


##############################################################################
# NFS Information
##############################################################################

# Copy NFS config files around
if [ -f /etc/auto.master ]; then
	$CP -p /etc/auto* ${LOGDIR}/etc
fi

# lets see what we have really exported 
if [ -x $EXPORTFS ]; then
	$EXPORTFS -v > ${LOGDIR}/disks/exportfs_-v.out 2>&1
fi

# This is what we have configured to be exported 
if [ -f /etc/exports ]; then
	$CP -p /etc/exports ${LOGDIR}/etc/exports
fi

if [ -x "$NFSSTAT" ]; then
	$NFSSTAT -a > ${LOGDIR}/disks/nfsstat_-a.out 2>&1
fi

##############################################################################
# Raid Information
##############################################################################

if [ -f /etc/raidtab ]; then
	$CP -p /etc/raidtab ${LOGDIR}/etc/raidtab
fi

$MKDIR ${LOGDIR}/disks/raid 

if [ -x "$LSRAID" ]; then
	for i in $( $LS /dev/md[0-9]* 2>/dev/null )
	do
       		name=$(/bin/echo $i | sed 's/\//_/g')
		    $LSRAID -a $i > ${LOGDIR}/disks/raid/lsraid_-a_${name}.out > /dev/null 2>&1
	done
fi

if [ -x "$MDADM" ]; then
	for i in $( $LS /dev/md[0-9]* 2>/dev/null )
	do
       		name=$( echo $i | sed 's/\//_/g' )
		      $MDADM --detail /dev/$i > ${LOGDIR}/disks/raid/mdadm_--detail_${name}.out > /dev/null 2>&1

            if [ ! -s ${LOGDIR}/disks/raid/mdadm--detail_${name}.out ]; then
              $RM -f ${LOGDIR}/disks/raid/mdadm--detail_${name}.out
            fi
	done
fi

##############################################################################
# LVM Information
##############################################################################

LVMDIR=${LOGDIR}/disks/lvm
$MKDIR -p ${LVMDIR} 

if [ -x "$LVDISPLAY" ]; then
	$LVDISPLAY -vv 	> ${LVMDIR}/lvdisplay_-vv.out  2>&1
	$VGDISPLAY -vv 	> ${LVMDIR}/vgdisplay_-vv.out  2>&1
	$VGSCAN -vv    	> ${LVMDIR}/vgscan_-vv.out     2>&1
	$LVMDISKSCAN -v > ${LVMDIR}/lvmdiskscan_-v.out 2>&1
	$PVSCAN -v      > ${LVMDIR}/pvscan_-v.out      2>&1
	$PVDISPLAY -v   > ${LVMDIR}/pvdisplay_-v.out   2>&1
	$VGS -v         > ${LVMDIR}/vgs-v.out          2>&1
	$PVSCAN -v      > ${LVMDIR}/pvscan-v.out       2>&1
fi

if [ -x "$LVM" ]; then
	$LVM dumpconfig  > ${LVMDIR}/lvm_dumpconfig.out 2>&1
	$LVM lvs         > ${LVMDIR}/lvm_lvs.out        2>&1

  # Map every DM device to a disk
  $LVDISPLAY | $AWK  '/LV Name/{n=$3} /Block device/{d=$3; sub(".*:","dm-",d); print d,n;}' > ${LVMDIR}/devices.out 2>&1
fi

##############################################################################
# DM Information
##############################################################################

# Work out which dm device is being used by each filesystem
grep dm-[0-9] /proc/diskstats | awk '{print $1, $2, $3}' | while read line
do
	 Major=$(echo $line | awk '{print $1}')
	 Minor=$(echo $line | awk '{print $2}')
	Device=$(echo $line | awk '{print $3}')

	List=$(ls -la /dev/mapper | grep "${Major},  ${Minor}" | awk '{print $(NF)}')
	echo "$Device = $List " >> ${LOGDIR}/disks/dm-info.out
done 

##############################################################################
# Software Section
##############################################################################

Echo "[*] Software Section"
$MKDIR -p ${LOGDIR}/software/rpm-packages

#
# Systemd 
# 
if [ -x "$SYSTEMCTL" ]; then 
  $MKDIR ${LOGDIR}/software/systemd

  # systemd checks
  $SYSTEMD  --dump-configuration-items > ${LOGDIR}/software/systemd/systemd_--dump-configuration-items.out 2>&1
  $SYSTEMD  --test                     > ${LOGDIR}/software/systemd/systemd_--test.out                     2>&1 

  # systemd-cgls tree
  if [ -x "$SYSTEMDCGLS" ]; then
    $SYSTEMDCGLS  > ${LOGDIR}/software/systemd/systemd-cgls.out 2>&1
  fi

  if [ -x "$SYSTEMDLOGINCTL" ]; then
    $SYSTEMDLOGINCTL --all     > ${LOGDIR}/software/systemd/systemd-loginctl_--all.out     2>&1
    $SYSTEMDLOGINCTL show-seat > ${LOGDIR}/software/systemd/systemd-loginctl_show-seat.out 2>&1
    $SYSTEMDLOGINCTL show-user > ${LOGDIR}/software/systemd/systemd-loginctl_show_user.out 2>&1
  fi

  # Now systemctl checks
  $SYSTEMCTL --version        > ${LOGDIR}/software/systemd/systemctl_--version.out        2>&1
  $SYSTEMCTL                  > ${LOGDIR}/software/systemd/systemctl.out                  2>&1 
  $SYSTEMCTL --all            > ${LOGDIR}/software/systemd/systemctl_--all.out            2>&1 
  $SYSTEMCTL list-unit-files  > ${LOGDIR}/software/systemd/systemctl_list-unit-files.out  2>&1 
  $SYSTEMCTL list-jobs        > ${LOGDIR}/software/systemd/systemctl_list-jobs.out        2>&1 
  $SYSTEMCTL dump             > ${LOGDIR}/software/systemd/systemctl_dump.out             2>&1
  $SYSTEMCTL show-environment > ${LOGDIR}/software/systemd/systemctl_show-environment.out 2>&1

  if [ -d ${LOGDIR}/etc/systemd ]; then
    $LN -s ${LOGDIR}/etc/systemd ${LOGDIR}/software/systemd/etc-systemd 2>&1
  fi
fi

if [ -x "$RPM" ]; then
	if [ -x "$CHKCONFIG" ]; then
		$CHKCONFIG --list > ${LOGDIR}/software/chkconfig--list.out 2>&1
	fi

	# Short Description of all packages installed
	echo "Package_Name		Version		Size		Description" 	> ${LOGDIR}/software/rpm-qa--queryformat.out
	echo "===================================================================================" >> ${LOGDIR}/software/rpm-qa--queryformat.out
	$RPM -qa --queryformat '%-25{NAME}  %-16{VERSION} %-10{RELEASE} %-10{DISTRIBUTION}  %-10{SIZE} %-10{INSTALLTIME:date} %{SUMMARY}\n' | sort >> ${LOGDIR}/software/rpm-qa--queryformat.out 2>&1

	# Long Description of all packages installed
	$RPM -qa > ${LOGDIR}/software/rpm_-qa 2>&1
	$CAT ${LOGDIR}/software/rpm_-qa | while read line 
	do
 		$RPM -qi  $line > ${LOGDIR}/software/rpm-packages/${line}.out 2>&1
		if [ $? -ne 0 ]; then
			echo "ERROR: ${line} problem"
		fi
	done

	# print a list os installed packages sorted by install time:
	$RPM -qa -last | tac > ${LOGDIR}/software/rpm-packages/rpm_-qa_-last.out

	#############################################################
	# If you enable verification then this then it's going to 
	# take a some time to complete........
	#############################################################
	if [ ${FULLSOFT} -gt 0 ]; then
		 $RPM -Va > ${LOGDIR}/software/rpm-Va.out 2>&1
	fi
fi

if [ -f /usr/lib/rpm/rpmrc ]; then 
	$CP -p /usr/lib/rpm/rpmrc ${LOGDIR}/software/rpmrc
fi

# Make a copy of the yum config files so that we can compare them
YUMDIR=${LOGDIR}/software/yum

if [ -d /etc/yum.repos.d ]; then
	$MKDIR -p $YUMDIR/yum.repos.d
	$CP /etc/yum.repos.d/* $YUMDIR/yum.repos.d/
fi

if [ -x "$YUM" ]; then
  $YUM list installed       > ${YUMDIR}/yum_list_installed.out        2>&1
  $YUM info installed       > ${YUMDIR}/yum_info_installed.out        2>&1
  $YUM repolist all         > ${YUMDIR}/yum_repolist_all.out          2>&1
  $YUM repolist enabled     > ${YUMDIR}/yum_repolist_enabled.out      2>&1
  $YUM repolist disabled    > ${YUMDIR}/yum_repolist_disabled.out     2>&1
  $YUM -v repolist all      > ${YUMDIR}/yum_-v_repolist_all.out       2>&1
  $YUM -v repolist enabled  > ${YUMDIR}/yum_-v_repolist_enabled.out   2>&1
  $YUM -v repolist disabled > ${YUMDIR}/yum_-v_repolist_disabled.out  2>&1
fi

##############################################################################
# Some Debian specific info here for packages
##############################################################################

if [ -f /var/lib/dpkg/available ]; then
	$MKDIR -p ${LOGDIR}/var/lib/dpkg

	if [ -d /etc/apt ]; then
		$MKDIR -p ${LOGDIR}/etc/apt
	fi

	if [ -f /etc/apt/sources.list ]; then
		$CP -p /etc/apt/sources.list ${LOGDIR}/etc/apt/sources.list
	fi

	if [ -f /etc/apt/apt.conf ]; then
		$CP -p /etc/apt/apt.conf ${LOGDIR}/etc/apt/apt.conf
	fi

	if [ -f /etc/apt/apt.conf ]; then
		$CP -p /etc/apt/apt.conf ${LOGDIR}/etc/apt/apt.conf
	fi

	if [ -f /var/lib/dpkg/status ]; then
		$CP -p /var/lib/dpkg/status ${LOGDIR}/var/lib/dpkg/status
	fi

	if [ -x "$DPKG" ]; then
		 $DPKG  --list            > ${LOGDIR}/software/dpkg_--list.out
		 $DPKG  -all              > ${LOGDIR}/software/dpkg_-al.out
		 $DPKG  --get-selections  > ${LOGDIR}/software/dpkg_-get-selections.out
	fi
	
	if [ -x "$DPKG_QUERY" ]; then
		 $DPKG_QUERY -W  > ${LOGDIR}/software/dpkg-query_-W.out
	fi

	if [ -x /usr/bin/apt-config ]; then
		/usr/bin/apt-config dump > ${LOGDIR}/software/apt-config_dump.out
	fi 
fi

##############################################################################
# Some SuSE specific info here for packages
##############################################################################

if [ -x "$ZYPPER" ]; then
	$ZYPPER repos         > ${LOGDIR}/software/zypper_repos         2>&1
	$ZYPPER locks         > ${LOGDIR}/software/zypper_locks         2>&1
	$ZYPPER patches       > ${LOGDIR}/software/zypper_patches       2>&1
	$ZYPPER packages      > ${LOGDIR}/software/zypper_packages      2>&1
	$ZYPPER patterns      > ${LOGDIR}/software/zypper_patterns      2>&1
	$ZYPPER products      > ${LOGDIR}/software/zypper_products      2>&1
	$ZYPPER services      > ${LOGDIR}/software/zypper_services      2>&1
	$ZYPPER licenses      > ${LOGDIR}/software/zypper_licenses      2>&1
	$ZYPPER targetos      > ${LOGDIR}/software/zypper_targetos      2>&1
	$ZYPPER list-updates  > ${LOGDIR}/software/zypper_list-updates  2>&1
fi

##############################################################################
# This Section is for Gentoo - so we can work out what packages are installed
# Provided by Adam Bills 
##############################################################################

GENTOPKGS=${LOGDIR}/software/gento_kgs.out
if [ -d  /var/db/pkg ]; then

	( find /var/db/pkg -type f -name environment.bz2 | while read x; do bzcat $x | \
		awk -F= '{
			if ($1 == "CATEGORY"){
				printf "%s ", $2;
			}
			if ($1 == "PN"){
				printf "%s ",$2;
			}

			if ($1 == "PV"){
				print $2;
			}
		}'; done

	) >> $GENTOPKGS
fi

#  Show the bootup info
if [ -x $RC_UPDATE ]; then 
	$RC_UPDATE show >> ${LOGDIR}/software/rc-update_show.out
fi

##############################################################################
# sysconfig Section
##############################################################################

Echo "[*] Sysconfig Section"
if [ -d /etc/sysconfig ]; then
	if [ ! -d ${LOGDIR}/etc/sysconfig ]; then
		$MKDIR -p ${LOGDIR}/etc/sysconfig
	fi
	$CP -p -R /etc/sysconfig/* ${LOGDIR}/etc/sysconfig
fi

##############################################################################
# RHN Section
##############################################################################

if [ -d /etc/sysconfig/rhn ]; then
	Echo "[*] RedHat Network Section"
	RDIR=${LOGDIR}/rhn
	$MKDIR -p ${RDIR} 
	if [ -d  /etc/rhn ]; then
	    $CP -pR /etc/rhn/ ${LOGDIR}/etc/rhn/
	    if [ -f /etc/sysconfig/rhn/systemid ]; then
		    if [ -x /usr/bin/xsltproc ]; then
			    /usr/bin/xsltproc $UTILDIR/text.xsl $RDIR/systemid \
				    > $ROOT/$RHNDIR/systemid 2>&1 
		    fi
	    fi
    fi
fi

##############################################################################
# Systems Log Section
##############################################################################

Echo "[*] Systems Log Section"
$CP -R -p /var/log/* ${LOGDIR}/logs
$DMESG  > ${LOGDIR}/logs/dmesg.out
$LAST   > ${LOGDIR}/logs/lastlog

##############################################################################
#   SELINUX
##############################################################################

Echo "[*] SElinux Section"
SELINUXDIR=${LOGDIR}/selinux
$MKDIR -p ${SELINUXDIR} 

if [ -x $SESTATUS ]; then
  $SESTATUS > ${SELINUXDIR}/sestatus.out
	$SESTATUS -bv > ${SELINUXDIR}/sestatus_-bv.out 2>&1
fi

if [ -x $SEMANAGE ]; then
  $SEMANAGE fcontext -l | tee ${SELINUXDIR}/semanage_fcontext_-l.out &> /dev/null
  $SEMANAGE port -l     | tee ${SELINUXDIR}/semanage_port_-l.out      &> /dev/null
  $SEMANAGE login -l    | tee ${SELINUXDIR}/semanage_login_-l.out     &> /dev/null
  $SEMANAGE user -l     | tee ${SELINUXDIR}/semanage_user_-l.out      &> /dev/null
  $SEMANAGE node -l     | tee ${SELINUXDIR}/semanage_node_-l.out      &> /dev/null
  $SEMANAGE interface -l| tee ${SELINUXDIR}/semanage_interface_-l.out &> /dev/null
  $SEMANAGE boolean -l  | tee ${SELINUXDIR}/semanage_boolean_-l.out   &> /dev/null
fi

if [ -x $GETSEBOOL ]; then
	$GETSEBOOL -a > ${LOGDIR}/selinux/getsebool_-a.out 2>&1
else
	echo "getsebool not installed" > ${LOGDIR}/selinux/getsebool_-a.out 2>&1
fi

##############################################################################
# Virtual Servers Information
##############################################################################

VIRT=${LOGDIR}/virtual

#------------------------------------------------------------------------
# Xen
#------------------------------------------------------------------------

if [ -d /etc/xen ]; then
	Echo "[*] Xen Section"
	$MKDIR -p ${VIRT}/xen
	XENETC=${LOGDIR}/xen

	if [ ! -d $XENETC ]; then
		mkdir -p $XENETC 
	fi

	$CP -Rp /etc/xen/* ${XENETC}/
	$MKDIR -p ${VIRT}/xen

	if [ -x $XM  ]; then
		$XM list		> $VIRT/xen/xm_list.out		2>&1
		$XM info		> $VIRT/xen/xm_info.out		2>&1
		$XM logs		> $VIRT/xen/xm_log.out		2>&1
		$XM dmesg		> $VIRT/xen/xm_dmesg.out	2>&1
		$XM vcpu-list	> $VIRT/xen/xm_vcpu-list.out	2>&1

		for myHost in $($XM list  2>/dev/null | egrep -v "VCPUs |^Domain-0")
		do
			$XM network-list $myHost> $VIRT/xen/xm_network-list_${myHost}.out 2>&1
			$XM uptime $myHost      > $VIRT/xen/xm_uptime_${myHost}.out       2>&1
			$VIRSH dominfo $myHost  > $VIRT/xen/virsh_dominfo_${myHost}.out   2>&1
		done
	fi
fi

##############################################################################
# VirtLib Information
##############################################################################

#------------------------------------------------------------------------
# Virtlib
#------------------------------------------------------------------------

if [ -x $VIRSH ]; then
	Echo "[*] LibVirt Section"
	$MKDIR -p ${VIRT}/libvirt
	$VIRSH  list --all 2>/dev/null | \
		grep -v "Id Name"            | \
		egrep -v "\--|^$"            | \
		awk '{print $2}'             | while read line
		do 
			$VIRSH dominfo $line >> ${VIRT}/libvirt/virsh_dominfo_${line}.out 2>&1
			$VIRSH dumpxml $line >> ${VIRT}/libvirt/virsh_dumpxml_${line}.out 2>&1
		done
	$VIRSH  list --all > ${VIRT}/libvirt/virsh_list_--all.out 2>&1
fi

##############################################################################
#	yp services
##############################################################################

Echo "[*] YP Services Section"
YPDIR=${LOGDIR}/yp
$MKDIR -p ${YPDIR} 

if [ -x "$YPWHICH" ]; then
	$YPWHICH -m > ${YPDIR}/ypwhich-m.out 2>&1
fi

if [ -f /etc/domainname ]; then
	$CP -p /etc/domainname ${LOGDIR}/etc/

	$LS -lR /var/yp/$(cat /etc/domainname) > ${YPDIR}/ls_-lR.out 2>&1

fi

##############################################################################
# Networking Section
##############################################################################

Echo "[*] Networking Section"
for i in $($LS -d /etc/host* )
do
	filename=$(basename $i)
	$CP -p  $i ${LOGDIR}/etc/${filename}
done

for i in $( $LS -d /etc/ftp* 2>/dev/null )
do
	filename=$(basename $i)
	$CP -p $i ${LOGDIR}/etc/$filename
done

$CP -p /etc/services ${LOGDIR}/etc/services

if [ -f /etc/HOSTNAME ]; then
	$CP -p /etc/HOSTNAME ${LOGDIR}/etc/HOSTNAME 
fi

if [ -f /etc/hostname ]; then
	$CP -p /etc/hostname ${LOGDIR}/etc/hostname 
fi

if [ -f /etc/networks ]; then
	$CP -p /etc/networks ${LOGDIR}/etc/networks 
fi

if [ -f /etc/hosts.allow ]; then
	$CP -p /etc/hosts.allow ${LOGDIR}/etc/hosts.allow
fi

if [ -f /etc/hosts.deny ]; then
	$CP -p /etc/hosts.deny ${LOGDIR}/etc/hosts.deny
fi

if [ -f /etc/shells ]; then
	$CP -p /etc/shells ${LOGDIR}/etc/shells
fi

if [ -f /etc/network/interfaces ]; then
	if [ ! -d ${LOGDIR}/etc/network/interfaces ]; then
	 	$MKDIR -p ${LOGDIR}/etc/network/interfaces
	fi
	$CP -p /etc/network/interfaces ${LOGDIR}/etc/network/interfaces
fi

$MKDIR -p ${LOGDIR}/network
$IFCONFIG  -a	> ${LOGDIR}/network/ifconfig_-a.out 2>&1
$ARP -an > ${LOGDIR}/network/arp_-an.out 2>&1

if [ -f "${LOGDIR}/etc/resolv.conf" ]; then
  $LN -s ${LOGDIR}/etc/resolv.conf ${LOGDIR}/network/resolv.conf 2>&1
fi

$NETSTAT -rn    > ${LOGDIR}/network/netstat_-rn.out     2>&1
$NETSTAT -lan   > ${LOGDIR}/network/netstat_-lan.out    2>&1
$NETSTAT -lav   > ${LOGDIR}/network/netstat_-lav.out    2>&1
$NETSTAT -tulpn > ${LOGDIR}/network/netstat_-tulpn.out  2>&1
$NETSTAT -ape   > ${LOGDIR}/network/netstat_-ape.out    2>&1
$NETSTAT -uan   > ${LOGDIR}/network/netstat_-uan.out    2>&1
$NETSTAT -s     > ${LOGDIR}/network/netstat_-s.out      2>&1
$NETSTAT -in    > ${LOGDIR}/network/netstat_-in.out     2>&1
$ROUTE -nv      > ${LOGDIR}/network/route_-nv.out       2>&1  

if [ -x "$IP" ]; then
  $IP  add	> ${LOGDIR}/network/ip_add.out    2>&1
  $IP  route> ${LOGDIR}/network/ip_route.out  2>&1
  $IP  link	> ${LOGDIR}/network/ip_link.out   2>&1
  $IP  rule	> ${LOGDIR}/network/ip_rule.out   2>&1
fi

if [ -x "$IWCONFIG" ]; then
  $IWCONFIG	> ${LOGDIR}/network/iwconfig.out 2>&1
fi

if [ -x "${MIITOOL}" ]; then
  ${MIITOOL}	> ${LOGDIR}/network/mii-tool.out 2>&1
fi

# Collect bridging information
if [ -x "${BRCTL}" ]; then
  $BRCTL show > ${LOGDIR}/network/brctl_show.out 2>&1
  for myBridge in $($BRCTL show | grep -v "STP enabled" |  grep ^[a-zA-Z] | awk '{ print $1}') 
  do
    $BRCTL showmacs $myBridge > ${LOGDIR}/network/btctl_showmacs_${myBridge}.out 2>&1
    $BRCTL showstp  $myBridge > ${LOGDIR}/network/btctl_showstp_${myBridge}.out 2>&1
  done       
fi

##############################################################################
# Get the iptable information
##############################################################################

if [ -x "$IPTABLES" ]; then
	$IPTABLES -L 		          > ${LOGDIR}/network/iptables-L.out
	$IPTABLES -t filter -nvL 	> ${LOGDIR}/network/iptables-t_filter-nvL.out
	$IPTABLES -t mangle -nvL 	> ${LOGDIR}/network/iptables-t_mangle-nvL.out
	$IPTABLES -t nat -nvL		  > ${LOGDIR}/network/iptables_-t_nat_-nvL.out
else
	echo "no iptables in kernel" > ${LOGDIR}/network/iptables-NO-IP-TABLES
fi

##############################################################################
# List the ipchains rules
##############################################################################

if [ -x "$IPCHAINS" ]; then
	$IPCHAINS -L -n > ${LOGDIR}/network/ipchains_-L_-n.out
fi

##############################################################################
# Lets now check the network cards speeds
##############################################################################

if [ -x "$ETHTOOL" ]; then
	for version in 4 6
	do
		INTERFACES=$( cat /proc/net/dev | grep "[0-9]:" | awk -F: '{print $1 }' )
		for i in $INTERFACES 
		do
        		$ETHTOOL $i    >  ${LOGDIR}/network/ethtool_ipv${version}_${i}.out    2>&1
        		$ETHTOOL -i $i >> ${LOGDIR}/network/ethtool_ipv${version}_-i_${i}.out 2>&1
        		$ETHTOOL -S $i >> ${LOGDIR}/network/ethtool_ipv${version}_-S_${i}.out 2>&1
		done
	done
fi

##############################################################################
# xinetd Section
##############################################################################

Echo "[*] xinetd Section"
if [ -d /etc/xinet.d ]; then
	XINETD=${LOGDIR}/etc/xinet.d
	$MKDIR -p ${XINETD}

	for i in $($LS -d /etc/xinetd.d/* )
	do
		filename=$(basename $i)
		$CP -p $i  ${XINETD}/$filename
	done
fi

if [ -f /etc/xinetd.log ]; then
	$CP -p /etc/xinetd.log ${LOGDIR}/etc/xinetd.log
fi

##############################################################################
# DNS Section
##############################################################################

Echo "[*] DNS Section"
if [ -f /etc/named.boot ]; then
	$CP -p  /etc/named.boot ${LOGDIR}/etc/named.boot
fi

DNSDIR=""
if [ "${DNSDIR}" != "" ]; then
	if [ ! -d ${LOGDIR}${DNSDIR} ]; then
		$MKDIR -p ${LOGDIR}${DNSDIR} 
	fi
	cd ${DNSDIR}
	 $TAR cf - . 2>/dev/null | ( cd ${LOGDIR}${DNSDIR} ; tar xpf - ) > /dev/null 2>&1
fi

##############################################################################
#   Cluster Section
##############################################################################

CLUSTERDIR=${LOGDIR}/clusters
Echo "[*] Cluster Section"

#--------------------------------------------------------------------
# Oracles OCFS2 cluster filesystems
#--------------------------------------------------------------------
if [ -f /etc/ocfs2/cluster.conf ]; then
	if [ ! -d ${LOGDIR}/etc/ocfs2 ]; then
		$MKDIR -p ${LOGDIR}/etc/ocfs2
	fi
	$CP -p /etc/ocfs2/cluster.conf ${LOGDIR}/etc/ocfs2/cluster.conf
	$MKDIR -p ${CLUSTERDIR}/ocfs2
	$CP -p /etc/ocfs2/cluster.conf ${CLUSTERDIR}/ocfs2/cluster.conf
fi

#--------------------------------------------------------------------
# Redhat Cluster
#--------------------------------------------------------------------
if [ -x $CLUSTAT ]; then
	Echo "[*] Veritas Cluster Section"
	MyClusterDir=${CLUSTERDIR}/redhat
	mkdir -p ${CLUSTERDIR}/redhat
	$CLUSTAT    > $MyClusterDir/clustat.out         2>&1
	$CLUSTAT -f	> $MyClusterDir/clustat_-f.out      2>&1
	$CLUSTAT -l	> $MyClusterDir/clustat_-l.out      2>&1
	$CLUSTAT -I	> $MyClusterDir/clustat_-I.out      2>&1
	$CLUSTAT -v	> $MyClusterDir/clustat_-v.out      2>&1
	$CLUSTAT -x	> $MyClusterDir/clustat_-x.out      2>&1
  $CLUSVCADM -v	> $MyClusterDir/clusvcadm_-x.out  2>&1
  $CLUSVCADM -S	> $MyClusterDir/clusvcadm_-S.out  2>&1
fi

# List out Quorum devices
if [ -x $MKQDISK ] ; then
	$MKQDISK -L >> $MyClusterDir/mkqdisk_-L.out	2>&1
fi

# Copy the cluster config files over
if [ -f /etc/cluster.xml ]; then
	$CP -p /etc/cluster.xml ${LOGDIR}/etc/cluster.xml
	$CP -p /etc/cluster.xml $MyClusterDir/cluster.xml
fi

if [ -d /etc/cluster ]; then
	$CP -Rp /etc/cluster/* ${LOGDIR}/etc/cluster/
	$CP -p /etc/cluster/* $MyClusterDir/
fi

#--------------------------------------------------------------------
# Veritas Cluster
#--------------------------------------------------------------------

if [ -f /etc/VRTSvcs/conf/config/main.cf ]; then
    Echo "[*] Veritas Cluster Section"
    VCSDIR=${CLUSTERDIR}/veritas

    if [ ! -d $VCSDIR ]; then
        $MKDIR -p ${VCSDIR}
    fi

    $MKDIR -p ${LOGDIR}/etc/VRTSvcs/conf/config
    $CP -p /etc/VRTSvcs/conf/config/* ${LOGDIR}/etc/VRTSvcs/conf/config

    if [ -d /var/VRTSvcs/log ]; then
		$MKDIR -p ${LOGDIR}/var/VRTSvcs/log
		$CP -p /var/VRTSvcs/log/* ${LOGDIR}/var/VRTSvcs/log
    fi

    $HASTATUS -sum>   ${VCSDIR}/hastatus_-sum.out 2>&1
    $HARES -list  >   ${VCSDIR}/hares_-list.out   2>&1
    $HAGRP -list  >   ${VCSDIR}/hagrp_-list.out   2>&1
    $HATYPE -list >   ${VCSDIR}/hatype_-list.out  2>&1
    $HAUSER -list >   ${VCSDIR}/hauser_-list.out  2>&1
    $LLTSTAT -vvn >   ${VCSDIR}/lltstat_-vvn.out  2>&1
    $GABCONFIG -a >   ${VCSDIR}/gabconfig_-a.out  2>&1
    
    $HACF -verify /etc/VRTSvcs/conf/config/main.cf > ${VCSDIR}/hacf-verify.out 2>&1 
    
    $CP -p /etc/llthosts  ${LOGDIR}/etc
    $CP -p /etc/llttab    ${LOGDIR}/etc
    $CP -p /etc/gabtab    ${LOGDIR}/etc
fi

#--------------------------------------------------------------------
# CRM/PaceMaker Cluster
#--------------------------------------------------------------------
Echo "[*] CRM Cluster Section"
CRMDIR=${CLUSTERDIR}/crm

if [ -x $CRM_MON ]; then 
	$MKDIR -p ${CRMDIR}
	$CRM_MON --version > ${CRMDIR}/crm_mon_--version.out

	if [ -x $CRM ]; then 
		$CRM status             > ${CRMDIR}/crm_status.out
		$CRM configure show     > ${CRMDIR}/crm_configure_show.out
		$CRM configure show xml > ${CRMDIR}/crm_configure_show_xml.out
		$CRM ra classes         > ${CRMDIR}/crm_ra_classes.out
		$CRM ra list ocf heartbeat > ${CRMDIR}/crm_ra_list_ocf_heartbeat.out
		$CRM ra list ocf pacemaker > ${CRMDIR}/crm_ra_list_ocf_pacemaker.out
	fi
	
  if [ -x $CRM_VERIFY ]; then $CRM_VERIFY -L > ${CRMDIR}/crm_verify_-L.out; fi
	if [ -x $CIBADMIN ]; then $CIBADMIN -Ql > ${CRMDIR}/cibadmin_-Ql.out; fi
fi

##############################################################################
#   Crontab Section
##############################################################################

Echo "[*] Crontab Section"
$MKDIR -p ${LOGDIR}/etc/cron
$CP -R -p /etc/cron*  ${LOGDIR}/etc

if [ -d /var/spool/cron ]; then
    $MKDIR -p ${LOGDIR}/var/spool/cron
    cd /var/spool/cron
    $TAR cf - . | ( cd ${LOGDIR}/var/spool/cron ; tar xpf - )
fi

##############################################################################
# Printer Section
##############################################################################

Echo "[*] Printer Sectiona"

PRINTDIR=${LOGDIR}/lp
$MKDIR -p ${PRINTDIR}
$MKDIR -p ${PRINTDIR}/general
$MKDIR -p ${LOGDIR}/etc/printcap

if [ -x /usr/bin/lpstat ]; then 
	/usr/bin/lpstat -t > ${PRINTDIR}/lpstat_-t.out 2>&1
fi

if [ -x /usr/sbin/lpc ]; then 
	/usr/sbin/lpc status > ${PRINTDIR}/lpstat_status.out 2>&1
fi

if [ -f /etc/printcap ]; then
	$CP /etc/printcap ${LOGDIR}/etc/printcap
fi

if [ -d /etc/cups ]; then
	$MKDIR -p ${LOGDIR}/etc/cups
	$CP -p -R /etc/cups/* ${LOGDIR}/etc/cups
fi

/usr/bin/lpq > ${PRINTDIR}/general/lpq.out 2>&1

if [ -x /usr/bin/lpq.cups ]; then
	/usr/bin/lpq.cups	> ${PRINTDIR}/lpq.cups.out 2>&1
fi

##############################################################################
# openldap Section
##############################################################################

Echo "[*] Openldap Section"

if [ -d /etc/openldap ]; then
	$MKDIR -p ${LOGDIR}/etc/openldap
	$CP -p -R /etc/openldap/* ${LOGDIR}/etc/openldap
fi

##############################################################################
# pam Section
##############################################################################

Echo "[*] PAM Section"

$MKDIR -p ${LOGDIR}/etc/pam 
$CP -p -R /etc/pam.d/* ${LOGDIR}/etc/pam/

##############################################################################
# Sendmail Section
##############################################################################

Echo "[*] Sendmail Section"

$MKDIR -p ${LOGDIR}/etc/mail

if [ -f /etc/sendmail.cf ]; then
	$CP -p /etc/sendmail.cf ${LOGDIR}/etc/sendmail.cf
fi
                                                                                
if [ -f /etc/sendmail.cw ]; then
	$CP -p /etc/sendmail.cw ${LOGDIR}/etc/sendmail.cw
fi

if [  -d /etc/mail ]; then
	for i in $($LS -d /etc/mail/* | $GREP -v \.db) ; do
		$CP -R -p $i ${LOGDIR}/etc/mail
	done
fi

if [ -f /etc/aliases ]; then
	$CP -p /etc/aliases ${LOGDIR}/etc/aliases
fi

if [ -f /etc/mail/aliases ]; then
	$CP -p /etc/mail/aliases ${LOGDIR}/etc/mail/aliases
fi

##############################################################################
# Postfix Section
##############################################################################

Echo "[*] Postfix Section"

if [ -d /etc/postfix ]; then
	POSTDIR=${LOGDIR}/etc/postfix
	$MKDIR -p $POSTDIR
	$CP -p -R /etc/postfix/* ${POSTDIR}
	$POSTCONF -v > ${POSTDIR}/postconf_-v.out 2>&1
	$POSTCONF -l > ${POSTDIR}/postconf_-l.out 2>&1
fi

##############################################################################
# Exim Section
##############################################################################

Echo "[*] Exim Section"

if [ -d /etc/exim ]; then
  EXIMDIR=${LOGDIR}/etc
  $CP -p -R /etc/exim  ${EXIMDIR}
fi

##############################################################################
# Time Section
##############################################################################

Echo "[*] Time Section"

TIMEDIR=${LOGDIR}/etc/time

if [ ! -d ${TIMEDIR} ]; then
	$MKDIR -p ${TIMEDIR}
fi

$DATE > ${TIMEDIR}/date

if [ -f /etc/timezone ]; then 
	$CP -p /etc/timezone ${TIMEDIR}/timezone
fi

if [ -f /usr/share/zoneinfo ]; then 
	$CP -p /usr/share/zoneinfo ${TIMEDIR}/zoneinfo
fi

if [ -f /etc/ntp.drift ]; then
	$CP -p /etc/ntp.drift ${TIMEDIR}/ntp.drift
fi

if [ -x $HWCLOCK ]; then
	$HWCLOCK --show > ${TIMEDIR}/hwclock_--show.out 
fi

if [ -x $NTPQ  ]; then
	$NTPQ -p > ${TIMEDIR}/ntpq_-p.out 2>&1
fi

if [ -f /etc/ntp/step-tickers ]; then 
	$CP -p /etc/ntp/step-tickers ${LOGDIR}/etc
fi

if [ -f /etc/ntp/ntpservers ]; then
	$CP -p /etc/ntp/ntpservers   ${LOGDIR}/etc
fi

##############################################################################
# PPP Section
##############################################################################

Echo "[*] PPP Section"

PPPDIR=${LOGDIR}/etc/ppp
if [ ! -d ${PPPDIR} ]; then
	$MKDIR -p ${PPPDIR}
	$MKDIR -p ${PPPDIR}/peers
fi

if [ -d /etc/ppp ]; then
	$CP -R -p /etc/ppp/* ${PPPDIR} 2>&1
fi

if [ -d /etc/wvdial ] ; then
	$CP -p /etc/ppp/options.* ${PPPDIR} > /dev/null 2>&1
	$CP -p -R /etc/ppp/peers/* ${PPPDIR}/peers > /dev/null 2>&1
fi

##############################################################################
# Apache Section
##############################################################################

Echo "[*] Apache Section"

if [ -d /etc/httpd ]; then
	APACHEDIR=${LOGDIR}/httpd
else
	APACHEDIR=${LOGDIR}/apache
fi

if [ ! -d $APACHEDIR ]; then
	$MKDIR -p ${APACHEDIR}
fi

if [ -x $APACHECTL ]; then
	$APACHECTL status > ${APACHEDIR}/apachectl_status.out 2>&1
fi

if [ -x $APACHE2CTL ]; then
	$APACHE2CTL status > ${APACHEDIR}/apache2ctl_status.out 2>&1
fi

##############################################################################
# Samba Section
##############################################################################

Echo "[*] Samba Section"

SAMBADIR=${LOGDIR}/disks/samba

if [ ! -d ${SAMBADIR} ]; then
	$MKDIR -p ${SAMBADIR}
fi

if [ -x $TESTPARM  ]; then
	echo "y" | $TESTPARM > ${SAMBADIR}/testparm.out 2>&1
fi

if [ -x $WBINFO ]; then
	$WBINFO -g > ${SAMBADIR}/wbinfo_-g.out 2>&1
  $WBINFO -u > ${SAMBADIR}/wbinfo_-g.out 2>&1
fi

##############################################################################
# OpenSSH Section
##############################################################################

Echo "[*] OpenSSH Section"

SSHDIR=${LOGDIR}/etc/ssh
$MKDIR -p ${SSHDIR}

if [ -f /etc/nologin ]; then
	$CP -p /etc/nologin ${LOGDIR}/etc/nologin
fi

if [ -d /etc/ssh/ssh_config ]; then
	$CP -p /etc/ssh/ssh_config ${SSHDIR}/ssh_config
fi

if [ -d /etc/ssh/sshd_config ]; then
	$CP -p /etc/ssh/sshd_config ${SSHDIR}/sshd_config
fi

##############################################################################
# X11 Section
##############################################################################

Echo "[*] X11 Section"

XDIR=${LOGDIR}/X  
$MKDIR -p $XDIR

if [ -d /etc/X11 ]; then
	$CP -R -p /etc/X11 ${LOGDIR}/etc
fi

if [ -x $SYSP ]; then
	$SYSP -c          > ${XDIR}/sysp_-c.out
	$SYSP -s mouse    > ${XDIR}/sysp_-s_mouse.out
	$SYSP -s keyboard > ${XDIR}/sysp_-s_keyboard.out
fi

if [ -x $_3DDIAG ]; then
	$_3DDIAG > ${XDIR}/3Ddiag.out
fi

##############################################################################
# This section is for removing any information 
# about hardcoded passwords inserted in files.
##############################################################################

if [ -f /etc/wvdial.conf ]; then 
	$CAT /etc/wvdial.conf | sed -e /^Password/d  > ${LOGDIR}/etc/wvdial.conf 
fi

##############################################################################
# Tar Up Support Directory | GPG support
##############################################################################

cd ${LOGTOP}
$TAR czf ${TARFILE} . > /dev/null 2>&1  

if [[ ${GPG} -eq "1" ]]; then 
  #--------------------------------------------------------------------------
  # Import GPG public key:   (0x57260789) 
  #                          Facundo M. de la Cruz
  #                          <fdelacruz@dc-solutions.com.ar> 
  #--------------------------------------------------------------------------
  echo "[*] Importing GPG public key: $GPG_ID"
  gpg --import << EOF  
-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v1.4.12 (GNU/Linux)

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
AAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0
NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKT
lJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl
5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL
/8QAtREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdhcRMiMoEIFEKRobHB
CSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpj
ZGVmZ2hpanN0dXZ3eHl6goOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3
uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oADAMBAAIR
AxEAPwD3kzqO9R/alOenFUGuDiq5nBZ+e/8ASlcVy/PfBAMAE+lVGvi3OMCqF3cb
SuK4Xxh8TNM8Kt9mffd6gRn7NGQNo7bm7fqfagZ6E93l1wcnOBWRf+KdLsJfKu9Q
s4pP7jzqGJ+hNfN3iDx3rniqcm5uPs9oPuW0D7V/Hux+v6VzE0pib5CMemKQ7H1R
b+MNM1CUx2tzA5H9yVX/AJE4qK61q3i1C3gYjdNnaQOCQM18sJdTRuHjYq6nIZeC
D61al1jU7ySMz3k7kNkZc9aLAfVMd0knKKMeopzTZ7V5p8NPGC6pBNp13L/pcbbk
LH/WL7fTFdz+63Sbldzu4yGbsPXigRcMmelRlqjTAHEYjHpx/SgHLt7YH9f60DGc
G5YgDIQfjk//AFqeeaanJdvVv5cf40+gBhUUmwU/FGKAIjHRUtFAHW7hjrVfcN8n
+9/Snbhgcj8qhBy0n+9/QUEHP+NNdTw9oE+olQ7xriNCfvOTgD86+XrmW81fVpri
ZnnupnLu2OpP9K9x+N5kXwvZOpOwXY3D/gLYrz3wdpoS2W5KZklOcn0qZS5Vc2pQ
53Yy7fwpqNwisUWMH0GcVYvPCEllbrLcS7mb7oNepWkICruYeuBWd4i05r6GN4V3
FD90dawVRtnXKhFLQ8yOlCJBhQeccjpWdcWwjTf3zxXYXSLtIxtYHJB+lc9fpiIL
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
EHvKMZD4F6S7F7vVQw==
=kL5L
-----END PGP PUBLIC KEY BLOCK-----
EOF
  $GPG_BIN -e -r ${GPG_ID} ${TARFILE}
  TARFILE="${TARFILE}.gpg"
fi

if [ -t 0 ]; then
		$CAT <<- EOF

**********************************************************************
The Tar file ${TARFILE} 
has been created for support purposes.
	
You can email the tar file to those providing you 
with technical support to <$SUPPORT>
**********************************************************************
EOF
fi
