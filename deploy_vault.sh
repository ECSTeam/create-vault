#!/bin/bash
##################################################
#
#   Performs a Vault BOSH deployment. This script expects
#   the bosh director is targeted. A "generated" 
#   directory is created under the current directory
#   that houses files generated during the deployment
#   and the keys generated during the vault initialization.
#
#   Arguments:
#     -v <Vault FQDN> - the fully qualified Vault domain name.
#     -d <directory>  - Directory that will hold the generated
#                       deployment archives.
#     
##################################################
set -e 
set -x 

function usage() {
cat <<EOF
USAGE:
   deploy_vault.sh -v <Vault FQDN> -d <deployment archives directory>
EOF
}

# Fully Qualified Domain Name of Vault.
VAULT_FQDN=""
# Directory that houses files related to the given deployment
DEPLOYMENT_DIR=""

while getopts "v:d:" opt; do
    case "$opt" in
    v)
        VAULT_FQDN=$OPTARG
        ;;
    d)
        DEPLOYMENT_DIR=$OPTARG
        ;;
    *)
        echo "Unknown argument - $opt"
        usage
        exit 1
        ;;    
    esac
done

# Release and stemcell to deploy.
VAULT_RELEASE=https://bosh.io/d/github.com/cloudfoundry-community/vault-boshrelease
STEMCELL=https://bosh.io/d/stemcells/bosh-vsphere-esxi-ubuntu-trusty-go_agent

VAULT_KEYS=$DEPLOYMENT_DIR/vault_keys

# Create the directory to house the deployment files.
mkdir -p $DEPLOYMENT_DIR

# Uploaded the release and stemcell to BOSH
bosh2 ur $VAULT_RELEASE
bosh2 us $STEMCELL
# Deploy vault
bosh2 -n -d concourse-vault deploy vault_manifest_template.yml \
  --vars-store=$DEPLOYMENT_DIR/vars.yml \
  -v internal_ip=$VAULT_FQDN

# Set the vault address environment variable. This is used by the 
# vault cli
export VAULT_ADDR="https://$VAULT_FQDN:8200"

# The vault cert will be self signed. Tell vault to 
# skip verification.
export VAULT_SKIP_VERIFY=true

# If vault has not been initialized, initial it.
# "-check" Don't actually initialize, just check if Vault is
# already initialized. 
set +e
vault init -check 
VAULT_INITIALIZED=$?
set -e

if [[ $VAULT_INITIALIZED == 0 ]]; then
  echo "Vault already initialized"
  exit 0
elif [[ $VAULT_INITIALIZED == 2 ]]; then
  echo "Initializing vault"
  vault init  > $VAULT_KEYS

  # unseal vault. This requires unsealing with 3 keys.
  NUM_KEYS_READ=0
  while read KEY_LINE; do
    key=`echo $KEY_LINE | cut -d' ' -f4`
    vault unseal $key
    NUM_KEYS_READ=`expr $NUM_KEYS_READ + 1`
    if [[ NUM_KEYS_READ -eq 3 ]]; then
      break;
    fi
  done < $VAULT_KEYS

  ROOT_KEY=`grep "Root" $VAULT_KEYS | cut -d' ' -f4`
  vault auth $ROOT_KEY
else
  echo "Vault command error."
  exit $VAULT_INITIALIZED
fi