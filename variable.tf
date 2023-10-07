

variable "region" {
  description = "The region where the resources will be created"
  default     = "us-west2"
}

variable "zone" {
  description = "The zone where the resources will be created"
  default     = "us-west2-a"
}

variable "instance_type" {
  description = "The machine type for the instances"
  default     = "n2-standard-4"
}

variable "min_size" {
  description = "The minimum number of instances in the autoscaling group"
  default     = 1
}

variable "max_size" {
  description = "The maximum number of instances in the autoscaling group"
  default     = 10
}

variable "device_count" {
  description = "The number of devices connected to the VM"
  default     = 0
}