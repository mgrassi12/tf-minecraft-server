terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.49"
    }
  }

  default {
    tags = {
      Environment = "Production"
      Name = "minecraft-server"
      Repo = "https://github.com/mgrassi12/tf-minecraft-server"
      ManagedBy = "Terraform"
    }
  }
}