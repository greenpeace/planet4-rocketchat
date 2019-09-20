#!/usr/bin/env bash
# shellcheck disable=2016
set -exuo pipefail

function finish() {
  kubectl -n "${NAMESPACE}" exec -ti "$pod"  -- sh -c 'rm -fr /tmp/rocketchat-db-backup.gz'
}

pod=$(kubectl get pods --namespace "${NAMESPACE}" \
  --sort-by=.metadata.creationTimestamp \
  --field-selector=status.phase=Running \
  -l "release=${HELM_RELEASE},app=mongodb,component=primary" \
  -o jsonpath="{.items[-1:].metadata.name}")

[ -z "$pod" ] && echo "ERROR: No mongodb pod found" && exit 1

trap finish EXIT

kubectl -n "${NAMESPACE}" exec -ti "$pod"  -- sh -c 'mongodump --oplog --gzip --archive=/tmp/rocketchat-db-backup.gz -u $MONGODB_PRIMARY_ROOT_USER -p $MONGODB_ROOT_PASSWORD'

kubectl -n "${NAMESPACE}" cp "$pod":/tmp/rocketchat-db-backup.gz .

gsutil cp rocketchat-db-backup.gz "gs://$BACKUP_BUCKET"
