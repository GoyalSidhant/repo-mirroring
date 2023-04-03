#!/bin/bash

set -eux

echo "Script Start"
DEST_PROTO="$(echo $DEST_REPO | sed -nr 's,^(.*://).*,\1,p')"
# Remove the protocol from the URL.
DEST_URL="$(echo ${DEST_REPO/$DEST_PROTO/})"
# Extract the user (includes trailing "@").
DEST_USER="$(echo $DEST_URL | sed -nr 's,^(.*@).*,\1,p')"
DEST_USER=${DEST_USER:-git@}
# Remove the user from the URL.
DEST_URL="$(echo ${DEST_URL/$DEST_USER/})"
# Extract the port (includes leading ":").
DEST_PORT="$(echo $DEST_URL | sed -nr 's,.*:([0-9]+).*,\1,p')"
DEST_PORT=${DEST_PORT:-22}
# Remove the port from the URL.
DEST_URL="$(echo ${DEST_URL/$DEST_PORT/})"
# Extract the path (includes leading "/" or ":").
DEST_PATH="$(echo $DEST_URL | sed -nr 's,[^/:]*([/:].*),\1,p')"
# Remove the path from the URL.
DEST_HOST="$(echo ${DEST_URL/$DEST_PATH/})"



# Extract the protocol (includes trailing "://").
SRC_PROTO="$(echo $SRC_REPO | sed -nr 's,^(.*://).*,\1,p')"
# Remove the protocol from the URL.
SRC_URL="$(echo ${SRC_REPO/$SRC_PROTO/})"
# Extract the user (includes trailing "@").
SRC_USER="$(echo $SRC_URL | sed -nr 's,^(.*@).*,\1,p')"
SRC_USER=${SRC_USER:-git@}
# Remove the user from the URL.
SRC_URL="$(echo ${SRC_URL/$SRC_USER/})"
# Extract the port (includes leading ":").
SRC_PORT="$(echo $SRC_URL | sed -nr 's,.*:([0-9]+).*,\1,p')"
SRC_PORT=${SRC_PORT:-22}
# Remove the port from the URL.
SRC_URL="$(echo ${SRC_URL/$SRC_PORT/})"
# Extract the path (includes leading "/" or ":").
SRC_PATH="$(echo $SRC_URL | sed -nr 's,[^/:]*([/:].*),\1,p')"
# Remove the path from the URL.
SRC_HOST="$(echo ${SRC_URL/$SRC_PATH/})"
# name that can be used for the folder name e.g vendor/repo
SRC_PROJECT="$(echo $SRC_PATH | sed -nr 's,:(.*)\.git,\1,p')"


if [[ ! -d ~/.ssh ]] ; then 
  printf "\nConfiguring ssh client to use deploy keys\n"
  mkdir -p ~/.ssh
  chmod 700 ~/.ssh
  eval `ssh-agent -s`
  echo "$SRC_DEPLOY_KEY" | base64 -d > ~/.ssh/id_rsa
  chmod 600 ~/.ssh/id_rsa
  ssh-add -k  ~/.ssh/id_rsa

  echo "$DEST_USER$DEST_HOST"
  echo "$DEST_REPO"
  printf "\n\nChecking access to $SRC_HOST\n"
  ssh -o StrictHostKeyChecking=no -T "$SRC_USER$SRC_HOST" -p "$SRC_PORT" || 'true'
  printf "\n\nChecking access to $DEST_HOST\n"
  ssh -o StrictHostKeyChecking=no -T "$DEST_USER$DEST_HOST" -p "$DEST_PORT" || 'true'
fi 

if [[ ! -d /storage/"$SRC_PROJECT" ]]; then
  printf "\nCloning $SRC_REPO\n"
  cd /storage
  git clone --bare "$SRC_REPO" "$SRC_PROJECT"
  cd /storage/"$SRC_PROJECT"
  git remote add dest ssh://"$DEST_REPO"
fi

cd /storage/"$SRC_PROJECT"

printf "\Triggering sync\n"
git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
git fetch --prune
git remote set-head origin -d
git branch -a || 'true'
git remote  set-url  dest ssh://"$DEST_REPO"
git push --prune dest +refs/remotes/origin/*:refs/heads/* +refs/tags/*:refs/tags/*