#!/bin/bash

CMD="kubeaudit"
pushd $(dirname $0) > /dev/null
# check if we have rg installed, if not, we install it
if ! command -v $CMD &> /dev/null
then
    # check if we already have it unpacked
    if [ -f ./bins/$CMD ]; then
      BIN=$(realpath ./bins/$CMD)
    else
      echo "$CMD could not be found, installing it via tarball at ./bins/$CMD.tar.gz"
      tar -xzf ./bins/$CMD.tar.gz -C ./bins
      BIN=$(realpath ./bins/$CMD)
    fi
else
    BIN=$(command -v $CMD)
fi
echo "Using kubeaudit at $BIN"
CONFIG=${1:-none}
# find config at $HOME/.kube/config - if not found quit and ask user to provide it
if [ $CONFIG == "none" ] && [ -f $HOME/.kube/config ]; then
  CONFIG=$HOME/.kube/config
elif [ $CONFIG == "none" ] && [ ! -f $HOME/.kube/config ]; then
  echo "No config provided and no config found at $HOME/.kube/config"
  exit 1
fi

$BIN all --kubeconfig $CONFIG $(kubectl config current-context)
popd > /dev/null
