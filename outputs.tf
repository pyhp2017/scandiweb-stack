output "scandiweb_magento2_ip" {
  value = "${aws_instance.scandiweb_magento2.public_ip}"
}

output "scandiweb_varnish_ip" {
  value = "${aws_instance.scandiweb_varnish.public_ip}"
}

output "admin_url" {
    value = "https://${data.aws_route53_zone.scandiweb_zone.name}/admin"
}

output "admin_user" {
    value = "admin"
}

output "admin_password" {
    value = "admin123"
}

