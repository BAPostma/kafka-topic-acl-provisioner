#!/bin/bash

# Script arguments
kafkaConfigFile=${1:-"./kafka-client.properties"}
cluster=${2:-"localhost:9092"}
userCanonicalName=${3:-"ip-127-0-0-1.eu-west-2.compute.internal"}
targetEnv=${4:-"local"}
topicsFile=${5:-"topic-configuration.csv"}

# Target environment configuration
partitionCount=4
replicationFactor=2

# Argument validation 
# - argument count
if [ "$#" -lt 4 ]
then
    echo "Usage:" $0 "<client.properties file> <cluster:port> <user CN> <envrionment prefix> [topic-configuration.csv]"
    exit
fi

# - csv config file exists
if [ ! -f $topicsFile ]
then
    echo "Provided topics CSV file ("$topicsFile") cannot be found"
    exit
fi

# Create the topics
create_topic()
{
    topicName=$targetEnv.$1

    echo "Creating topic:" $topicName
    kafka-topics.sh --create --bootstrap-server $cluster --replication-factor $replicationFactor --partitions $partitionCount --topic $topicName --config retention.ms=-1 --command-config $kafkaConfigFile;
}

# Create the ACLs
create_acl()
{
    topicName=$targetEnv.$1
    isProducer=$2
    isConsumer=$3

    if [ $isProducer == true ] && [ $isConsumer == false ]
    then
        echo "Setting" $topicName "ACL to producer"
        kafka-acls.sh --add --bootstrap-server $cluster --allow-principal User:CN=$userCanonicalName --topic $topicName --producer --command-config $kafkaConfigFile;
    
    elif [ $isConsumer == true ] && [ $isProducer == false ]
    then
        echo "Setting" $topicName "ACL to consumer"
        kafka-acls.sh --add --bootstrap-server $cluster --allow-principal User:CN=$userCanonicalName --topic $topicName --consumer --group * --command-config $kafkaConfigFile;
    
    elif [ $isProducer == true ] && [ $isConsumer == true ]
    then
        echo "Setting" $topicName "ACL to producer and consumer"
        kafka-acls.sh --add --bootstrap-server $cluster --allow-principal User:CN=$userCanonicalName --topic $topicName --producer --consumer --group * --command-config $kafkaConfigFile;
    
    else
        echo "Not setting ACL for" $topicName". It is likely to be inaccessible"
    fi
}



echo "Going to create topic(s) from" $topicsFile "for target environment" $targetEnv "on cluster" $cluster "with" $partitionCount "partitions, replicated" $replicationFactor "times."

# Create all the topics & acls by reading over the CSV file
while IFS=, read -r Name IsProducer IsConsumer || [ -n "$Name" ]
do
    if [ "$Name" == "Name" ]
    then # Skip CSV header row
        continue
    fi

    create_topic $Name
    create_acl $Name $IsProducer $IsConsumer

done < $topicsFile

echo "All operations have completed"
