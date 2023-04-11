# Using Terraform for Local Docker Deployments

Terraform can be used to automate more than just remote deployment configuration and architecture. In this demo I am going to walk through deploying a local docker image, and then I'll expand to using terraform to automate local dummy configuration for more complex application architectures.

First, let's test that we can configure a local docker image to run with terraform. We will start out with a simple `main.tf` file that looks something like this:

```
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "2.23.1"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

resource "docker_image" "alpine" {
  name = "alpine:latest"
}

resource "docker_container" "webserver" {
  image             = docker_image.alpine.repo_digest
  name              = "docker-test-v1"
  must_run          = true
  publish_all_ports = true
  command = [
    "tail",
    "-f",
    "/dev/null"
  ]
}
```

In the above we configure a _provider_ for Docker, setup the image we want to use, and deploy it with a set of custom run commands. Instead of walking you through the basics of that, let's pull it apart as we make improvements and turn this in to something more useful.

The first thing I want to do is be able to customize aspects of this deployment easily, so let's create a var file. For now we are just going to populate with a value of "alpine_instances = 3". So you should end up with a `terraform.tfvars` file that looks like this:

```
alpine_instances = 3
```

Now we will have to add a `variables.tf` file to make use of this new config item. This file will get more attention as we add more complications to project:

```
variable "alpine_instances" {
 type        = number
 description = "Count of instances to deploy"
}
```

Now, let's make a quick modiciation to the `main.tf` file to use this new configuration item:

```
...
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
```

You can now run the project to spin up 3 test containers in docker, that should be labelled 0 through 2, according to the count index. That'll let you spin up a number of test instances to check out distributed systems, but let's say you want to take it further. Right now let's take a look at the control surfaces we can move to configuration items.

In `main.tf` we can add some additional configuration for both the alpine version tag to use and the docker providers host command. As you can see below these are small changes, using terraforms conditional and string interpolation concepts, but they give you much greater control with the config file. These changes allow you to specify a fixed version of the docker image to use and allow you to run the deployment from a Windows machine, all without making direct changes to the terraform code.

```
...
provider "docker" {
  host = var.deployment_os == "Windows" ? "tcp://localhost:2375" : "unix:///var/run/docker.sock"
}

resource "docker_image" "alpine" {
  name = "alpine:${var.alpine_tag}"
}
...
```

We need to make an adjustment to the `variables.tf` file as well. In that I am going to include the defaults I would like to use for this configuration.

```
...
variable "deployment_os" {
 type        = string
 description = "Count of instances to deploy"
 default     = "unix"
}

variable "alpine_tag" {
 type        = string
 description = "The tag for the alpine image version to use"
 default     = "latest"
}
```

Now with this configuration I also need to deploy a db server alongside my test instances. We aren't running a real application just yet, so I am not too worried about underlying db requirements so we are just going to use Redis for demonstration purposes.

`variables.tf`
```
...
variable "redis_tag" {
 type        = string
 description = "The tag for the alpine image version to use"
 default     = "7.2-rc-alpine"
}
```

`main.tf`
```
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
```

Once those chanages are made, when you run `terraform apply --var-file=./terraform.tfvars` you should now see four servers deploy.