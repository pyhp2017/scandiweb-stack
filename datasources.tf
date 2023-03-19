data "aws_ami" "server_ami_ubuntu_22" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

data "aws_instances" "ec2_list" {
  instance_state_names = ["running"]
  depends_on = [aws_instance.scandiweb_varnish, aws_instance.scandiweb_magento2]
}

data "aws_subnet_ids" "GetSubnet_Ids" {
  vpc_id = aws_vpc.scandiweb_vpc.id
  filter {
    name   = "tag:Type"
    values = ["public"]
  }
  depends_on = [aws_subnet.scandiweb_public_subnet1, aws_subnet.scandiweb_public_subnet2]
}

data "template_file" "init" {
  template = "${file("${path.module}/installation/bootstrap.sh.tpl")}"

  vars = {
    MAGENTO_BASE_URL = "${aws_lb.scandiweb_lb.dns_name}"
  }
}