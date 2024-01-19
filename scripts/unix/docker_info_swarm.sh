#!/bin/bash

# if we get an error, don't exit
set +e

SWARM_IDS=$(docker node ls -q)
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export PATH=$PATH:$DIR/bins/

if [ -z "$SWARM_IDS" -o "$SWARM_IDS" == " " ]; then
    echo "No docker swarm nodes exist"
    exit 0
fi

for ID in $SWARM_IDS
do
  ROLE=$(docker node inspect $ID | jq -r '.[0].Spec.Role')
  HOSTNAME=$(docker node inspect $ID | jq -r '.[0].Description.Hostname')
  STATUS=$(docker node inspect $ID | jq -r '.[0].Status.State')
  ADDRESS=$(docker node inspect $ID | jq -r '.[0].Status.Addr')
  PLUGINS=$(docker node inspect $ID | jq -r '.[].Description.Engine.Plugins' | grep Name | cut -d '"' -f4 | xargs)
  SERVICE_IDS=$(docker node ps -q $ID)
  echo "##################### Swarm Node Info: $HOSTNAME #####################"
  echo "- Node ID: $ID"
  echo "- Role: $ROLE"
  echo "- Status: $STATUS"
  echo "- Address: $ADDRESS"
  echo "- Plugins: $PLUGINS"
  if [ -z "$SERVICE_IDS" -o "$SERVICE_IDS" == " " ]; then
    echo "*** No services running on $HOSTNAME ***"
  else
    function inspect_ids() {
      echo "*** SERVICES RUNNING ***"
      for ID in $1
      do
        SERVICE_ID=$(docker inspect $ID | jq -r '.[0].ServiceID')
        NAME=$(docker service inspect $SERVICE_ID | jq -r '.[0].Spec.Name')
        IMAGE=$(docker inspect $SERVICE_ID | jq -r '.[0].Spec.TaskTemplate.ContainerSpec.Image')
        DNS=$(docker inspect $SERVICE_ID | jq -r '.[0].Spec.TaskTemplate.ContainerSpec.DNSConfig')
        PS=$(docker service ps $SERVICE_ID)
        echo "--------- Service Info: $NAME ---------"
        echo "- Task ID: $ID"
        echo "- Service ID: $SERVICE_ID"
        echo "- Image: $IMAGE"
        echo "- DNS: $DNS"
        echo "- PS:"
        echo "$PS"
      done
    }
    SERVICE_INFO=$(inspect_ids $SERVICE_IDS)
    # add two spaces to the beginning of each line
    SERVICE_INFO=$(echo "$SERVICE_INFO" | sed 's/^/  /')
    echo "$SERVICE_INFO"
  fi
done;

