
#!/bin/bash

DIR_DEMO_HELPER="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

################################################################
# Downloading Utils from https://github.com/confluentinc/examples
#
# (This step will be skipped if the files are already in the utils folder)
################################################################
EXAMPLES_UTILS_URL="https://raw.githubusercontent.com/confluentinc/examples/5.5.0-post/utils"

[ ! -f $DIR_DEMO_HELPER/helper.sh ] && wget $EXAMPLES_UTILS_URL/helper.sh -P $DIR_DEMO_HELPER
[ ! -f $DIR_DEMO_HELPER/ccloud_library.sh ] && wget $EXAMPLES_UTILS_URL/ccloud_library.sh -P $DIR_DEMO_HELPER
[ ! -f $DIR_DEMO_HELPER/config.env ] && wget $EXAMPLES_UTILS_URL/config.env -P $DIR_DEMO_HELPER

# Source library
source $DIR_DEMO_HELPER/helper.sh 
source $DIR_DEMO_HELPER/ccloud_library.sh


function ccloud::create_acls_fm_connectors_wildcard() {
    SERVICE_ACCOUNT_ID=$1
    CLUSTER=$2

    ccloud kafka acl create --allow --service-account $SERVICE_ACCOUNT_ID --operation idempotent-write --cluster-scope --cluster $CLUSTER
    ccloud kafka acl create --allow --service-account $SERVICE_ACCOUNT_ID --operation describe --cluster-scope --cluster $CLUSTER
    ccloud kafka acl create --allow --service-account $SERVICE_ACCOUNT_ID --operation create --cluster-scope --cluster $CLUSTER

    return 0
}

function ccloud::create_topics(){
    CLUSTER=$1
    PARTITIONS=$2
    TOPICS_TO_CREATE=$3
    echo -e "\n# Will create the following topics: $TOPICS_TO_CREATE"
  for TOPIC in $TOPICS_TO_CREATE
  do
        echo -e "\n# Create new Kafka topic $TOPIC"
        echo "ccloud kafka topic create \"$TOPIC\" --partitions $PARTITIONS"
        ccloud kafka topic create "$TOPIC" --cluster $CLUSTER --partitions $PARTITIONS || true
        # In some cases I received an error 500 but the topic is created successfully anyway...
  done
}

# This Function will persist all the relevant info for the created resources in a file
# The format is that of a bash file, so you can just source it in a script
# I saw similar approach that uses the java config file but this is more straightforward and will not need to source that file
# https://github.com/confluentinc/examples/blob/7025c9cd5b80ac4b523f82996d3b3d77b9bca853/ccloud/ccloud-generate-cp-configs.sh#L725
#
# Example Usage
# ccloud::output_stack_to_file $ENV_FILEPATH "${PREFIX}_"
# If you need to export those vars for the system....
# ccloud::output_stack_to_file $ENV_FILEPATH "export "
function ccloud::output_stack_to_file(){
    local ENV_FILEPATH=$1
    local PREFIX=$2
    local API_KEY_SA=$(echo $CLUSTER_CREDS | awk -F: '{print $1}')
    local API_SECRET_SA=$(echo $CLUSTER_CREDS | awk -F: '{print $2}')
    local SR_API_KEY_SA=$(echo $SCHEMA_REGISTRY_CREDS | awk -F: '{print $1}')
    local SR_API_SECRET_SA=$(echo $SCHEMA_REGISTRY_CREDS | awk -F: '{print $2}')

    cat <<EOF >> $ENV_FILEPATH
${PREFIX}SERVICE_ACCOUNT_ID="${SERVICE_ACCOUNT_ID}"
${PREFIX}ENVIRONMENT="${ENVIRONMENT}"
${PREFIX}CLUSTER="${CLUSTER}"
${PREFIX}BOOTSTRAP_SERVERS="${BOOTSTRAP_SERVERS}"
${PREFIX}API_KEY_SA="${API_KEY_SA}"
${PREFIX}API_SECRET_SA="${API_SECRET_SA}"
${PREFIX}SR_ID="${SCHEMA_REGISTRY}"
${PREFIX}SR_ENDPOINT="${SCHEMA_REGISTRY_ENDPOINT}"
${PREFIX}SR_ID="${SCHEMA_REGISTRY}"
${PREFIX}SR_API_KEY_SA="${SR_API_KEY_SA}"
${PREFIX}SR_API_SECRET_SA="${SR_API_SECRET_SA}"
EOF

}

ccloud::wait_for_data_in_topic() {
    local count=0
    while [[ "$count" -le 100 ]];do 
        count=$(timeout 10 ccloud kafka topic consume -b $2 --cluster $1 | wc -l);
        echo "At least $count messages in the topic"
        #timeout 3 ccloud kafka topic consume -b $2 --cluster $1
        sleep 0.1 
    done 
}

function get_hybrid_workshop_repo() {
    local GIT_BRANCH="master"
    local GIT_REPO="tjunderhill/confluent-hybrid-cloud-workshop.git"
    WS_REPO_FOLDER=$DIR_DEMO_HELPER/confluent-hybrid-cloud-workshop
    [[ -d "$WS_REPO_FOLDER" ]] || git clone https://github.com/$GIT_REPO $WS_REPO_FOLDER
    (cd $WS_REPO_FOLDER && git fetch && git checkout ${GIT_BRANCH} && git pull) || {
        echo "ERROR: There seems to be an issue in Downloading $GIT_REPO. Please troubleshoot and try again."
        exit 1
    }

    return 0
}

