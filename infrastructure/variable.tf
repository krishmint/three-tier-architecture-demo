variable "cidr" {
    default = "10.0.0.0/16"
  }

variable "ssh_key_name" {
  description = "The name of the SSH key pair to use for instances"
  type        = string
  default     = "mumbaikey"     ## change the key name acc to region req
}  
