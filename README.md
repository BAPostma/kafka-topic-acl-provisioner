# Kafka topic provisioning tool
This script creates all required Kafka topics and sets their ACLs accordingly. It can be run by specifying parameters for the Kafka config file, cluster, User CN and the environment-prefix that is to be placed in front of topic names.  

__This script has been tested with the AWS MSK deployment of Kafka.__  

## Prerequisites
Note that the script assumes that the command line tools `kafka-topics.sh` and `kafka-acls.sh` are available on the `$PATH`.  

Ensure you've made changes to the `kafka-client.properties` file, to point to your local JKS files and set the passwords for those credential stores correctly.  
**Do not commit these files back in to Git**.

## Usage
Create a CSV file with the following structure. **Note that the environment name will be prefixed through a command-line variable.**

```csv
Name,IsProducer,IsConsumer
test-topic,true,false
```

### Run the script as follows:
```
~$ ./provision-kafka-topics.sh
Usage: ./provision-kafka-topics.sh <client.properties file> <cluster:port> <user CN> <envrionment prefix> [topic-configuration.csv]
```