#!/bin/bash

if [[ -z "${GROUP_NAME}" ]]; then
  echo "Group name not set"
  exit 1
fi

if [[ -n "${NAMESPACE}}" ]] && [[ -n "${JOB_NAME}" ]]; then
  MANAGED_BY="${NAMESPACE}_cronjob_${JOB_NAME}"
else
  MANAGED_BY="unknown"
fi

# list all routes and configmaps with console-link.cloud-native-toolkit.dev/enabled label
USERS=$(kubectl get users -o json | jq -c '[.items[].metadata.name] | {"users": .}')

if [[ -z "${USERS}" ]]; then
  echo "No users found"
  exit 0
fi

kubectl get group "${GROUP_NAME}" -o json > /tmp/group.json

GROUP_USERS=$(cat /tmp/group.json | jq -c '.users | {"users": .}')
cat /tmp/group.json | jq --arg MANAGED_BY $MANAGED_BY 'del(.users) | .metadata.labels["app.kubernetes.io/managed-by"] = $MANAGED_BY' > /tmp/group-nousers.json

if [[ "${USERS}" != "${GROUP_USERS}" ]]; then
  echo "Reconciling users to group"
  echo "${USERS}" | jq -s '.[0] * .[1]' /tmp/group-nousers.json - | kubectl apply -f -
fi
