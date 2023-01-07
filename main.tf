provider "aws" {
  profile = "default"
  region  = var.your_region
  default_tags {
    tags = {
      Environment = "Production"
      Name        = var.application_name
      Repo        = "https://github.com/mgrassi12/tf-minecraft-server"
      ManagedBy   = "Terraform"
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
resource "aws_spot_instance_request" "minecraft_server_spot_instance" {
  spot_price                     = var.spot_price
  wait_for_fulfillment           = "true"
  spot_type                      = "persistent"
  instance_interruption_behavior = "stop"
  ami                            = data.aws_ami.ubuntu_server_20_04_lts.id
  instance_type                  = var.instance_type
  vpc_security_group_ids         = [aws_security_group.minecraft_server_security_group.id]
  associate_public_ip_address    = true
  key_name                       = aws_key_pair.home.key_name
  user_data                      = <<-EOF
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

# Create snapshots of the instance's storage on a schedule
resource "aws_iam_role" "minecraft_dlm_lifecycle_role" {
  name = "minecraft_dlm_lifecycle_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "dlm.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "minecraft_dlm_lifecycle" {
  name = "minecraft_dlm_lifecycle"
  role = aws_iam_role.minecraft_dlm_lifecycle_role.id

  policy = <<EOF
{
   "Version": "2012-10-17",
   "Statement": [
      {
         "Effect": "Allow",
         "Action": [
            "ec2:CreateSnapshot",
            "ec2:CreateSnapshots",
            "ec2:DeleteSnapshot",
            "ec2:DescribeInstances",
            "ec2:DescribeVolumes",
            "ec2:DescribeSnapshots"
         ],
         "Resource": "*"
      },
      {
         "Effect": "Allow",
         "Action": [
            "ec2:CreateTags"
         ],
         "Resource": "arn:aws:ec2:*::snapshot/*"
      }
   ]
}
EOF
}

resource "aws_dlm_lifecycle_policy" "minecraft_dlm_lifecycle_policy" {
  description        = "DLM lifecycle policy for Minecraft server spot instance"
  execution_role_arn = aws_iam_role.minecraft_dlm_lifecycle_role.arn
  state              = "ENABLED"

  policy_details {
    resource_types     = ["INSTANCE"]
    resource_locations = ["CLOUD"]
    policy_type        = "EBS_SNAPSHOT_MANAGEMENT"
    target_tags = {
      Name = var.application_name
    }

    schedule {
      name = "2 weeks of bidaily snapshots"

      create_rule {
        interval      = 12
        interval_unit = "HOURS"
        times         = ["23:45"]
      }

      retain_rule {
        count = 14
      }

      tags_to_add = {
        SnapshotCreator = "DLM"
      }

      copy_tags = true
    }
  }
}

# Alarms to stop the instance if it has been on/idling for too long
resource "aws_cloudwatch_metric_alarm" "minecraft_low_cpu_util_alarm" {
  alarm_name          = "minecraft_low_cpu_util_stop_alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "3600"
  statistic           = "Maximum"
  threshold           = "2"
  actions_enabled     = true
  alarm_actions       = ["arn:aws:automate:${var.your_region}:ec2:stop"]
  dimensions = {
    InstanceId = aws_spot_instance_request.minecraft_server_spot_instance.id
  }
  alarm_description = "Stop instance when maximum CPU usage is less than 2% for an hour"
}

resource "aws_cloudwatch_metric_alarm" "minecraft_uptime_alarm" {
  alarm_name          = "minecraft_uptime_stop_alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Uptime"
  namespace           = "AWS/EC2"
  period              = "3600"
  statistic           = "Average"
  threshold           = "259200"
  actions_enabled     = true
  alarm_actions       = ["arn:aws:automate:${var.your_region}:ec2:stop"]
  dimensions = {
    InstanceId = aws_spot_instance_request.minecraft_server_spot_instance.id
  }
}