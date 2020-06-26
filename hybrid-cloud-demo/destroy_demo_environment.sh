#!/bin/bash
set -e

PRJ_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
UTILS_DIR="${PRJ_DIR}/utils"
TFS_PATH="${PRJ_DIR}/terraform"
TMP_FOLDER="$PRJ_DIR/tmp"
ENV_FILEPATH="${TMP_FOLDER}/envs.created"
STACK_FILEPATH="${TMP_FOLDER}/stack.created"
CFG_FILE="${PRJ_DIR}/demo_config.json"

function destroy_ccloud_env(){
  # Destroy Confluent Cloud Environment
  if [ ! -f "$ENV_FILEPATH" ]; then
      echo "No environment to drop: $ENV_FILEPATH does not exist"
      return
  fi

  source $ENV_FILEPATH

  for ACCOUNT in $(jq '.ccloud.credentials | keys[]' $CFG_FILE -r); do 
      
    my_creds=$(jq  ".ccloud.credentials.${ACCOUNT}" $CFG_FILE)
    URL=$(echo "$my_creds" | jq '.url' -r)
    USERNAME=$(echo "$my_creds" | jq '.username' -r)
    PASSWORD=$(echo "$my_creds" | jq '.password' -r)

    ccloud logout 
    ccloud::login_ccloud_cli $URL $USERNAME $PASSWORD

    local ENV_VARIABLE_NAME="${ACCOUNT}_ENVIRONMENT"
    local ENVIRONMENT=${!ENV_VARIABLE_NAME}
    local SERVICE_ACCOUNT_ID_VARIABLE_NAME="${ACCOUNT}_SERVICE_ACCOUNT_ID"
    local SERVICE_ACCOUNT_ID=${!SERVICE_ACCOUNT_ID_VARIABLE_NAME}
    local METRICS_API_KEY_VARIABLE_NAME="${ACCOUNT}_CCLOUD_METRICS_API_KEY"
    local CCLOUD_METRICS_API_KEY=${!METRICS_API_KEY_VARIABLE_NAME}

    ccloud service-account delete $SERVICE_ACCOUNT_ID 

    echo "Delete Confluent Environment Id: $ENVIRONMENT"
    ccloud environment delete $ENVIRONMENT 

    ccloud api-key delete $CCLOUD_METRICS_API_KEY

   

    echo "-----------"
      
  done

  rm -f "${ENV_FILEPATH}"
  rm -f "${STACK_FILEPATH}"
}

function destroy_infrastructure (){

    cd $WS_REPO_FOLDER
    ./workshop-destroy.py --dir $TMP_FOLDER

    rm $TMP_FOLDER/workshop.yaml

    cd $TFS_PATH
    terraform destroy --auto-approve

    rm -f "${TFS_PATH}/config.auto.tfvars"

}

function end_demo {
  
  # Source library
  source $UTILS_DIR/demo_helper.sh 
  
  check_jq || exit 1

  # Destroy Confluent Cloud Environment
  destroy_ccloud_env

  get_hybrid_workshop_repo
  destroy_infrastructure  
 
  rm -f "${TMP_FOLDER}/cluster_1.client.config"

}

end_demo 2>&1 | tee -a zz_demo_destruction.log