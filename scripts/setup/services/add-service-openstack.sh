#!/bin/bash
#
# Add openstack command-line clients to an existing linux system.
#
# @version 0.1
# @date 2016-01-27
# @author Aaron Ward
#
# Developed on CentOS 7, not tested elsewhere.
#
# NOTE : Output from install scripts is squelched, only exit codes are checked.
#
# Usage:
#   add-service-openstack [options]
#
#   Options:
#   -q : quiet mode, most output is squelched (critical errors are not).
#
# Examples:
#   source <(curl -s "http://geeq.com/arsenal/setup/services/add-service-openstack.sh")
#   source <(curl -s "http://geeq.com/arsenal/setup/services/add-service-openstack.sh") -q
#
# NOTE : Uses "return" instead of "exit" to prevent forced logout during remote
# execution. It may be necessary to replace "return" with "exit" to run locally.
#
# Known issues:
#   Running the script a second time with -q seems to ignore the flag, why?

SCRIPT_NAME="add service openstack"

LOG_DIR=/var/log
LOGFILE=$LOG_DIR/arsenal.log
VERSION=0.1

ROOT_UID=0     # Only users with $UID 0 have root privileges.

# Errors
E_NOTROOT=87     # Non-root exit error.
E_FAILURE=101    # Script failed to complete
E_OSVERSION=102  # Unsupported OS release

# require root user
if [ "$UID" -ne "$ROOT_UID" ]
then
  echo "Must be root to run this script."
  return $E_NOTROOT
fi

# Require CentOS 7
if [ "$(cat /etc/system-release | grep -c '^CentOS Linux release 7')" -ne "1" ]
then
  echo "Unsupported OS release, this script has only been tested on CentOS 7."
  return $E_OSVERSION
fi

DATE=$(date +"%Y-%m-%d %H:%M:%S")

# parameters
unset FLAG_Q

while getopts "q" opt; do
  case $opt in
    q)  FLAG_Q=$opt;;
    \?) echo Unknown flag.
  esac
done

echo [$DATE] [DEBUG] [$SCRIPT_NAME] Adding openstack command-line clients. >> $LOGFILE

# splash
if [ "$FLAG_Q" != "q" ]
then
  echo -----------------------------------------------------------
  echo   Add openstack command-line clients
  echo   Version $VERSION
  echo -----------------------------------------------------------
fi

echo [$DATE] [INFO] [$SCRIPT_NAME] Starting $SCRIPT_NAME version $VERSION. >> $LOGFILE

# install python development package
if [ "$FLAG_Q" != "q" ]
then
  echo installing python-devel
fi
echo [$DATE] [DEBUG] [$SCRIPT_NAME] Installing python-devel >> $LOGFILE
yum install -y -q python-devel > /dev/null 2>&1

if [ "$?" -ne "0" ]
then
  echo [$DATE] [ERROR] [$SCRIPT_NAME] Install failed with non-zero exit code : $? >> $LOGFILE
  echo [$DATE] [ERROR] Install failed with non-zero exit code : $?
  return $E_FAILURE
fi

# install pip
if [ "$FLAG_Q" != "q" ]
then
  echo installing pip
fi
echo [$DATE] [DEBUG] [$SCRIPT_NAME] Installing pip >> $LOGFILE
curl -s "https://bootstrap.pypa.io/get-pip.py" -o "get-pip.py"
python <(curl -s "https://bootstrap.pypa.io/get-pip.py") > /dev/null 2>&1

if [ "$?" -ne "0" ]
then
  echo [$DATE] [ERROR] [$SCRIPT_NAME] Install failed with non-zero exit code : $? >> $LOGFILE
  echo [$DATE] [ERROR] Install failed with non-zero exit code : $?
  return $E_FAILURE
fi

# install gcc (required for netifaces)
if [ "$FLAG_Q" != "q" ]
then
  echo installing gcc
fi
echo [$DATE] [DEBUG] [$SCRIPT_NAME] Installing gcc >> $LOGFILE
yum install -y -q gcc > /dev/null 2>&1

if [ "$?" -ne "0" ]
then
  echo [$DATE] [ERROR] [$SCRIPT_NAME] Install failed with non-zero exit code : $? >> $LOGFILE
  echo [$DATE] [ERROR] Install failed with non-zero exit code : $?
  return $E_FAILURE
fi

# install openstack
if [ "$FLAG_Q" != "q" ]
then
  echo installing openstack command-line clients
fi
echo [$DATE] [DEBUG] [$SCRIPT_NAME] Installing openstack command-line clients >> $LOGFILE
pip install -q python-openstackclient > /dev/null 2>&1

if [ "$?" -ne "0" ]
then
  echo [$DATE] [ERROR] [$SCRIPT_NAME] Install failed with non-zero exit code : $? >> $LOGFILE
  echo [$DATE] [ERROR] Install failed with non-zero exit code : $?
  return $E_FAILURE
fi

if [ "$FLAG_Q" != "q" ]
then
  echo All done.
fi

echo [$DATE] [DEBUG] [$SCRIPT_NAME] Openstack utilities setup complete. >> $LOGFILE

return 0
