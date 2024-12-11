variable "ec2_key_name" {
  type        = string
  description = "Name of the EC2 key pair to use. This will be used to ssh into the instance to install Jenkins."
}

variable "ssh_ip_whitelist" {
  type        = list(string)
  description = "A list of IPs in CIDR notation from which you will be able to ssh into the Jenkins controller."
}

# variable "route53_hosted_zone_name" {
#   type        = string
#   default     = ""
#   description = "Name of the Route53 zone where to create the record for the Jenkins instance."

#   validation {
#     condition     = var.jenkins_hostname != ""
#     error_message = "The `jenkins_hostname` variable must be set when declaring a Route53 hosted zone."
#   }
# }

# variable "jenkins_hostname" {
#   type        = string
#   default     = ""
#   description = "Jenkins controller hostname."

#   validation {
#     condition     = var.route53_hosted_zone_name != ""
#     error_message = "The `route53_hosted_zone_name` variable must be set when declaring a Jenkins hostname."
#   }
# }

variable "jenkins_dns" {
  type = object({
    hosted_zone = string
    hostname    = string
  })

  default = {
    hosted_zone = ""
    hostname    = ""
  }

  validation {
    condition     = (var.jenkins_dns.hosted_zone != "" && var.jenkins_dns.hostname != "") || (var.jenkins_dns.hosted_zone == "" && var.jenkins_dns.hostname == "")
    error_message = "Both `jenkins_dns.hosted_zone` and `jenkins_dns.hostname` must be defined to configure DNS."
  }
}
