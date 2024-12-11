data "aws_route53_zone" "selected" {
  count = local.route53_hosted_zone_name != "" && local.jenkins_hostname != "" ? 1 : 0

  name = local.route53_hosted_zone_name
}

resource "aws_route53_record" "jenkins" {
  count = local.route53_hosted_zone_name != "" && local.jenkins_hostname != "" ? 1 : 0

  zone_id = data.aws_route53_zone.selected[0].zone_id
  name    = local.jenkins_hostname
  type    = "A"
  ttl     = 300
  records = [aws_instance.jenkins.public_ip]
}
