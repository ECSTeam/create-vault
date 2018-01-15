#!/bin/bash
##########################################################
#
#  Sets the pipeline that runs tests when the create-vault
#  repo changes. 
#
#  Arguments:
#       -h - help message
#       -t <fly target> - the target of the fly command. Defaults to "gold".
#
##########################################################

set -e 

function usage() {
cat <<EOF
USAGE:
   set-vault-iac-test-pipeline.sh [-t <fly target>]
EOF
}

# Default the fly target to "gold".
FLY_TARGET="gold"

# Parse the command argument list
while getopts "ht:" opt; do
    case "$opt" in
    h|\?)
        usage
        exit 0
        ;;
    t)
        FLY_TARGET=$OPTARG
    esac
done
    
set-pipeline/set-pipeline.sh $FLY_TARGET pipeline.yml config.yml credentials.yml.stub create-vault-iac-test