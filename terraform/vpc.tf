data "aws_availability_zones" "available" {}

module "vpc_jenkins_demo" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.13.0"

  name = local.global_name
  cidr = local.vpc_cidr

  azs             = local.available_azs
  private_subnets = [for k, v in local.available_azs : cidrsubnet(local.vpc_cidr, 8, k)]
  public_subnets  = [for k, v in local.available_azs : cidrsubnet(local.vpc_cidr, 8, k + 4)]


  enable_dns_hostnames = true
}

resource "aws_security_group" "jenkins" {
  vpc_id = module.vpc_jenkins_demo.vpc_id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = local.ssh_ip_whitelist
  }

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}
