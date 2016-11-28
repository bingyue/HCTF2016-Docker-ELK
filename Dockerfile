# Elasticsearch(Full text search) + Logstash(Logging) + Kibana(Visualization)
# Tips:
# Step 1: Build images
# Change directory where Dockfile exsits and run command:
# 	docker build --tag="hctf-2016" .
# After operation ,it built one image named hctf-2016 (You can run command "docker images" to view your local images)
#
#
# Step 2:  Start a container with image named hctf-2016, so run command :
# 	docker run -d -p 80:80 -p 3333:3333 -p 3334:3334 -p 9200:9200 -p 6379:6379 --name Hctf2016_elk -it hctf-2016 /bin/bash
# Now you started one container named Hctf2016_elk (You can run command "docker ps" to view your containers)
#
#
# Step 3: You need run command "docker exec" to spawns a process inside the container called "Hctf2016_elk" 
# 	docker exec -it Hctf2016_elk /bin/bash
# 
#
# Step 4: To run elk when inside:
#	./start.sh
# Run restart-logstash.sh to restart logstash if you need
# 
# Mention :
# Send test data:
# You can send test data (tcp stream) to elk at port 3333,3334  (You can modify port in the file "logstash.conf") 
# 	echo 'Hello,HCTF2016 ' | nc Server_IP 3333.
# After this ,you can see the logs in Kibana by view the page http://SERVER_IP/index.html#/dashboard/file/logstash.json

# hub.c.163.com/library/ubuntu:14.04 is also recommeded in China
FROM ubuntu:14.04
MAINTAINER HCTF-2016

#Modify source (Aliyun)
RUN echo "deb http://mirrors.aliyun.com/ubuntu/ trusty main restricted universe multiverse\ndeb http://mirrors.aliyun.com/ubuntu/ trusty-security main restricted universe multiverse\ndeb http://mirrors.aliyun.com/ubuntu/ trusty-updates main restricted universe multiverse\ndeb http://mirrors.aliyun.com/ubuntu/ trusty-proposed main restricted universe multiverse\ndeb http://mirrors.aliyun.com/ubuntu/ trusty-backports main restricted universe multiverse\ndeb-src http://mirrors.aliyun.com/ubuntu/ trusty main restricted universe multiverse\ndeb-src http://mirrors.aliyun.com/ubuntu/ trusty-security main restricted universe multiverse\ndeb-src http://mirrors.aliyun.com/ubuntu/ trusty-updates main restricted universe multiverse\ndeb-src http://mirrors.aliyun.com/ubuntu/ trusty-proposed main restricted universe multiverse\ndeb-src http://mirrors.aliyun.com/ubuntu/ trusty-backports main restricted universe multiverse" >> /etc/apt/sources.list

# Initial update
RUN apt-get update

#Install basic tools
RUN apt-get install vim -y

# Install add-apt-repository utility.
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y software-properties-common

# Install Oracle Java 8 (Logstash to be needed)
RUN	apt-key adv --keyserver keyserver.ubuntu.com --recv-keys EEA14886 && \
	DEBIAN_FRONTEND=noninteractive add-apt-repository -y ppa:webupd8team/java && \
	apt-get update && \
	echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections &&\
	DEBIAN_FRONTEND=noninteractive apt-get install -y oracle-java8-installer

# Install Elasticsearch
# To start Elasticsearch  :  /elasticsearch/bin/elasticsearch. (Default port 9200)
RUN wget https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.3.1.tar.gz && \
	tar xf elasticsearch-1.3.1.tar.gz && \
	rm elasticsearch-1.3.1.tar.gz && \
	mv elasticsearch-1.3.1 elasticsearch 

# Install Logstash
# Create a logstash.conf and start logstash by /logstash/bin/logstash agent -f logstash.conf
RUN wget https://download.elasticsearch.org/logstash/logstash/logstash-1.4.2.tar.gz && \
	tar xf logstash-1.4.2.tar.gz && \
	rm logstash-1.4.2.tar.gz && \
	mv logstash-1.4.2 logstash

# Install Kibana
RUN wget https://download.elasticsearch.org/kibana/kibana/kibana-3.1.0.tar.gz && \
	tar xf kibana-3.1.0.tar.gz && \
	rm kibana-3.1.0.tar.gz && \
	mv kibana-3.1.0  kibana

# Install vim 
RUN apt-get install -y vim

# Install Nginx(Default Port 80)
# Sed command is to make the worker threads of nginx run as user root
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y nginx && \
	sed -i -e 's/www-data/root/g' /etc/nginx/nginx.conf

# Deploy kibana to Nginx
RUN rm /usr/share/nginx/html/* && cp -r /kibana/* /usr/share/nginx/html

# Create a start bash script
RUN touch start.sh && \
	echo '#!/bin/bash' >> start.sh && \
	echo '/elasticsearch/bin/elasticsearch &' >> start.sh && \
	echo '/etc/init.d/nginx start &' >> start.sh && \
	echo 'exec /logstash/bin/logstash agent -f /logstash.conf &' >> start.sh && \
        echo 'tail -f ' >> start.sh && \
	chmod 777 start.sh
	
#Add add logstash.conf into images
ADD logstash.conf /logstash.conf

#Add restart-logstash.sh into images
RUN touch restart-logstash.sh && \
    echo "ps aux | grep -i logstash | awk {'print \$2'} | xargs kill -9" >> restart-logstash.sh && \
    echo 'exec /logstash/bin/logstash agent -f /logstash.conf &' >> restart-logstash.sh && \
    chmod 777 restart-logstash.sh

# Nginx =>  80
# Elasticsearch => 9200,
# Logstash TCP Stream =>  3333,3334
EXPOSE 80 3333 3334 9200

