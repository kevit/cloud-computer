locals {
}

module "cloud-computer" {
  source = "github.com/terraform-digitalocean-modules/terraform-digitalocean-droplet"

  droplet_count = 1

  droplet_name       = "cloud-computer"
  droplet_size =  "s-1vcpu-2gb"
  monitoring         = true
  private_networking = true
  ipv6               = true
  floating_ip        = true
  block_storage_size = 50
  tags               = [""]
  user_data          = "${file("user-data.web")}"
}
resource "digitalocean_droplet" "cloud-computer" {
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
}
