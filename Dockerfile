FROM ubuntu:14.04

RUN \
    apt-get update \
    && apt-get install -y --no-install-recommends \
      curl \
      supervisor \
      nano \
      openssh-server \
      net-tools \
      iputils-ping \
      telnet \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# install all to /opt/*
ENV OPT_DIR /opt

#Create new user
#RUN useradd -ms /bin/bash formcept

# Java
ENV JAVA_HOME /opt/jdk
ENV PATH $PATH:$JAVA_HOME/bin
RUN cd $OPT_DIR \
    && curl -SL -k "http://download.oracle.com/otn-pub/java/jdk/8u66-b17/jdk-8u66-linux-x64.tar.gz" -b "oraclelicense=a" \
    |  tar xz \
    && ln -s /opt/jdk1.8.0_66 /opt/jdk \
    && rm -f /opt/jdk/*src.zip \
    && echo '' >> /etc/profile \
    && echo '# JDK' >> /etc/profile \
    && echo "export JAVA_HOME=$JAVA_HOME" >> /etc/profile \
    && echo 'export PATH="$PATH:$JAVA_HOME/bin"' >> /etc/profile \
    && echo '' >> /etc/profile

# SSH keygen
RUN cd /root && ssh-keygen -t dsa -P '' -f "/root/.ssh/id_dsa" \
    && cat /root/.ssh/id_dsa.pub >> /root/.ssh/authorized_keys \
    && chmod 644 /root/.ssh/authorized_keys 

# Daemon supervisord
RUN mkdir -p /var/log/supervisor
ADD conf/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Daemon SSH 
RUN mkdir /var/run/sshd \
    && sed -i 's/without-password/yes/g' /etc/ssh/sshd_config \
    && sed -i 's/UsePAM yes/UsePAM no/g' /etc/ssh/sshd_config \
    && echo '    StrictHostKeyChecking no' >> /etc/ssh/ssh_config \
    && echo 'SSHD: ALL' >> /etc/hosts.allow

# Root password
RUN echo 'root:mecbot' | chpasswd

#Port
#HDFS: 50070, HBase: 60010, Spark master WEBUI PORT:8080, Spark URI Port: 7077, Elasticsearch: 9200, Spark Workers: 4040-4060
EXPOSE 22 50070 60010 9200 4040-4060 8080 7077

# Hadoop
ENV HADOOP_URL http://www.eu.apache.org/dist/hadoop/common
ENV HADOOP_VERSION 2.7.1
RUN cd $OPT_DIR \
    && curl -SL -k "$HADOOP_URL/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz" \
    |  tar xz \
    && ln -s /opt/hadoop-$HADOOP_VERSION /opt/hadoop \
    && rm -Rf /opt/hadoop/share/doc

ENV HADOOP_PREFIX $OPT_DIR/hadoop
ENV PATH $PATH:$HADOOP_PREFIX/bin:$HADOOP_PREFIX/sbin
ENV HADOOP_MAPRED_HOME $HADOOP_PREFIX
ENV HADOOP_COMMON_HOME $HADOOP_PREFIX
ENV HADOOP_HDFS_HOME $HADOOP_PREFIX
ENV YARN_HOME $HADOOP_PREFIX
RUN echo '# Hadoop' >> /etc/profile \
    && echo "export HADOOP_PREFIX=$HADOOP_PREFIX" >> /etc/profile \
    && echo 'export PATH=$PATH:$HADOOP_PREFIX/bin:$HADOOP_PREFIX/sbin' >> /etc/profile \
    && echo 'export HADOOP_MAPRED_HOME=$HADOOP_PREFIX' >> /etc/profile \
    && echo 'export HADOOP_COMMON_HOME=$HADOOP_PREFIX' >> /etc/profile \
    && echo 'export HADOOP_HDFS_HOME=$HADOOP_PREFIX' >> /etc/profile \
    && echo 'export YARN_HOME=$HADOOP_PREFIX' >> /etc/profile

RUN echo "export JAVA_HOME=/opt/jdk" >> /opt/hadoop/etc/hadoop/hadoop-env.sh
COPY hdfs/core-site.xml /opt/hadoop/etc/hadoop/
COPY hdfs/slaves /opt/hadoop/etc/hadoop/
COPY hdfs/hdfs-site.xml /opt/hadoop/etc/hadoop/
COPY hdfs/mapred-site.xml /opt/hadoop/etc/hadoop/

#Namenode and Datanode directories for HDFS
RUN mkdir -p /root/hadoop_store/hdfs/namenode
RUN mkdir -p /root/hadoop_store/hdfs/datanode

#ZooKeeper
ENV ZOOKEEPER_VERSION 3.4.8
RUN cd $OPT_DIR \
    && curl -SL -k "http://mirror.fibergrid.in/apache/zookeeper/zookeeper-3.4.8/zookeeper-3.4.8.tar.gz" \
    | tar xz \
    && ln -s /opt/zookeeper-$ZOOKEEPER_VERSION /opt/zookeeper

ENV ZOOKEEPER_PREFIX $OPT_DIR/zookeeper
ENV ZOOKEEPER_HOME $ZOOKEEPER_PREFIX
RUN cp $ZOOKEEPER_PREFIX/conf/zoo_sample.cfg $ZOOKEEPER_PREFIX/conf/zoo.cfg


# Spark
ENV SPARK_HOME /opt/spark
RUN cd $OPT_DIR \
    && curl -SL -k "http://d3kbcqa49mib13.cloudfront.net/spark-1.5.2-bin-hadoop2.6.tgz" \
    | tar xz \
    && rm -f spark-1.5.2-bin-hadoop2.6.tgz \
    && ln -s spark-1.5.2-bin-hadoop2.6 spark \
    && echo '' >> /etc/profile \
    && echo '# SPARK' >> /etc/profile \
    && echo "export SPARK_HOME=$SPARK_HOME" >> /etc/profile \
    && echo 'export PATH="$PATH:$SPARK_HOME/bin"' >> /etc/profile \
    && echo '' >> /etc/profile

#Spark config files
RUN cd $SPARK_HOME/conf \
    && cp spark-env.sh.template spark-env.sh \
    && echo "JAVA_HOME=/opt/jdk" >> spark-env.sh \
    && echo "SPARK_MASTER_WEBUI_PORT=8080" >> spark-env.sh \
    && echo "SPARK_WORKER_INSTANCES=1" >> spark-env.sh \
    && echo "SPARK_WORKER_CORES=4" >> spark-env.sh \
    && echo "SPARK_WORKER_MEMORY=2g" >> spark-env.sh

#Elasticsearch
ENV ELASTICSEARCH_VERSION 1.7.5
RUN cd $OPT_DIR \
    && curl -SL -k "https://download.elastic.co/elasticsearch/elasticsearch/elasticsearch-1.7.5.tar.gz" \
    | tar xz \
    && ln -s /opt/elasticsearch-$ELASTICSEARCH_VERSION /opt/elasticsearch

ENV ES_HEAP_SIZE=256M
ENV ELASTICSEARCH_PREFIX $OPT_DIR/elasticsearch
ENV PATH $PATH:$ELASTICSEARCH_PREFIX/bin
ENV ELASTICSEARCH_HOME $ELASTICSEARCH_PREFIX

#HBase
ENV HBASE_URL  https://archive.apache.org/dist/hbase/1.1.1/
ENV HBASE_VERSION 1.1.1
RUN cd $OPT_DIR \
    && curl -SL -k "https://archive.apache.org/dist/hbase/1.1.1/hbase-1.1.1-bin.tar.gz" \
    | tar xz \
    && ln -s /opt/hbase-$HBASE_VERSION /opt/hbase
  
ENV HBASE_PREFIX $OPT_DIR/hbase
ENV PATH $PATH:$HBASE_PREFIX/bin
ENV HBASE_HOME $HBASE_PREFIX
RUN echo "export JAVA_HOME=/opt/jdk" >> /opt/hbase/conf/hbase-env.sh
COPY hbase-site.xml /opt/hbase/conf/
COPY hbase-env.sh /opt/hbase/conf/

COPY start-services.sh /
COPY stop-services.sh /


#Adding spark to rc.local to run on boot
#RUN echo > /etc/rc.local
#RUN echo "#!/bin/sh" > /etc/rc.local
#RUN echo "nohup sleep 5 && cd $SPARK_HOME && sbin/start-all.sh & " >> /etc/rc.local
#RUN echo "/bin/sh sbin/start-all.sh & " >> /etc/rc.local
#RUN echo "/start-spark.sh" >> /etc/rc.local
#RUN echo "exit 0" >> /etc/rc.local
  
# Daemon
CMD ["/usr/bin/supervisord"]
