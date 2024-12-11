locals {
  global_name   = "jenkins_demo"
  vpc_cidr      = "10.0.0.0/16"
  available_azs = slice(data.aws_availability_zones.available.names, 0, 3)

  ec2_key_name     = var.ec2_key_name
  ssh_ip_whitelist = var.ssh_ip_whitelist

  route53_hosted_zone_name = var.jenkins_dns.hosted_zone
  jenkins_hostname         = var.jenkins_dns.hostname
}
