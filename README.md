```
 _____                     __                               _                            __ _
/__   \___ _ __ _ __ __ _ / _| ___  _ __ _ __ ___     /\/\ (_)_ __   ___  ___ _ __ __ _ / _| |_
  / /\/ _ \ '__| '__/ _` | |_ / _ \| '__| '_ ` _ \   /    \| | '_ \ / _ \/ __| '__/ _` | |_| __|
 / / |  __/ |  | | | (_| |  _| (_) | |  | | | | | | / /\/\ \ | | | |  __/ (__| | | (_| |  _| |_
 \/   \___|_|  |_|  \__,_|_|  \___/|_|  |_| |_| |_| \/    \/_|_| |_|\___|\___|_|  \__,_|_|  \__|
```

## Setup
- Generate an SSH key if you don't already have one with `ssh-keygen -t rsa -b 4096`.
- [Install Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli) (tested on 1.1.3).
- [Install the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html).
- [Configure the AWS CLI with an access key ID and secret access key](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html).

## Steps
- Create your .tfvars files based on the examples provided in the repo.
- Run `terraform init`.
- Run `terraform apply`.
- Copy the IP output by the previous command into Minecraft.
- Wait a minute for the server to spin up.
- Play.
- Irrecoverably shut everything down with `terraform destroy`.

For troubleshooting or changing server properties (like game difficulty), SSH to the EC2 instance using `ssh -i ~/.ssh/id_rsa ubuntu@ip_of_instance_goes_here`

## Acknowledgements
This project deploys a Bedrock Edition server. It was originally cloned from this [Java Edition server project](https://github.com/HarryNash/terraform-minecraft) and combined with info from [here](https://gist.github.com/johntelforduk/8128dadc05ac5d14b6d835ce772dc3dc). I have used a spot instance in lieu of an on-demand instance and have used alarms to shut down idling instances for cost reduction purposes. This is a work-in-progress.

## To-Do List
- Static ip + r53 records for using a fqdn
- Save state in s3 bucket
- Automate deployment on push using github actions
- Add customization of server.properties through tfvars
- Send email notification when alarm is triggered