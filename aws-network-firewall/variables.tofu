variable "cidr_range" {
  type        = string
  description = "CIDR range in CIDR format to whitelist IP's for ssh access"
}

variable "public_ssh_key_material" {
  type        = string
  description = "Public key ssh to enable you to SSH into the instance"
}
