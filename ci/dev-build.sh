#!/bin/bash
set -e
set -u
set -x

# This script is called by `make dev-build`
export VERSION="dev-$(date +%s)"
export NAMESPACE="development"

# find everything with a development.nomad file
declare -a targets=($(
    ls */*.development.nomad | while read; do
        echo ${REPLY%/*} 
    done | sort -u
))

# run infrastructure
nomad run nomad/fabio_development.nomad
nomad run nomad/linkerd_development.nomad

## now loop through the above array
for target in "${targets[@]}"
do
    # Remove slashes from service
    service=$(echo $target | sed 's/\///g')
    nomad_file="$service.development.nomad"
    export service
    export nomad_file
    # Run the build
    bazel run //$target:docker
    # Tag so we can track the deploy in Kubernetes
    # (bazel converts slash to an underscore)
    docker tag bazel/$(echo $target):docker localhost:5000/$service:latest
    docker push localhost:5000/$service:latest
    # Deploy service to Nomad
    bash ./ci/deploy-service.sh
done