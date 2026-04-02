packer {
  required_plugins {
    docker = {
      version = ">= 1.0.8"
      source  = "github.com/hashicorp/docker"
    }
  }
}

source "docker" "nginx" {
  image  = "nginx:latest"
  commit = true
}

build {
  sources = ["source.docker.nginx"]

  # On copie le fichier index.html dans le dossier web de Nginx
  provisioner "file" {
    source      = "index.html"
    destination = "/usr/share/nginx/html/index.html"
  }

  # On donne un nom à notre nouvelle image
  post-processor "docker-tag" {
    repository = "custom-nginx"
    tags       = ["latest"]
  }
}