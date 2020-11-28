#!/bin/bash
#
################################################################################
#
# Rename Objects v0.2 (08-04-2020)
#
# Copyright (c) 2020 Rick Hoppe
# Distributed under the MIT license
#
# v0.1 Initial version
# v0.2 Added dos2unix to remove Windows formatting
#
# Rename objects (bulk) from CSV file. You can choose to publish the session
# automatically or disconnect and take over manually with SmartConsole to
# verify the changes before manually publishing the session.
#
# If there are errors when renaming actions are taking place the session will
# be discarded and the errors will be displayed
#
# Create a CSV file in the following format when renaming TCP services
# (note the header line needed for all type of objectchanges):
# name,new-name
# t-80,TCP_80
# T-443,TCP_443
#
# TODO:
# - Do you have suggestions? Let me know.
#
# Usage:
# ./rename_objects.sh username domainname changenumber tcp|udp|hosts|networks|servicegroups|networkgroups csvfile nopublish|publish
#
# Example:
# ./rename_objects.sh johndoe DMS-CP-1 CHG4726 hosts rename_hosts.csv nopublish
#
################################################################################

###################################
# Pre-startup Variables
###################################
VERSION="0.2"


###################################
# Cleanup temporary files
###################################
if [ -f "id.txt" ]; then
  rm id.txt
fi


###################################
# Usage function
###################################
function script_usage_long()
{
printf "\nrename_objects.sh version %s\n\n" "$VERSION"
printf "Usage:\n"
printf "  ./rename_objects.sh [ARGUMENTS]...\n\n"
printf "Rename objects listed in a CSV file using the Management API of a Check Point\n"
printf "Multi-Domain Management Server running on R80.x\n\n"
printf "Mandatory arguments to supply when running the script.\n"
printf "  username       Put your username that has Write access to the DMS here.\n"
printf "  domainname     Put the name of the DMS here.\n"
printf "  changenumber   Put in your changenumber. It will be used for session info.\n"
printf "  objecttype     Can be either tcp|udp|hosts|networks|servicegroups|networkgroups.\n"
printf "  filename       The CSV file that lists the current and new names of the\n"
printf "                 objects.\n"
printf "  sessionaction  Can be either nopublish|publish.\n\n"
printf "Example:\n"
printf "  ./rename_objects.sh johndoe DMS-CP-1 CHG4726 hosts rename_hosts.csv nopublish\n\n"
printf "If there are errors or warnings when renaming objects the complete session will\n"
printf "be discarded. A log will be shown so you can fix it before trying again.\n\n"
printf "The CSV file should always start with this line:\n"
printf "name,new-name\n\n"
printf "From this point you can add new lines with the current name and the new name of\n"
printf "the objects:\n"
printf "Gooogle-DNS1,Google-DNS1\n"
printf "Googgle-DNS2,Google-DNS2\n"
printf "etc...\n\n"
printf "When you choose not to publish you can takeover the session in SmartConsole.\n"
printf "In SmartConsole you can then verify the changes and publish it manually.\n"
}

function script_usage_short()
{
printf "\nExample:\n"
printf "  ./rename_objects.sh johndoe DMS-CP-1 CHG4726 hosts rename_hosts.csv nopublish\n\n"
printf "Run rename_objects.sh without arguments for complete help information.\n\n"
}


###################################
# Arguments checks
###################################
if [ $# -lt 6 ]
  then
    script_usage_long
    exit 1
fi

if [[ $4 != "tcp" ]] && [[ $4 != "udp" ]] && [[ $4 != "hosts" ]] && [[ $4 != "networks" ]] && [[ $4 != "servicegroups" ]] && [[ $4 != "networkgroups" ]]
  then
    printf "\nError: %s is not a valid objecttype.\n" "$4"
    script_usage_short
    exit 1
fi

if [ ! -f "$5" ]
  then
    printf "\nError: Specified file %s does not exist.\n" "$5"
    script_usage_short
    exit 1
fi

if [[ $6 != "publish" ]] && [[ $6 != "nopublish" ]]
  then
    printf "\nError: %s is not a valid session action.\n" "$6"
    script_usage_short
    exit 1
fi


###################################
# Variables
###################################
NO_OBJECTS=$(expr $(cat $5 | wc -l) - 1)


###################################
# Functions
###################################
function rename_tcp_services()
{
RENAME_TYPE="TCP services"
SESSION_NAME="$3"
SESSION_DESC="$3 - Rename $RENAME_TYPE from $5"

mgmt_cli set session new-name "$SESSION_NAME" description "$SESSION_DESC" --version "$MGMT_VER" -s id.txt
printf "\n\nNumber of objects to change: %s\n" "$NO_OBJECTS"
mgmt_cli set service-tcp -b "$5" --version "$MGMT_VER" -s id.txt >output.log
(($? != 0)) && {
discard_session "$1" "$2" "$3" "$4" "$5" "$6"
               }
}

function rename_udp_services()
{
RENAME_TYPE="UDP services"
SESSION_NAME="$3"
SESSION_DESC="$3 - Rename $RENAME_TYPE from $5"

mgmt_cli set session new-name "$SESSION_NAME" description "$SESSION_DESC" --version "$MGMT_VER" -s id.txt
printf "\n\nNumber of objects to change: %s\n" "$NO_OBJECTS"
mgmt_cli set service-udp -b "$5" --version "$MGMT_VER" -s id.txt >output.log
(($? != 0)) && {
discard_session "$1" "$2" "$3" "$4" "$5" "$6"
               }
}

function rename_hosts()
{
RENAME_TYPE="Hosts"
SESSION_NAME="$3"
SESSION_DESC="$3 - Rename $RENAME_TYPE from $5"

mgmt_cli set session new-name "$SESSION_NAME" description "$SESSION_DESC" --version "$MGMT_VER" -s id.txt
printf "\n\nNumber of objects to change: %s\n" "$NO_OBJECTS"
mgmt_cli set host -b "$5" --version "$MGMT_VER" -s id.txt >output.log
(($? != 0)) && {
discard_session "$1" "$2" "$3" "$4" "$5" "$6"
               }
}

function rename_networks()
{
RENAME_TYPE="Networks"
SESSION_NAME="$3"
SESSION_DESC="$3 - Rename $RENAME_TYPE from $5"

mgmt_cli set session new-name "$SESSION_NAME" description "$SESSION_DESC" --version "$MGMT_VER" -s id.txt
printf "\n\nNumber of objects to change: %s\n" "$NO_OBJECTS"
mgmt_cli set network -b "$5" --version "$MGMT_VER" -s id.txt >output.log
(($? != 0)) && {
discard_session "$1" "$2" "$3" "$4" "$5" "$6"
               }
}

function rename_servicegroups()
{
RENAME_TYPE="Service Groups"
SESSION_NAME="$3"
SESSION_DESC="$3 - Rename $RENAME_TYPE from $5"

mgmt_cli set session new-name "$SESSION_NAME" description "$SESSION_DESC" --version "$MGMT_VER" -s id.txt
printf "\n\nNumber of objects to change: %s\n" "$NO_OBJECTS"
mgmt_cli set service-group -b "$5" --version "$MGMT_VER" -s id.txt >output.log
(($? != 0)) && {
discard_session "$1" "$2" "$3" "$4" "$5" "$6"
               }
}

function rename_networkgroups()
{
RENAME_TYPE="Network Groups"
SESSION_NAME="$3"
SESSION_DESC="$3 - Rename $RENAME_TYPE from $5"
mgmt_cli set session new-name "$SESSION_NAME" description "$SESSION_DESC" --version "$MGMT_VER" -s id.txt
printf "\n\nNumber of objects to change: %s\n" "$NO_OBJECTS"
mgmt_cli set group -b "$5" --version "$MGMT_VER" -s id.txt >output.log
(($? != 0)) && {
discard_session "$1" "$2" "$3" "$4" "$5" "$6"
               }
}

function discard_session()
{
printf "\nSession will be discarded and logged out. See output below:\n\n"
mgmt_cli discard --version "$MGMT_VER" -s id.txt
mgmt_cli logout --version "$MGMT_VER" -s id.txt > /dev/null
cat output.log
rm output.log
rm id.txt
exit 1
}

function publish()
{
mgmt_cli publish --version "$MGMT_VER" -s id.txt > /dev/null
}

function no_publish()
{
printf "\n\nRename %s finished. Please take over your session in SmartConsole and check/publish manually.\n\n" "$RENAME_TYPE"
printf "Domain: %s\n" "$2"
printf "User: %s\n" "$1"
printf "Session name: %s\n" "$SESSION_NAME"
printf "Session description: %s\n\n" "$SESSION_DESC"
}

function logout()
{
mgmt_cli logout --version "$MGMT_VER" -s id.txt > /dev/null
rm id.txt
exit 0
}


###################################
# Hello world!
###################################
printf "\nINFORMATION: Make sure you don't have any other active GUI sessions\n"
printf "to DMS %s with user %s.\n\n" "$2" "$1"
printf "Hi %s! Please enter your password to login to DMS %s.\n" "$1" "$2"
mgmt_cli login user "$1" domain "$2" > id.txt
(($? != 0)) && { cat id.txt; rm id.txt; exit 1; }

MGMT_VER=$(grep api-server-version id.txt | awk '{print $2}' | xargs)

printf "\n\n"
dos2unix "$5"

if [[ $4 == "tcp" ]]
then
  rename_tcp_services "$1" "$2" "$3" "$4" "$5" "$6"

elif [[ $4 == "udp" ]]
then
  rename_udp_services "$1" "$2" "$3" "$4" "$5" "$6"

elif [[ $4 == "hosts" ]]
then
  rename_hosts "$1" "$2" "$3" "$4" "$5" "$6"

elif [[ $4 == "networks" ]]
then
  rename_networks "$1" "$2" "$3" "$4" "$5" "$6"

elif [[ $4 == "servicegroups" ]]
then
  rename_servicegroups "$1" "$2" "$3" "$4" "$5" "$6"

elif [[ $4 == "networkgroups" ]]
then
  rename_networkgroups "$1" "$2" "$3" "$4" "$5" "$6"
fi

if [[ $6 == "nopublish" ]]
then
  no_publish "$1" "$2" "$3" "$4" "$5" "$6"
  logout "$1" "$2" "$3" "$4" "$5" "$6"

elif [[ $6 == "publish" ]]
then
  publish "$1" "$2" "$3" "$4" "$5" "$6"
  logout "$1" "$2" "$3" "$4" "$5" "$6"
fi

exit 0
