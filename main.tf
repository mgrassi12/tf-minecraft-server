provider "aws" {
  profile = "default"
  region  = var.your_region
  default_tags {
    tags = {
      Environment = "Production"
      Name = "minecraft-server"
      Repo = "https://github.com/mgrassi12/tf-minecraft-server"
      ManagedBy = "Terraform"
    }
  }
}

# Build the security group to be used by the instance
resource "aws_security_group" "minecraft_server_security_group" {
  ingress {
    description = "Receive SSH from home."
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.your_ip}"]
  }
  ingress {
    description = "Receive Minecraft (Bedrock Edition) traffic from everywhere."
    from_port   = 19132
    to_port     = 19133
    protocol    = "tcp"
    cidr_blocks = var.player_whitelist
  }
  ingress {
    description = "Receive Minecraft (Bedrock Edition) traffic from everywhere."
    from_port   = 19132
    to_port     = 19133
    protocol    = "udp"
    cidr_blocks = var.player_whitelist
  }
  egress {
    description = "Send to everywhere."
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# For SSHing to the instance
resource "aws_key_pair" "home" {
  key_name   = "Home"
  public_key = var.your_public_key
}

# Find an Ubuntu Server 20.04 LTS image
data "aws_ami" "ubuntu_server_20_04_lts" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Build the instance to be used as the MC Bedrock Edition server itself
resource "aws_instance" "minecraft" {
  ami                         = data.aws_ami.ubuntu_server_20_04_lts.id
  instance_type               = var.instance_type
  vpc_security_group_ids      = [aws_security_group.minecraft_server_security_group.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.home.key_name
  user_data                   = <<-EOF
    #!/bin/bash
    sudo apt-get update --yes
    sudo snap install aws-cli --classic --accept-classic
    sudo apt -y install unzip
    mkdir minecraft
    cd minecraft
    wget -O server_files.zip https://minecraft.azureedge.net/bin-linux/bedrock-server-1.19.51.01.zip
    unzip server_files.zip
    rm server_files.zip
    LD_LIBRARY_PATH=.
    export LD_LIBRARY_PATH
    chmod +rwx bedrock_server
    ./bedrock_server
    EOF
}

# TODO: change to spot instancing to reduce cost + do backups to keep game state across terminations
# TODO: r53 records for using a fqdn
# TODO: save state in s3 bucket
# TODO: auto deploy on push using github actions
# TODO: add customization of server.properties through tfvars