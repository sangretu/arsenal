#!/bin/bash
#
# Create an openstack vm, including network infrastructure.
#
# @version 0.1
# @date 2016-01-27
# @author Aaron Ward (aaron.of.ward@gmail.com)
#
# This script must be run from a system with OpenStack CLI clients installed
# (see add-service-openstack.sh) and the appropriate environment variables
# in place for command-line access to OpenStack utilities on a given
# service. Rudimentary testing has only been done on the trystack.org service.
#
# Examples:
#   source <(curl -s "http://sangretu.github.io/arsenal/scripts/setup/services/create-vm-openstack.sh")

SCRIPT_NAME="create vm openstack"

# TODO: /var/log/arsenal.log is not writable by the average user, temporarily moving log until I put in a proper solution.

LOG_DIR=~
LOGFILE=$LOG_DIR/arsenal.log
VERSION=0.1

# Errors
E_FAILURE=101    # Script failed to complete
E_OSVERSION=102  # Unsupported OS release

# Require CentOS 7
if [ "$(cat /etc/system-release | grep -c '^CentOS Linux release 7')" -ne "1" ]
then
  echo "Unsupported OS release, this script has only been tested on CentOS 7."
  return $E_OSVERSION
fi

DATE=$(date +"%Y-%m-%d %H:%M:%S")

# parameters
VERBOSITY_DEFAULT="1"
VERBOSITY="$VERBOSITY_DEFAULT"

# workaround to ensure parameters are read
# see http://stackoverflow.com/questions/23581368/bug-in-parsing-args-with-getopts-in-bash
OPTIND=1

while getopts "qv" opt; do
  case $opt in
    q)  VERBOSITY=$((VERBOSITY - 1));;
    v)  VERBOSITY=$((VERBOSITY + 1));;
    \?) echo Unknown flag.
  esac
done

# TODO: add confirmation and -y option

echo [$DATE] [DEBUG] [$SCRIPT_NAME] Creating OpenStack VM. >> $LOGFILE

# splash
if [ "$VERBOSITY" -ge "$VERBOSITY_DEFAULT" ]
then
  echo -----------------------------------------------------------
  echo   Create OpenStack VM
  echo   Version $VERSION
  echo -----------------------------------------------------------
fi

echo [$DATE] [INFO] [$SCRIPT_NAME] Starting $SCRIPT_NAME version $VERSION. >> $LOGFILE

# environment variables, default settings create "test-*" named resources
OS_NETWORK_NAME="test-network"
OS_EXTERNAL_NETWORK_NAME="public"
OS_SUBNET_NAME="test-subnet"
OS_SUBNET_CIDR="10.71.81.0/24"
OS_NAMESERVER="8.8.8.8"
OS_ROUTER_NAME="test-router"
OS_KEY_NAME="test-key"
OS_SECURITY_GROUP_NAME="test-security-group"
OS_SECURITY_GROUP_DESCRIPTION=""
OS_INSTANCE_NAME="test-instance"

# create network
if [ "$VERBOSITY" -ge "$VERBOSITY_DEFAULT" ]
then
  echo "Creating network $OS_NETWORK_NAME"
fi

# NOTE these commands do not support quiet mode, so I had to improvise
# NOTE apparently it is possible to have multiple networks with the same name, this is bad.
if [ "$VERBOSITY" -gt "$VERBOSITY_DEFAULT" ]
then
  neutron net-create $OS_NETWORK_NAME
  neutron subnet-create $OS_NETWORK_NAME $OS_SUBNET_CIDR --name $OS_SUBNET_NAME --dns-nameserver $OS_NAMESERVER
else
  neutron net-create $OS_NETWORK_NAME > /dev/null 2>&1
  neutron subnet-create $OS_NETWORK_NAME $OS_SUBNET_CIDR --name $OS_SUBNET_NAME --dns-nameserver $OS_NAMESERVER > /dev/null 2>&1
fi

if [ "$?" -ne "0" ]
then
  echo [$DATE] [ERROR] [$SCRIPT_NAME] Install failed with non-zero exit code : $? >> $LOGFILE
  echo [$DATE] [ERROR] Install failed with non-zero exit code : $?
  return $E_FAILURE
fi

# create router
if [ "$VERBOSITY" -ge "$VERBOSITY_DEFAULT" ]
then
  echo "Creating router $OS_ROUTER_NAME"
fi
neutron router-create $OS_ROUTER_NAME
neutron router-gateway-set $OS_ROUTER_NAME $OS_EXTERNAL_NETWORK_NAME
neutron router-interface-add $OS_ROUTER_NAME $OS_SUBNET_NAME

if [ "$?" -ne "0" ]
then
  echo [$DATE] [ERROR] [$SCRIPT_NAME] Install failed with non-zero exit code : $? >> $LOGFILE
  echo [$DATE] [ERROR] Install failed with non-zero exit code : $?
  return $E_FAILURE
fi

# create key
if [ "$VERBOSITY" -ge "$VERBOSITY_DEFAULT" ]
then
  echo "Creating keypair $OS_KEY_NAME"
fi
nova keypair-add $OS_KEY_NAME > $OS_KEY_NAME.pem

if [ "$?" -ne "0" ]
then
  echo [$DATE] [ERROR] [$SCRIPT_NAME] Install failed with non-zero exit code : $? >> $LOGFILE
  echo [$DATE] [ERROR] Install failed with non-zero exit code : $?
  return $E_FAILURE
fi

chmod 600 $OS_KEY_NAME.pem

# create security group
if [ "$VERBOSITY" -ge "$VERBOSITY_DEFAULT" ]
then
  echo "Creating security group $OS_SECURITY_GROUP_NAME"
fi
nova secgroup-create $OS_SECURITY_GROUP_NAME "$OS_SECURITY_GROUP_DESCRIPTION"
nova secgroup-add-rule $OS_SECURITY_GROUP_NAME icmp -1 -1 0.0.0.0/0
nova secgroup-add-rule $OS_SECURITY_GROUP_NAME tcp 22 22 0.0.0.0/0
nova secgroup-add-rule $OS_SECURITY_GROUP_NAME tcp 80 80 0.0.0.0/0

if [ "$?" -ne "0" ]
then
  echo [$DATE] [ERROR] [$SCRIPT_NAME] Install failed with non-zero exit code : $? >> $LOGFILE
  echo [$DATE] [ERROR] Install failed with non-zero exit code : $?
  return $E_FAILURE
fi

# launch instance
if [ "$VERBOSITY" -ge "$VERBOSITY_DEFAULT" ]
then
  echo "Launching instance $OS_INSTANCE_NAME"
fi
nova boot --flavor m1.small --image f1e2c717-b8c6-4ae0-ad7d-7943d9333e69 --key-name $OS_KEY_NAME --security-groups $OS_SECURITY_GROUP_NAME $OS_INSTANCE_NAME

if [ "$?" -ne "0" ]
then
  echo [$DATE] [ERROR] [$SCRIPT_NAME] Install failed with non-zero exit code : $? >> $LOGFILE
  echo [$DATE] [ERROR] Install failed with non-zero exit code : $?
  return $E_FAILURE
fi

# add floating ip
if [ "$VERBOSITY" -ge "$VERBOSITY_DEFAULT" ]
then
  echo "Allocating floating IP"
fi
OS_FLOATING_IP=$(nova floating-ip-create | head -n 4 | tail -n 1 | awk '{print $4}')

if [ "$?" -ne "0" ]
then
  echo [$DATE] [ERROR] [$SCRIPT_NAME] Install failed with non-zero exit code : $? >> $LOGFILE
  echo [$DATE] [ERROR] Install failed with non-zero exit code : $?
  return $E_FAILURE
fi

# associate floating ip
if [ "$VERBOSITY" -ge "$VERBOSITY_DEFAULT" ]
then
  echo "Associating floating IP $OS_FLOATING_IP"
fi
nova add-floating-ip $OS_INSTANCE_NAME $OS_FLOATING_IP

if [ "$?" -ne "0" ]
then
  echo [$DATE] [ERROR] [$SCRIPT_NAME] Install failed with non-zero exit code : $? >> $LOGFILE
  echo [$DATE] [ERROR] Install failed with non-zero exit code : $?
  return $E_FAILURE
fi

# user instructions
echo
echo "Wait a few moments for the vm to boot, then try logging in with:"
echo "ssh -i $OS_KEY_NAME.pem centos@$OS_FLOATING_IP"
echo "or:"
echo "ssh -o \"StrictHostKeyChecking no\" -i $OS_KEY_NAME.pem centos@$OS_FLOATING_IP"

echo [$DATE] [DEBUG] [$SCRIPT_NAME] Openstack VM creation complete. >> $LOGFILE

return 0