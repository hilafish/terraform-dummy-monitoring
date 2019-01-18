##################################################################################
# VARIABLES
##################################################################################

variable "aws_access_key" {
    default = "<your_aws_access_key>"
}

variable "aws_secret_key" {
    default = "<your_aws_secret_key>"
} 

variable "aws_private_key_path" {
    default = "<your_aws_private_key_path>"
}

variable "aws_key_name" {
    default = "<your_aws_key_name>"
}

variable "aws_region" {
    default = "us-east-2"
}

##################################################################################
# PROVIDERS
##################################################################################

provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.aws_region}"
}

##################################################################################
# DATA
##################################################################################

data "template_file" "consul-client-userdata" {
  template = "${file("${path.module}/config/user-data/consul-client-userdata.sh.tpl")}"

  vars {
    elastic_search_private_ip = "${aws_instance.elastic_search.private_ip}"
    CHECKPOINT_URL            = "https://checkpoint-api.hashicorp.com/v1/check"
    LOCAL_IPV4                = "$${LOCAL_IPV4}"
    CONSUL_VERSION            = "$${CONSUL_VERSION}"
    DATACENTER_NAME           = "OpsSchool"
  }
}

data "template_file" "kibana_config" {
  template = "${file("${path.module}/config/kibana/kibana.yml.tpl")}"

  vars {
    elastic_search_private_ip = "${aws_instance.elastic_search.private_ip}"
  }
}

data "template_file" "prometheus-userdata" {
  template = "${file("${path.module}/config/user-data/prometheus-userdata.sh.tpl")}"

  vars {
    consul_server_private_ip = "${aws_instance.consul_server.private_ip}"
  }
}

data "template_file" "elasticsearch-userdata" {
  template = "${file("${path.module}/config/user-data/elasticsearch-userdata.sh.tpl")}"

  vars {
    LOCAL_IPV4 = "$${LOCAL_IPV4}"
  }
}

data "template_file" "prometheus_datasource" {
  template = "${file("${path.module}/config/grafana/prometheus_datasource.yaml.tpl")}"

  vars {
    prometheus_private_ip = "${aws_instance.prometheus.private_ip}"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

##################################################################################
# RESOURCES
##################################################################################

# INSTANCES #

resource "aws_instance" "elastic_search" {
  ami                    = "${data.aws_ami.ubuntu.id}"
  instance_type          = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.elastic-search-sg.id}"]
  subnet_id              = "${aws_subnet.priv_subnet.id}"
  key_name               = "${var.aws_key_name}"
  depends_on             = ["aws_nat_gateway.NATGW-Custom-VPC"]

  connection {
    user        = "ubuntu"
    private_key = "${file(var.aws_private_key_path)}"
  }

  tags {
    Name = "elastic_search"
  }

    user_data = "${data.template_file.elasticsearch-userdata.rendered}"
}

resource "aws_instance" "consul_server" {
  ami                    = "${data.aws_ami.ubuntu.id}"
  instance_type          = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.consul-sg.id}"]
  key_name               = "${var.aws_key_name}"
  subnet_id              = "${aws_subnet.priv_subnet.id}"
  iam_instance_profile   = "${aws_iam_instance_profile.consul-server-instance-profile.name}"
  depends_on             = ["aws_nat_gateway.NATGW-Custom-VPC"]

  connection {
    user        = "ubuntu"
    private_key = "${file(var.aws_private_key_path)}"
  }

  tags {
    Name = "consul-server"
  }

  user_data = "${file("${path.module}/config/user-data/consul-server-userdata.sh")}"
}

resource "aws_instance" "prometheus" {
  ami                    = "${data.aws_ami.ubuntu.id}"
  instance_type          = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.prometheus-sg.id}"]
  key_name               = "${var.aws_key_name}"
  subnet_id              = "${aws_subnet.priv_subnet.id}"
  depends_on             = ["aws_instance.consul_server", "aws_nat_gateway.NATGW-Custom-VPC"]

  connection {
    user        = "ubuntu"
    private_key = "${file(var.aws_private_key_path)}"
  }

  tags {
    Name = "prometheus"
  }

  user_data = "${data.template_file.prometheus-userdata.rendered}"
}

resource "aws_instance" "kibana_grafana" {
  ami                         = "${data.aws_ami.ubuntu.id}"
  instance_type               = "t2.micro"
  vpc_security_group_ids      = ["${aws_security_group.kibana-grafana-sg.id}"]
  associate_public_ip_address = true
  key_name                    = "${var.aws_key_name}"
  subnet_id                   = "${aws_subnet.pub_subnet.id}"
  depends_on                  = ["aws_instance.elastic_search", "aws_instance.kibana_grafana"]

  connection {
    user        = "ubuntu"
    private_key = "${file(var.aws_private_key_path)}"
  }

  tags {
    Name = "kibana_grafana"
  }

  provisioner "file" {
    content     = "${data.template_file.kibana_config.rendered}"
    destination = "/tmp/kibana.yml"
  }

  provisioner "file" {
    source      = "${path.module}/config/kibana/kibana_dashboard.json"
    destination = "/tmp/kibana_dashboard.json"
  }

  provisioner "file" {
    content     = "${data.template_file.prometheus_datasource.rendered}"
    destination = "/tmp/prometheus_datasource.yaml"
  }

  provisioner "file" {
    source      = "${path.module}/config/grafana/prometheus_dashboards.yaml"
    destination = "/tmp/prometheus_dashboards.yaml"
  }

  provisioner "file" {
    source      = "${path.module}/config/grafana/grafana_dashboard.json"
    destination = "/tmp/grafana_dashboard.json"
  }

  provisioner "remote-exec" {
    inline = [
      # installing kibana & grafana
      "wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -",
      "echo \"deb https://artifacts.elastic.co/packages/6.x/apt stable main\" | sudo tee -a /etc/apt/sources.list.d/elastic-6.x.list",
      "echo \"deb https://packagecloud.io/grafana/stable/debian/ stretch main\" | sudo tee -a /etc/apt/sources.list.d/grafana.list",
      "sudo curl https://packagecloud.io/gpg.key | sudo apt-key add -",
      "sudo apt-get update",
      "sudo apt-get install -y --allow-unauthenticated kibana grafana",
      "sudo mv /tmp/kibana.yml /etc/kibana/",
      "sudo sed -i \"s/#server.host: \\\"localhost\\\"/server.host: \\\"${self.private_ip}\\\"/g\" /etc/kibana/kibana.yml",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable kibana",
      "sudo mkdir /var/lib/grafana/dashboards",
      "sudo mv /tmp/prometheus_datasource.yaml /etc/grafana/provisioning/datasources/",
      "sudo mv /tmp/grafana_dashboard.json /var/lib/grafana/dashboards/",
      "sudo mv /tmp/prometheus_dashboards.yaml /etc/grafana/provisioning/dashboards/",
      "dummy1_hostname=$(echo '${aws_instance.dummy_exporter.0.private_dns}' | awk '{split($0,a,\".\"); print a[1]}')",
      "dummy2_hostname=$(echo '${aws_instance.dummy_exporter.1.private_dns}' | awk '{split($0,a,\".\"); print a[1]}')",
      "sudo sed -i \"s/dummy-exporter-1/$${dummy1_hostname}/g\" /var/lib/grafana/dashboards/grafana_dashboard.json",
      "sudo sed -i \"s/dummy-exporter-2/$${dummy2_hostname}/g\" /var/lib/grafana/dashboards/grafana_dashboard.json",
      "sudo systemctl restart kibana",
      "sudo systemctl enable grafana-server",
      "sudo systemctl start grafana-server",
      "sleep 30",
      "curl -f -XPOST -H 'Content-Type: application/json' -H 'kbn-xsrf: anything' 'http://${self.private_ip}:5601/api/saved_objects/index-pattern/filebeat-*' '-d{\"attributes\":{\"title\":\"filebeat-*\",\"timeFieldName\":\"@timestamp\"}}'",
      "curl -u elastic:${aws_instance.elastic_search.private_ip} -k -XPOST 'http://${self.private_ip}:5601/api/kibana/dashboards/import' -H 'Content-Type: application/json' -H \"kbn-xsrf: true\" -d @/tmp/kibana_dashboard.json",
    ]
  }
}

resource "aws_instance" "dummy_exporter" {
  count                  = 2
  ami                    = "${data.aws_ami.ubuntu.id}"
  instance_type          = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.dummy-exporter-sg.id}"]
  key_name               = "${var.aws_key_name}"
  iam_instance_profile   = "${aws_iam_instance_profile.consul-server-instance-profile.name}"
  subnet_id              = "${aws_subnet.priv_subnet.id}"
  depends_on             = ["aws_instance.consul_server", "aws_nat_gateway.NATGW-Custom-VPC"]

  connection {
    user        = "ubuntu"
    private_key = "${file(var.aws_private_key_path)}"
  }

  tags {
    Name = "dummy-exporter-${count.index + 1}"
  }

  user_data = "${data.template_file.consul-client-userdata.rendered}"
}

##################################################################################
# OUTPUT
##################################################################################

output "kibana_grafana_public_dns" {
  value = "${aws_instance.kibana_grafana.public_dns}"
}
