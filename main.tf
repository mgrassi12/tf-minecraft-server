provider "aws" {
  profile = "default"
  region  = var.your_region
}

resource "aws_security_group" "minecraft" {
  ingress {
    description = "Receive SSH from home."
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.your_ip}/32"]
  }
  ingress {
    description = "Receive Minecraft from everywhere."
    from_port   = 25565
    to_port     = 25565
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Send everywhere."
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Minecraft"
  }
}

resource "aws_key_pair" "home" {
  key_name   = "Home"
  public_key = var.your_public_key
}

resource "aws_instance" "minecraft" {
  ami                         = "ami-0fdbd8587b1cf431e"
  instance_type               = "t2.small"
  vpc_security_group_ids      = [aws_security_group.minecraft.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.home.key_name
  user_data                   = <<-EOF
    #!/bin/bash
    sudo yum -y update
    sudo rpm --import https://yum.corretto.aws/corretto.key
    sudo curl -L -o /etc/yum.repos.d/corretto.repo https://yum.corretto.aws/corretto.repo
    sudo yum install -y java-17-amazon-corretto-devel.x86_64
    wget -O server.jar ${var.mojang_server_url}
    java -Xmx1024M -Xms1024M -jar server.jar nogui
    sed -i 's/eula=false/eula=true/' eula.txt
    java -Xmx1024M -Xms1024M -jar server.jar nogui
    EOF
  tags = {
    Name = "Minecraft"
  }
}