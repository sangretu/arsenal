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
echo "Creating network $OS_NETWORK_NAME"
neutron net-create $OS_NETWORK_NAME
neutron subnet-create $OS_NETWORK_NAME $OS_SUBNET_CIDR --name $OS_SUBNET_NAME --dns-nameserver $OS_NAMESERVER

# create router
echo "Creating router $OS_ROUTER_NAME"
neutron router-create $OS_ROUTER_NAME
neutron router-gateway-set $OS_ROUTER_NAME $OS_EXTERNAL_NETWORK_NAME
neutron router-interface-add $OS_ROUTER_NAME $OS_SUBNET_NAME

# create key
echo "Creating keypair $OS_KEY_NAME"
nova keypair-add $OS_KEY_NAME > $OS_KEY_NAME.pem
chmod 600 $OS_KEY_NAME.pem

# create security group
echo "Creating security group $OS_SECURITY_GROUP_NAME"
nova secgroup-create $OS_SECURITY_GROUP_NAME "$OS_SECURITY_GROUP_DESCRIPTION"
nova secgroup-add-rule $OS_SECURITY_GROUP_NAME icmp -1 -1 0.0.0.0/0
nova secgroup-add-rule $OS_SECURITY_GROUP_NAME tcp 22 22 0.0.0.0/0
nova secgroup-add-rule $OS_SECURITY_GROUP_NAME tcp 80 80 0.0.0.0/0

# launch instance
echo "Launching instance $OS_INSTANCE_NAME"
nova boot --flavor m1.small --image f1e2c717-b8c6-4ae0-ad7d-7943d9333e69 --key-name $OS_KEY_NAME --security-groups $OS_SECURITY_GROUP_NAME $OS_INSTANCE_NAME

# add floating ip
echo "Allocating floating IP"
OS_FLOATING_IP=$(nova floating-ip-create | head -n 4 | tail -n 1 | awk '{print $4}')

# associate floating ip
echo "Associating floating IP $OS_FLOATING_IP"
nova add-floating-ip $OS_INSTANCE_NAME $OS_FLOATING_IP

# user instructions
echo "Wait a few moments for the vm to boot, then try logging in with:"
echo "ssh -i $OS_KEY_NAME.pem centos@$OS_FLOATING_IP"
echo "or:"
echo "ssh -o \"StrictHostKeyChecking no\" -i $OS_KEY_NAME.pem centos@$OS_FLOATING_IP"