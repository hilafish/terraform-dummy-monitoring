#!/bin/bash
sudo apt-get install -y openjdk-8-jdk
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
echo "deb https://artifacts.elastic.co/packages/6.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-6.x.list
sudo apt-get update
sudo apt-get install elasticsearch
LOCAL_IPV4=$(curl "http://169.254.169.254/latest/meta-data/local-ipv4")
sudo sed -i "s/#network.host: 192.168.0.1/network.host: ${LOCAL_IPV4}/g" /etc/elasticsearch/elasticsearch.yml
sudo sed -i "s/#cluster.name: my-application/cluster.name: elastic-cluster/g" /etc/elasticsearch/elasticsearch.yml
sudo sed -i "s/#node.name: node-1/node.name: elastic1/g" /etc/elasticsearch/elasticsearch.yml
sudo sed -i "s/-Xms1g/-Xms256m/g" /etc/elasticsearch/jvm.options
sudo sed -i "s/-Xmx1g/-Xmx256m/g" /etc/elasticsearch/jvm.options
sudo sysctl -w vm.max_map_count=262144
sudo systemctl enable elasticsearch
sudo systemctl restart elasticsearch



