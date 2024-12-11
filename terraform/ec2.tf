data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

resource "aws_instance" "jenkins" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.medium"
  subnet_id     = module.vpc_jenkins_demo.public_subnets[0]

  key_name                    = local.ec2_key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.jenkins.id]

  user_data_replace_on_change = true
  user_data                   = <<-EOF
              #! /bin/bash
              apt update
              apt install docker.io -y 
              mkdir -p /usr/local/lib/docker/cli-plugins/
              curl -SL https://github.com/docker/compose/releases/download/v2.30.3/docker-compose-linux-x86_64 -o /usr/local/lib/docker/cli-plugins/docker-compose
              chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
              systemctl start docker
              EOF

  instance_market_options {
    market_type = "spot"
    spot_options {
      max_price = 0.0528
    }
  }

  tags = {
    Name = "Jenkins-Controller"
  }
}
