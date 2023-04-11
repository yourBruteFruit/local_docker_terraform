variable "alpine_instances" {
 type        = number
 description = "Count of instances to deploy"
}

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

variable "redis_tag" {
 type        = string
 description = "The tag for the alpine image version to use"
 default     = "7.2-rc-alpine"
}