# Bridge to Cloud Demo with Confluent Platform and Microsoft Azure

In this demo we'll use:
1. Confluent Platform
1. Confluent Cloud
1. Confluent Replicator
1. Microsoft Azure


![Diagram of what's being built with the Bridge to Cloud Demo](docs/resources/images/architecture.png)

## Pre-requisites
1. Install Terraform:
   - for MacOs -> `brew install terraform`
   - Alternatively see [Installation Instructions](https://learn.hashicorp.com/terraform/getting-started/install.html)
1. Install Confluent Cloud CLI:
   - for MacOs -> `curl -L https://cnfl.io/ccloud-cli | sh -s -- -b /<path-to-directory>/bin`i.e./usr/local/bin
   - Alternatively see [Installation Instructions](https://docs.confluent.io/current/cloud/cli/install.html)
1. Install Mac coreutils:
   - for MacOs -> `brew install coreutils`
1. Clone this repository, from now on we'll consider this as base path

## Configure Azure


## Configure the demo
1. create a copy of the file `demo_config.json.example` and rename the copy `demo_config.json`
1. fill the `demo_config.json` file with the required information
1. execute `create_demo_environment.sh`
1. At the end of the script you will receive an output with the IP of your demo. Copy that ip in your browser to continue

## Destroy the environment
1. execute `destroy_demo_environment.sh`