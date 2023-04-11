terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "2.23.1"
    }
  }
}

provider "docker" {
  host = var.deployment_os == "Windows" ? "tcp://localhost:2375" : "unix:///var/run/docker.sock"
}

resource "docker_image" "alpine" {
  name = "alpine:${var.alpine_tag}"
}

resource "docker_image" "redis" {
    name = "redis:${var.redis_tag}"
}

resource "docker_container" "webserver" {
  count             = var.alpine_instances
  image             = docker_image.alpine.repo_digest
  name              = "docker-test-v1_${count.index}"
  must_run          = true
  publish_all_ports = true
  command = [
    "tail",
    "-f",
    "/dev/null"
  ]
}

resource "docker_container" "dbserver" {
  image             = docker_image.redis.repo_digest
  name              = "docker-test-redis"
  must_run          = true
  publish_all_ports = true
  command = [
    "tail",
    "-f",
    "/dev/null"
  ]
}