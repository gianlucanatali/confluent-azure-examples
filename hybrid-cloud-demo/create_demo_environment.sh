#!/bin/bash
set -e

PRJ_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
UTILS_DIR="${PRJ_DIR}/utils"
TMP_FOLDER="${PRJ_DIR}/tmp"
TFS_PATH="${PRJ_DIR}/terraform"
STATE_FILE_PATH="${TFS_PATH}/terraform.tfstate"
WS_STATE_FILE_PATH="${TMP_FOLDER}/.terraform_staging/terraform.tfstate"
STACK_FILEPATH="${TMP_FOLDER}/stack.created"
ENV_FILEPATH="${TMP_FOLDER}/envs.created"
CFG_FILE="${PRJ_DIR}/demo_config.json"

#http://patorjk.com/software/taag/#p=display&f=ANSI%20Shadow&t=hybrid%20cloud%20%0A%20%20%20%20%20%20demo%0A%20Confluent%20%0A%20%20%20Azure
function welcome_screen {
    local DEMO_IP=$VM_HOST
    local DEMO_SITE="http://${DEMO_IP}"
    local C3_LINK="http://${DEMO_IP}:9021"
    local STITCH_APP_LINK="https://${STITCH_APP_ID}.mongodbstitch.com"

    echo "                                                                                           ";
    echo "██╗  ██╗██╗   ██╗██████╗ ██████╗ ██╗██████╗      ██████╗██╗      ██████╗ ██╗   ██╗██████╗  ";  
    echo "██║  ██║╚██╗ ██╔╝██╔══██╗██╔══██╗██║██╔══██╗    ██╔════╝██║     ██╔═══██╗██║   ██║██╔══██╗ ";  
    echo "███████║ ╚████╔╝ ██████╔╝██████╔╝██║██║  ██║    ██║     ██║     ██║   ██║██║   ██║██║  ██║ ";  
    echo "██╔══██║  ╚██╔╝  ██╔══██╗██╔══██╗██║██║  ██║    ██║     ██║     ██║   ██║██║   ██║██║  ██║ ";  
    echo "██║  ██║   ██║   ██████╔╝██║  ██║██║██████╔╝    ╚██████╗███████╗╚██████╔╝╚██████╔╝██████╔╝ ";  
    echo "╚═╝  ╚═╝   ╚═╝   ╚═════╝ ╚═╝  ╚═╝╚═╝╚═════╝      ╚═════╝╚══════╝ ╚═════╝  ╚═════╝ ╚═════╝  ";  
    echo "                                                                                           ";  
    echo "                        ██████╗ ███████╗███╗   ███╗ ██████╗                                ";  
    echo "                        ██╔══██╗██╔════╝████╗ ████║██╔═══██╗                               ";  
    echo "                        ██║  ██║█████╗  ██╔████╔██║██║   ██║                               ";  
    echo "                        ██║  ██║██╔══╝  ██║╚██╔╝██║██║   ██║                               ";  
    echo "                        ██████╔╝███████╗██║ ╚═╝ ██║╚██████╔╝                               ";  
    echo "                        ╚═════╝ ╚══════╝╚═╝     ╚═╝ ╚═════╝                                ";  
    echo "                                                                                           ";  
    echo "     ██████╗ ██████╗ ███╗   ██╗███████╗██╗     ██╗   ██╗███████╗███╗   ██╗████████╗        ";  
    echo "    ██╔════╝██╔═══██╗████╗  ██║██╔════╝██║     ██║   ██║██╔════╝████╗  ██║╚══██╔══╝        ";  
    echo "    ██║     ██║   ██║██╔██╗ ██║█████╗  ██║     ██║   ██║█████╗  ██╔██╗ ██║   ██║           ";  
    echo "    ██║     ██║   ██║██║╚██╗██║██╔══╝  ██║     ██║   ██║██╔══╝  ██║╚██╗██║   ██║           ";  
    echo "    ╚██████╗╚██████╔╝██║ ╚████║██║     ███████╗╚██████╔╝███████╗██║ ╚████║   ██║           ";  
    echo "     ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝     ╚══════╝ ╚═════╝ ╚══════╝╚═╝  ╚═══╝   ╚═╝           ";  
    echo "                                                                                           ";  
    echo "                        █████╗ ███████╗██╗   ██╗██████╗ ███████╗                           ";  
    echo "                       ██╔══██╗╚══███╔╝██║   ██║██╔══██╗██╔════╝                           ";  
    echo "                       ███████║  ███╔╝ ██║   ██║██████╔╝█████╗                             ";  
    echo "                       ██╔══██║ ███╔╝  ██║   ██║██╔══██╗██╔══╝                             ";  
    echo "                       ██║  ██║███████╗╚██████╔╝██║  ██║███████╗                           ";  
    echo "                       ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝                           ";  
    echo "                                                                                           ";  
    echo "                                                                                           ";
    echo "*******************************************************************************************";
    echo " ";
    echo " ";
    echo "Handy links: "
    echo " - Demo main page: ${DEMO_SITE} ";
    echo " - Confluent Control Center: ${C3_LINK}";
}

function create_tfvars_file {
    cd $PRJ_DIR
    TERRAFORM_CONFIG="$TFS_PATH/config.auto.tfvars"
    echo -e "\n# Create a local configuration file $TERRAFORM_CONFIG with the terraform variables"
    cat <<EOF > $TERRAFORM_CONFIG
ssh_user                = "dc01"
ssh_password            = "$VM_PASSWORD"
vm_host                 = "$VM_HOST"
EOF

}

function init_vars_from_config() {

    if [ ! -f "$CFG_FILE" ]; then
        echo "You are missing the main configuration file! $CFG_FILE does not exist"
        exit 1
    fi

    DEMO_TYPE=$(jq '.demo_type' $CFG_FILE -r)

    if [[ -z "$DEMO_TYPE" ]]; then
        echo "You need to specify a demo Type!"
        exit 1
    fi

    DEMO_NAME=$(jq '.demo_name' $CFG_FILE -r)
    MONGODBATLAS_PUBLIC_KEY=$(jq '.mongodbatlas.public_key' $CFG_FILE -r)
    MONGODBATLAS_PRIVATE_KEY=$(jq '.mongodbatlas.private_key' $CFG_FILE -r)
    MONGODBATLAS_PROJECT_ID=$(jq '.mongodbatlas.project_id' $CFG_FILE -r)
    MONGODBATLAS_PROVIDER_NAME=$(jq '.mongodbatlas.cloud_provider.name' $CFG_FILE -r)
    MONGODBATLAS_PROVIDER_INSTANCE_SIZE_NAME=$(jq '.mongodbatlas.instance_size_name' $CFG_FILE -r)
    MONGODBATLAS_PROVIDER_REGION_NAME=$(jq '.mongodbatlas.cloud_provider.region_name' $CFG_FILE -r)
    MONGODBATLAS_DISK_SIZE_GB=$(jq '.mongodbatlas.disk_size_gb' $CFG_FILE -r)
    MONGODBATLAS_MONGO_DB_MAJOR_VERSION=$(jq '.mongodbatlas.mongodb.major_version' $CFG_FILE -r)
    MONGODBATLAS_DBUSER_USERNAME=$(jq '.mongodbatlas.mongodb.dbuser_username' $CFG_FILE -r)
    MONGODBATLAS_DBUSER_PASSWORD=$(jq '.mongodbatlas.mongodb.dbuser_password' $CFG_FILE -r)
    SR_CLOUD_PROVIDER=$(jq '.ccloud.schema_registry.cloud_provider' $CFG_FILE -r)
    SR_CLOUD_GEO=$(jq '.ccloud.schema_registry.cloud_geo' $CFG_FILE -r)

    case $DEMO_TYPE in
     azure)
        AZURE_SUBSCRIPTION_ID=$(jq '.azure.subscription_id' $CFG_FILE -r)
        AZURE_CLIENT_ID=$(jq '.azure.client_id' $CFG_FILE -r)
        AZURE_CLIENT_SECRET=$(jq '.azure.client_secret' $CFG_FILE -r)
        AZURE_TENANT_ID=$(jq '.azure.tenant_id' $CFG_FILE -r)
        AZURE_LOCATION=$(jq '.azure.location' $CFG_FILE -r)
        VM_USERNAME=$(jq '.azure.vm.username' $CFG_FILE -r)
        VM_PASSWORD=$(jq '.azure.vm.password' $CFG_FILE -r)
        VM_TYPE=$(jq '.azure.vm.type' $CFG_FILE -r)
        ;; 
     *)
        echo "Use one of the demo_types: azure"
        exit 1
        ;;
    esac

}

function login_to_ccloud_from_config () {
    local ACCOUNT=$1
    my_creds=$(jq  ".ccloud.credentials.${ACCOUNT}" $CFG_FILE)
    URL=$(echo "$my_creds" | jq '.url' -r)
    USERNAME=$(echo "$my_creds" | jq '.username' -r)
    PASSWORD=$(echo "$my_creds" | jq '.password' -r)

    ccloud logout 
    echo "---- Logging to Confluent Cloud with user: $USERNAME"
    ccloud::login_ccloud_cli $URL $USERNAME $PASSWORD
}

function create_cluster_from_config () {
    local PREFIX=$1
    local config=$(jq  ".ccloud.$PREFIX" $CFG_FILE)
    echo "$config"
    local ACCOUNT=$(echo "$config" | jq '.ccloud' -r)
    local CLUSTER_NAME=$(echo "$config" | jq '.name' -r)
    local CLUSTER_CLOUD=$(echo "$config" | jq '.cloud_provider' -r)
    local CLUSTER_REGION=$(echo "$config" | jq '.cloud_region' -r)
    local TOPICS_TO_CREATE=$(echo "$config" | jq '.topics_to_create' -r)
    local CLIENT_CONFIG="$TMP_FOLDER/$PREFIX.client.config"
    
    local enable_ksql=false
    local ENV_VARIABLE_NAME="${ACCOUNT}_ENVIRONMENT"
    local ENVIRONMENT=${!ENV_VARIABLE_NAME}
    local SERVICE_ACCOUNT_ID_VARIABLE_NAME="${ACCOUNT}_SERVICE_ACCOUNT_ID"
    local SERVICE_ACCOUNT_ID=${!SERVICE_ACCOUNT_ID_VARIABLE_NAME}
    local METRICS_API_KEY_VARIABLE_NAME="${ACCOUNT}_CCLOUD_METRICS_API_KEY"
    local CCLOUD_METRICS_API_KEY=${!METRICS_API_KEY_VARIABLE_NAME}
    local METRICS_API_SECRET_VARIABLE_NAME="${ACCOUNT}_CCLOUD_METRICS_API_SECRET"
    local CCLOUD_METRICS_API_SECRET=${!METRICS_API_SECRET_VARIABLE_NAME}
    
    cat <<EOF >> $STACK_FILEPATH
${PREFIX}_CCLOUD_METRICS_API_KEY="${CCLOUD_METRICS_API_KEY}"
${PREFIX}_CCLOUD_METRICS_API_SECRET="${CCLOUD_METRICS_API_SECRET}"
EOF
    

    local KSQL_NAME="${PREFIX}-ksql-$SERVICE_ACCOUNT_ID"

    login_to_ccloud_from_config $ACCOUNT
    ccloud environment use $ENVIRONMENT

    ccloud::create_ccloud_stack

    ccloud::create_acls_all_resources_full_access $SERVICE_ACCOUNT_ID
    ccloud::create_acls_fm_connectors_wildcard $SERVICE_ACCOUNT_ID $CLUSTER

    ccloud::create_topics $CLUSTER 1 "$TOPICS_TO_CREATE"

    ccloud::output_stack_to_file $STACK_FILEPATH "${PREFIX}_"

}

function create_ccloud_resources () {

    local count=$(ls ${TMP_FOLDER}/*.created | wc -l);
    if (( count > 0 )); then
        echo "Confluent Cloud Environment(s) already created, will not recreate"
        return
    fi

    for ACCOUNT in $(jq '.ccloud.credentials | keys[]' $CFG_FILE -r); do 
        
        login_to_ccloud_from_config ${ACCOUNT}
        
        local RANDOM_NUM=$((1 + RANDOM % 1000000))
        #echo "RANDOM_NUM: $RANDOM_NUM"

        local SERVICE_NAME="$DEMO_NAME-$RANDOM_NUM"
        local SERVICE_ACCOUNT_ID=$(ccloud::create_service_account $SERVICE_NAME)
        echo "Creating Confluent Cloud stack for new service account id $SERVICE_ACCOUNT_ID of name $SERVICE_NAME"
        
        # Creating API Key for Cloud resource (Metrics API)
        local METRICS_CREDS=$(ccloud::create_credentials_resource $SERVICE_ACCOUNT_ID cloud)

        local CCLOUD_METRICS_API_KEY=$(echo $METRICS_CREDS | awk -F: '{print $1}')
        local CCLOUD_METRICS_API_SECRET=$(echo $METRICS_CREDS | awk -F: '{print $2}')

        local ENVIRONMENT_NAME=$(jq  ".ccloud.credentials.${ACCOUNT}.environment_name" -r $CFG_FILE)
        local ENVIRONMENT=$(ccloud::create_and_use_environment $ENVIRONMENT_NAME)
        

        cat <<EOF >> $ENV_FILEPATH
${ACCOUNT}_SERVICE_ACCOUNT_ID="${SERVICE_ACCOUNT_ID}"
${ACCOUNT}_ENVIRONMENT="${ENVIRONMENT}"
${ACCOUNT}_CCLOUD_METRICS_API_KEY="${CCLOUD_METRICS_API_KEY}"
${ACCOUNT}_CCLOUD_METRICS_API_SECRET="${CCLOUD_METRICS_API_SECRET}"
EOF
        source ${ENV_FILEPATH}
        echo "-----------"
    done

    create_cluster_from_config cluster_1
    source $STACK_FILEPATH

}



function create_infrastructure (){

    local WORKSHOP_CFG_TEMPLATE="${PRJ_DIR}/templates/ws_configs/workshop-example-${DEMO_TYPE}.yaml"
    cat >$TMP_FOLDER/workshop.yaml <(eval "cat <<EOF
$(<$WORKSHOP_CFG_TEMPLATE)
EOF
")

    cd $WS_REPO_FOLDER
    ./workshop-create.py --dir $TMP_FOLDER

    # Read VM IP from workshop terraform output
    VM_HOST=$(terraform output -json -state=${WS_STATE_FILE_PATH} | jq ".external_ip_addresses.value[0]" -r)
    
    # Initialize demo using terraform
    create_tfvars_file
    cd $TFS_PATH
    terraform init
    terraform apply --auto-approve
}



function start_demo {

    source $UTILS_DIR/demo_helper.sh

    check_jq || exit 1

    init_vars_from_config
    get_hybrid_workshop_repo

    create_ccloud_resources
    source $STACK_FILEPATH

    # Create the Infrastructure
    create_infrastructure

    welcome_screen
}

start_demo 2>&1 | tee -a zz_demo_creation.log


