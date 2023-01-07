variable "your_region" {
  type        = string
  description = "Where you want your server to be. The options are here https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.RegionsAndAvailabilityZones.html."
}

variable "application_name" {
  type        = string
  description = "Name used in tags."
}

variable "instance_type" {
  type        = string
  description = "Type of EC2 instance to run the Minecraft server. T3.medium as a minimum is advisable."
}

variable "spot_price" {
  type        = string
  description = "Spot price for instance type."
}

variable "your_ip" {
  type        = string
  description = "Only this IP will be able to administer the server. Find it here https://www.whatsmyip.org/."
  sensitive = true
}

variable "player_whitelist" {
  type        = list
  description = "Only these IPs will be able to connect and play on the server."
  sensitive = true
}

variable "your_public_key" {
  type        = string
  description = "This will be in ~/.ssh/id_rsa.pub by default."
  sensitive = true
}