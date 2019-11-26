locals {
  environment_name = "cloud-computer-${var.CLOUD_COMPUTER_HOST_ID}-${random_id.instance_id.hex}"
  machine_type = "nano"
}

provider "aws" {
  region = "eu-west-1"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_security_group" "default" {
  name   = "default"
  vpc_id = data.aws_vpc.default.id
}

module "web_server_sg" {
  source = "terraform-aws-modules/security-group/aws//modules/http-80"

  name        = "web-server"
  description = "Security group for web-server with HTTP ports open within VPC"
  vpc_id = data.aws_vpc.default.id
  ingress_cidr_blocks = ["10.10.0.0/16"]
}

module "key_pair" {
  source = "terraform-aws-modules/key-pair/aws"
  key_name   = "cloud-computer"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD3F6tyPEFEzV0LX3X8BsXdMsQz1x2cEikKDEY0aIj41qgxMCP/iteneqXSIFZBp5vizPvaoIR3Um9xK7PGoW8giupGn+EPuxIA4cDM4vzOqOkiMPhz5XK0whEjkVzTo4+S0puvDZuwIsdiW9mxhJc7tgBNL0cYlWSYVkz4G/fslNfRPW5mYAM49f4fhtxPb5ok4Q2Lg9dPKVHO/Bgeu5woMc7RY0p1ej6D4CKFE6lymSDJpW0YHX/wqE9+cfEauh7xZcG0q9t2ta6F6fmX0agvpFyZo8aFbXeUBr7osSCJNgvavWbM/06niWrOvYX2xwWdhXmXSrbX8ZbabVohBK41 email@example.com"

}

module "cloud-computer" {
  source                 = "terraform-aws-modules/ec2-instance/aws"
  version                = "~> 2.0"
  name                   = "${var.environment_name}"
  instance_count         = 1
  ami                    = "ami-ebd02392"
  instance_type          = "${var.machine_type}"
  key_name               = "cloud-computer"
  monitoring             = true
  vpc_security_group_ids      = [module.aws_security_group.this_security_group_id]
  subnet_id     = tolist(data.aws_subnet_ids.all.ids)[0]
  tags = {
  }
}


  provisioner "remote-exec" {
    connection {
      agent = false
      private_key = "${tls_private_key.cloud-computer.private_key_pem}"
      type = "ssh"
      user = "root"
    }

    inline = [
      "# Set cloud computer environment",
      "export CLOUD_COMPUTER_CLOUD_PROVIDER_CREDENTIALS='${file("${var.cloud_provider_credentials_path}")}'",
      "export CLOUD_COMPUTER_DNS_EMAIL=${var.CLOUD_COMPUTER_DNS_EMAIL}",
      "export CLOUD_COMPUTER_DNS_TOKEN=${var.CLOUD_COMPUTER_DNS_TOKEN}",
      "export CLOUD_COMPUTER_DNS_ZONE=${var.CLOUD_COMPUTER_DNS_ZONE}",
      "export CLOUD_COMPUTER_HOST_ID=${var.CLOUD_COMPUTER_HOST_ID}",
      "export CLOUD_COMPUTER_IMAGE=${var.CLOUD_COMPUTER_IMAGE}",
      "export CLOUD_COMPUTER_REPOSITORY=${var.CLOUD_COMPUTER_REPOSITORY}",
      "export CLOUD_COMPUTER_YARN_JAEGER_TRACE=${var.CLOUD_COMPUTER_YARN_JAEGER_TRACE}",
      "export GIT_COMMITTER_EMAIL=${var.GIT_COMMITTER_EMAIL}",
      "export GIT_COMMITTER_NAME=${var.GIT_COMMITTER_NAME}",

      "# Alias docker run with cloud computer environment",
      "alias docker_run=\"docker run --env CLOUD_COMPUTER_DNS_EMAIL --env CLOUD_COMPUTER_DNS_TOKEN --env CLOUD_COMPUTER_DNS_ZONE --env CLOUD_COMPUTER_HOST_ID --env CLOUD_COMPUTER_CLOUD_PROVIDER_CREDENTIALS --env CLOUD_COMPUTER_YARN_JAEGER_TRACE --env DOCKER_HOST=localhost --env GIT_COMMITTER_EMAIL --env GIT_COMMITTER_NAME --interactive --rm --tty --volume CLOUD_COMPUTER_REPOSITORY:$CLOUD_COMPUTER_REPOSITORY --volume /var/run/docker.sock:/var/run/docker.sock --workdir $CLOUD_COMPUTER_REPOSITORY\"",
      "alias docker_run_root=\"docker_run --user root $CLOUD_COMPUTER_IMAGE\"",
      "alias docker_run_non-root=\"docker_run $CLOUD_COMPUTER_IMAGE\"",

      "# Clone the cloud computer repository",
      "docker_run_root git clone --branch ${var.CLOUD_COMPUTER_GIT_BRANCH} --quiet ${var.CLOUD_COMPUTER_GIT_URL} $CLOUD_COMPUTER_REPOSITORY",

      "# Set ownership of the CLOUD_COMPUTER_REPOSITORY volume",
      "docker_run_root chown -R 1000:1000 $CLOUD_COMPUTER_REPOSITORY",

      "# Start the cloud computer",
      "docker_run_non-root yarn --cwd infrastructure/cloud-computer start",
    ]
  }

  scheduling {
    on_host_maintenance = "TERMINATE"
  }
}
