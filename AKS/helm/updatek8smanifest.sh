#!/bin/bash

set -x

# Set the repository URL
REPO_URL="https://github.com/krishmint/three-tier-architecture-demo.git"

# Clone the git repository into the /tmp directory
git clone "$REPO_URL" /tmp/temp_repo

# Navigate into the cloned repository directory
cd /tmp/temp_repo

# Make changes to the Kubernetes manifest file(s)
# 
sed -i "s|version:.*|version: $1|g" AKS/helm/values.yaml  ## to chnage the values.yaml file for help t use updated image

sed -i "s|TAG=.*|TAG=$1|g" .env    ## to change the .env file for docker compose


# Add the modified files
git add .

# Commit the changes
git commit -m "Update Kubernetes manifest"

# Push the changes back to the repository
git push

# Cleanup: remove the temporary directory
rm -rf /tmp/temp_repo
