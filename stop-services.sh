#!/bin/bash

#Shutdown Spark
cd $SPARK_HOME
./sbin/stop-all.sh
sleep 5

#Shutdown Hbase
cd $HBASE_HOME
./bin/stop-hbase.sh
sleep 5

#Shutdown ElasticSearch
cd $ELASTICSEARCH_HOME
./bin/elasticsearch stop
sleep 5

#Shutdown Zookeeper
cd $ZOOKEEPER_HOME
./bin/zkServer.sh stop
sleep 5

#Shutdown Hadoop
cd $HADOOP_HDFS_HOME
./sbin/stop-all.sh
sleep 5
