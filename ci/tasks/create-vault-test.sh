#!/bin/bash
#########################################################
#
#  Test the script that creates a Vault BOSH deployment
#  functions as expected.
#
#########################################################

# Exit if a command fails.
set -e 

# Print commands executed.
set -x

export BOSH_CLIENT=admin
export BOSH_CLIENT_SECRET=$BOSH_ADMIN_PASSWORD
export BOSH_ENVIRONMENT="concourse-director"

bosh2 alias-env $BOSH_ENVIRONMENT -e $BOSH_DIRECTOR --ca-cert $BOSH_CA

bosh2 is