#!/bin/bash
scriptDir=$(dirname $0)

############
### MAIN ###
############

function createProjectAndServiceAccount {
    YOUR_PROJECT_NAME=$1
    SA_NAME=$2
    echo ###############################
    echo # Create project if not exist #
    echo ###############################
    PROJECT_EXIST=$(oc get ns $YOUR_PROJECT_NAME 2> /dev/null)
    if [[ -z  $PROJECT_EXIST ]]
    then
        echo "Create $YOUR_PROJECT_NAME"
        oc new-project ${YOUR_PROJECT_NAME}
    fi
    oc project ${YOUR_PROJECT_NAME}
    if [[ -z $(oc get sa | grep $SA_NAME) ]]
    then
      oc apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: $SA_NAME
EOF
      oc adm policy add-scc-to-user anyuid -z $SA_NAME -n ${YOUR_PROJECT_NAME}
    else
      echo "Found service account $SA_NAME"
    fi
}