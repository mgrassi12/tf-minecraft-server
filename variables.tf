variable "your_region" {
  type        = string
  description = "Where you want your server to be. The options are here https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.RegionsAndAvailabilityZones.html."
}

variable "your_ip" {
  type        = string
  description = "Only this IP will be able to administer the server. Find it here https://www.whatsmyip.org/."
}

variable "your_public_key" {
  type        = string
  description = "This will be in ~/.ssh/id_rsa.pub by default."
}

variable "mojang_server_url" {
  type        = string
  description = "Copy the server download link from here https://www.minecraft.net/en-us/download/server/."
}