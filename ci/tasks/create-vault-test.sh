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

# The cert comes in as a string. Need to convert it back to a proper PEM format
echo $BOSH_CA > boshca.pem
tr ' ' '\n' < boshca.pem > newline.pem
sed -e ':a' -e 'N' -e '$!ba' -e 's/N\nC/N C/g' newline.pem > topfixed.pem
sed -e ':a' -e 'N' -e '$!ba' -e 's/D\nC/D C/g' topfixed.pem > finalboshca.pem

bosh2 alias-env $BOSH_ENVIRONMENT -e $BOSH_DIRECTOR --ca-cert finalboshca.pem

bosh2 is