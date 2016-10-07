#!/bin/bash

#Starting Hadoop
cd $HADOOP_HDFS_HOME
hadoop namenode -format
./sbin/start-dfs.sh
sleep 5

#Starting Zookeeper
cd $ZOOKEEPER_HOME
./bin/zkServer.sh start
sleep 5

#Starting ElasticSearch
cd $ELASTICSEARCH_HOME
./bin/elasticsearch -d
sleep 5

#Starting Hbase
cd $HBASE_HOME
./bin/start-hbase.sh
sleep 5

#Starting Spark
cd $SPARK_HOME
./sbin/start-all.sh
sleep 5
