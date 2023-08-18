terraform {
  required_version = "~> 1.0.0"

  required_providers {
    linode = {
      source = "linode/linode"
      version = "2.5.2"
    }
  }
}

# Configure the Linode Provider
provider "linode" {
  token = var.api_token
}

variable "api_token" {
  description = "Linode access token"
}

variable "servers" {
  description = "Number of servers to create"
}

resource "linode_sshkey" "login" {
  label = "login"
  ssh_key = chomp(file("~/.ssh/id_rsa.pub"))
}

resource "random_password" "passwords" {
  count = var.servers
  length = 16
  special = true
}

resource "linode_instance" "k3s-server" {
  count            = var.servers
  label      = "k3s-server-${count.index+1}"
  tags = ["k3s", "k3s-server"]
  image      = "linode/ubuntu22.04"
  region     = "eu-west"
  type       = "g6-dedicated-2"
  authorized_keys    = [linode_sshkey.login.ssh_key]
  root_pass = random_password.passwords[count.index].result

  private_ip = true

  interface {
    purpose = "public"
  }

  interface {
    purpose = "vlan"
    label = "k3s"
    ipam_address = "192.168.3.${count.index+1}/24"
  }

  connection {
    type     = "ssh"
    user     = "root"
    password = random_password.passwords[count.index].result
    host     = self.ip_address
    
  }

  provisioner "remote-exec" {
    inline = ["sudo hostnamectl set-hostname ${self.label}" ]
  }
}

resource "linode_nodebalancer" "k3s-api" {
    label = "k3s-api"
    region = "eu-west"
    client_conn_throttle = 0
    tags = ["k3s-server"]
}

resource "linode_nodebalancer_config" "k3s-api" {
    nodebalancer_id = linode_nodebalancer.k3s-api.id
    port = 6443
    protocol = "tcp"
    check = "connection"
    algorithm = "roundrobin"
}

resource "linode_nodebalancer_config" "k3s-http" {
    nodebalancer_id = linode_nodebalancer.k3s-api.id
    port = 80
    protocol = "tcp"
    check = "connection"
    algorithm = "roundrobin"
}

resource "linode_nodebalancer_config" "k3s-https" {
    nodebalancer_id = linode_nodebalancer.k3s-api.id
    port = 443
    protocol = "tcp"
    check = "connection"
    algorithm = "roundrobin"
}


resource "linode_nodebalancer_node" "k3s-api-node" {
    count = var.servers
    nodebalancer_id = linode_nodebalancer.k3s-api.id
    config_id = linode_nodebalancer_config.k3s-api.id
    label = "k3s-server-${count.index + 1}"
    address = "${element(linode_instance.k3s-server.*.private_ip_address, count.index)}:6443"
    mode = "accept"
}

resource "linode_nodebalancer_node" "k3s-http" {
    count = var.servers
    nodebalancer_id = linode_nodebalancer.k3s-api.id
    config_id = linode_nodebalancer_config.k3s-http.id
    label = "k3s-server-${count.index + 1}"
    address = "${element(linode_instance.k3s-server.*.private_ip_address, count.index)}:80"
    mode = "accept"
}


resource "linode_nodebalancer_node" "k3s-https" {
    count = var.servers
    nodebalancer_id = linode_nodebalancer.k3s-api.id
    config_id = linode_nodebalancer_config.k3s-https.id
    label = "k3s-server-${count.index + 1}"
    address = "${element(linode_instance.k3s-server.*.private_ip_address, count.index)}:443"
    mode = "accept"
}

data "linode_instances" "k3s-vms" {
  count            = var.servers
  filter {
    name = "label"
    values = ["k3s-server-${count.index+1}"]
  }
}

output "nodebalancer" {
  value = linode_nodebalancer.k3s-api.ipv4
}

output "servers" {
  value = {
    for k, v in linode_instance.k3s-server : v.id => {"label": v.label ,"vlan_ip": trimsuffix(v.interface[1].ipam_address,"/24"), "public_ip": v.ip_address}
  }
}
