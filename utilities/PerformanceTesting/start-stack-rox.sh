#!/usr/bin/env bash
set -eou pipefail

name=$1
artifacts_dir=${2:-/tmp/artifacts}
collector_image_registry=${3:-quay.io/rhacs-eng}
collector_image_tag=${4:-3.7.3}

DIR="$(cd "$(dirname "$0")" && pwd)"

"$DIR"/wait-for-cluster.sh "$name"
"$DIR"/get-artifacts-dir.sh "$name" "$artifacts_dir"
export KUBECONFIG="$artifacts_dir"/kubeconfig
"$DIR"/start-central-and-scanner.sh "$artifacts_dir"
"$DIR"/wait-for-pods.sh "$artifacts_dir"
"$DIR"/grab-bundle.sh "$artifacts_dir"
"$DIR"/start-secured-cluster.sh "$artifacts_dir" "$collector_image_registry" "$collector_image_tag"
#kubectl set env ds/collector ROX_PROCESSES_LISTENING_ON_PORT=true --namespace stackrox
#kubectl set env deployment/central ROX_PROCESSES_LISTENING_ON_PORT=true --namespace stackrox
#kubectl set env deployment/sensor ROX_PROCESSES_LISTENING_ON_PORT=true --namespace stackrox
"$DIR"/turn-on-monitoring.sh "$artifacts_dir"
