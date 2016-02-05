#!/bin/sh
#
# Delete an openstack vm and all its associated resources (only to be used as a
# rollback for the create-vm-openstack.sh script)
#
# @version 0.0.1
# @date 2016-01-21
# @author Aaron Ward
#
# This script must be run from a system with openstack CLI tools installed
# (see add-service-openstack.sh) and the appropriate environment variables
# in place for command-line access to openstack utilities on a given
# service. Rudimentary testing has only been done on the trystack.org service.

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

# find floating ip
echo "Finding floating IP"
OS_FLOATING_IP=$(nova floating-ip-list | head -n 4 | tail -n 1 | awk '{print $4}')

# delete floating ip
echo "Deleting floating IP address $OS_FLOATING_IP"
nova floating-ip-disassociate $OS_INSTANCE_NAME $OS_FLOATING_IP
nova floating-ip-delete $OS_FLOATING_IP

# delete instance
echo "Deleting instance $OS_INSTANCE_NAME"
nova delete $OS_INSTANCE_NAME

# delete security group
echo "Deleting security group $OS_SECURITY_GROUP_NAME"
nova secgroup-delete $OS_SECURITY_GROUP_NAME

# delete key
echo "Deleting keypair $OS_KEY_NAME"
nova keypair-delete $OS_KEY_NAME
rm $OS_KEY_NAME.pem

# delete router
echo "Deleting router $OS_ROUTER_NAME"
neutron router-interface-delete $OS_ROUTER_NAME $OS_SUBNET_NAME
neutron router-delete $OS_ROUTER_NAME

# delete network
# NOTE apparently it is possible to have multiple networks with the same name, this is bad.
echo "Deleting network $OS_NETWORK_NAME"
neutron net-delete $OS_NETWORK_NAME