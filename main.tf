# Create a VPC (Virtual Private Cloud) for the stack
resource "aws_vpc" "scandiweb_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true # Default is true just to mention it
  enable_dns_hostnames = true

  tags = {
    Name = "scandiweb_stack_vpc"
  }
}

# Create a public subnet for the load balancer
resource "aws_subnet" "scandiweb_public_subnet1" {
  vpc_id                  = aws_vpc.scandiweb_vpc.id
  cidr_block              = "10.0.3.0/24"
  map_public_ip_on_launch = true # Assign public IP to the load balancer
  availability_zone       = "eu-central-1a"

  tags = {
    Name = "scandiweb_stack_public_subnet1"
    Type = "public"
  }
}

# Create another public subnet for the load balance 
resource "aws_subnet" "scandiweb_public_subnet2" {
  vpc_id                  = aws_vpc.scandiweb_vpc.id
  cidr_block              = "10.0.64.0/24"
  map_public_ip_on_launch = true # Assign public IP to the load balancer
  availability_zone       = "eu-central-1b"

  tags = {
    Name = "scandiweb_stack_public_subnet2"
    Type = "public"
  }
}

# Create a subnet for the EC2 instances
resource "aws_subnet" "scandiweb_instance_subnet" {
  vpc_id                  = aws_vpc.scandiweb_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = true # better to NOT assign public ip to the instances

  tags = {
    Name = "scandiweb_stack_instance_subnet"
    Type = "instance_subnet"
  }
}

# Create an internet gateway for the VPC
resource "aws_internet_gateway" "scandiweb_gw" {
  vpc_id = aws_vpc.scandiweb_vpc.id

  tags = {
    Name = "scandiweb_stack_igw"
  }
}

# Create a route table for the public subnet
resource "aws_route_table" "scandiweb_route_table" {
  vpc_id = aws_vpc.scandiweb_vpc.id

  tags = {
    Name = "scandiweb_stack_route_table"
  }
}

# Create a route for the internet gateway
resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.scandiweb_route_table.id
  destination_cidr_block = "0.0.0.0/0" # All ip addresses will go to internet gateway
  gateway_id             = aws_internet_gateway.scandiweb_gw.id
}

# Create association between subnet and route table which will allow to access the internet (for load balancer)
resource "aws_route_table_association" "scandiweb_rtassoc1" {
  subnet_id      = aws_subnet.scandiweb_public_subnet1.id
  route_table_id = aws_route_table.scandiweb_route_table.id
}

resource "aws_route_table_association" "scandiweb_rtassoc2" {
  subnet_id      = aws_subnet.scandiweb_public_subnet2.id
  route_table_id = aws_route_table.scandiweb_route_table.id
}

# Create association between subnet and route table which will allow to access the internet (for instances)
resource "aws_route_table_association" "scandiweb_rtassoc3" {
  subnet_id      = aws_subnet.scandiweb_instance_subnet.id
  route_table_id = aws_route_table.scandiweb_route_table.id
}

# Create a security group for the VPC
resource "aws_security_group" "scandiweb_sg" {
  name        = "scandiweb_stack_sg"
  description = "Security group for the Scandiweb stack"
  vpc_id      = aws_vpc.scandiweb_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"          # All protocols
    cidr_blocks = ["0.0.0.0/0"] # All ip addresses (only for testing purpose - not recommended - better to change to your ip address)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"          # All protocols
    cidr_blocks = ["0.0.0.0/0"] # Everything inside VPC could have access to internet
  }
}

# Create a key pair for the instances
resource "aws_key_pair" "scandiweb_auth" {
  key_name   = "scandiweb_stack_auth"
  public_key = var.servers_public_key
}

# Create a magento2 instance
resource "aws_instance" "scandiweb_magento2" {
  instance_type          = "t2.medium"
  ami                    = data.aws_ami.server_ami_ubuntu_22.id
  private_ip             = var.magento2_private_ip # Assign a private ip to the instance (it is better to use another method - 
  # i didn't find a way to do it)
  subnet_id              = aws_subnet.scandiweb_instance_subnet.id
  vpc_security_group_ids = [aws_security_group.scandiweb_sg.id]
  key_name               = aws_key_pair.scandiweb_auth.key_name
  user_data              = data.template_file.init.rendered

  # Copy the all the magento config files to the instance
  provisioner "file" {
    source      = "installation/magento/"
    destination = "/home/ubuntu"
  }

  # Setup connection to the instance
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.servers_private_key_path)
    host        = self.public_ip
    timeout     = "4m"
  }

  root_block_device {
    volume_size = 20
  }

  tags = {
    Name = "scandiweb_stack_magento2"
  }
}

# Create a varnish instance
resource "aws_instance" "scandiweb_varnish" {
  instance_type          = "t2.micro"
  ami                    = data.aws_ami.server_ami_ubuntu_22.id
  subnet_id              = aws_subnet.scandiweb_instance_subnet.id
  private_ip             = var.varnish_private_ip # Assign a private ip to the instance (Hardcoded for now - needs to be changed)
  vpc_security_group_ids = [aws_security_group.scandiweb_sg.id]
  key_name               = aws_key_pair.scandiweb_auth.key_name
  user_data              = data.template_file.init.rendered

  # Copy the default.vcl file to the instance
  provisioner "file" {
    source      = "installation/varnish/"
    destination = "/home/ubuntu"
  }

  # Setup connection to the instance
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.servers_private_key_path)
    host        = self.public_ip
    timeout     = "4m"
  }

  root_block_device {
    volume_size = 10
  }

  tags = {
    Name = "scandiweb_stack_varnish"
  }
}

# Load Balancer Security Group (The method acts as a virtual firewall to control your inbound
# and outbound traffic flowing to your EC2 instances inside a subnet.)
resource "aws_security_group" "scandiweb_lb_sg" {
  name_prefix = "scandiweb_load_balancer_security_group"
  description = "Security group for the Scandiweb load balancer"
  vpc_id      = aws_vpc.scandiweb_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "scandiweb_load_balancer_security_group"
  }
}

# This resource group resources for use so that it can be associated with load balancers.
# This target group belongs to the magento2 instance
resource "aws_lb_target_group" "scandiweb_lb_target_group_magento2" {
  name        = "scandiweb-stack-lb-tg-magento2"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.scandiweb_vpc.id
  target_type = "instance"

  depends_on = [aws_security_group.scandiweb_lb_sg]

  health_check {
    path = "/health_check.php"
  }
}

# This target group belongs to the varnish instance
resource "aws_lb_target_group" "scandiweb_lb_target_group_varnish" {
  name        = "scandiweb-stack-lb-tg-varnish"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.scandiweb_vpc.id
  target_type = "instance"

  depends_on = [aws_security_group.scandiweb_lb_sg]

  health_check {
    path = "/health_check.php"
  }
}

# Register the magento2 instance with the target group
resource "aws_lb_target_group_attachment" "scandiweb_lb_target_group_attachment_magento2" {
  target_group_arn = aws_lb_target_group.scandiweb_lb_target_group_magento2.arn
  target_id        = aws_instance.scandiweb_magento2.id
  port             = 80
  depends_on       = [aws_lb_target_group.scandiweb_lb_target_group_magento2]
}

# Register the varnish instance with the target group
resource "aws_lb_target_group_attachment" "scandiweb_lb_target_group_attachment_varnish" {
  target_group_arn = aws_lb_target_group.scandiweb_lb_target_group_varnish.arn
  target_id        = aws_instance.scandiweb_varnish.id
  port             = 80
  depends_on       = [aws_lb_target_group.scandiweb_lb_target_group_varnish]
}

# This resource is used to create a load balancer that helps us distribute our traffic.
resource "aws_lb" "scandiweb_lb" {
  name               = "scandiweb-stack-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.scandiweb_lb_sg.id]
  subnets            = data.aws_subnet_ids.GetSubnet_Ids.ids

  enable_deletion_protection = false

  tags = {
    Name = "scandiweb_stack_lb"
  }
}

# tls private key for the load balancer
resource "tls_private_key" "private_key" {
  algorithm = "RSA"
}

# acme register for the load balancer based on dns challenge
resource "acme_registration" "cert_registration" {
  account_key_pem = tls_private_key.private_key.private_key_pem
  email_address   = var.acme_registration_email
}

# acme certificate for the load balancer created by the acme register
resource "acme_certificate" "scandiweb_acm_cert" {
  account_key_pem           = acme_registration.cert_registration.account_key_pem
  common_name               = "www.nowruz.me"
  subject_alternative_names = ["www2.nowruz.me", "nowruz.me"]
  recursive_nameservers = ["8.8.8.8:53", "1.1.1.1:53"]
  depends_on                = [acme_registration.cert_registration]

  dns_challenge {
    provider = "route53"
    config = {
      shared_credentials_files = "~/.aws/credentials"
      AWS_REGION            = var.aws_region
      AWS_HOSTED_ZONE_ID    = data.aws_route53_zone.scandiweb_zone.zone_id
    }
  }
}

# acm certificate for the load balancer (save it in the aws)
resource "aws_acm_certificate" "scandiweb_certificate" {
  certificate_body = acme_certificate.scandiweb_acm_cert.certificate_pem
  private_key      = acme_certificate.scandiweb_acm_cert.private_key_pem
  certificate_chain = acme_certificate.scandiweb_acm_cert.issuer_pem
}

# Create a listener (http) for the load balancer to redirect to https (ssl)
resource "aws_lb_listener" "scandiweb_lb_http_listener" {
  load_balancer_arn = aws_lb.scandiweb_lb.arn
  port             = "80"
  protocol         = "HTTP"

  default_action {
    type             = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# Create a listener (ssl) for the load balancer to forward the traffic to the varnish instance
resource "aws_lb_listener" "scandiweb_lb_https_listener" {
  load_balancer_arn = aws_lb.scandiweb_lb.arn
  port             = "443"
  protocol         = "HTTPS"
  ssl_policy = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn = aws_acm_certificate.scandiweb_certificate.arn
  

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.scandiweb_lb_target_group_varnish.arn
  }
}

# Attach certificate to the listener
resource "aws_lb_listener_certificate" "scandiweb_lb_listener_certificate" {
  listener_arn    = aws_lb_listener.scandiweb_lb_https_listener.arn
  certificate_arn = aws_acm_certificate.scandiweb_certificate.arn
}

# Create a rule for the listener to forward the traffic to the magento2 instance
resource "aws_lb_listener_rule" "scandiweb_lb_listener_rule_magento2" {
  listener_arn = aws_lb_listener.scandiweb_lb_https_listener.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.scandiweb_lb_target_group_magento2.arn
  }

  condition {
    path_pattern {
      values = ["/media/*", "/static/*"]
    }
  }
}

# Create a resource for domain record which will be used to point to the load balancer
resource "aws_route53_record" "scandiweb_record" {
  zone_id = data.aws_route53_zone.scandiweb_zone.zone_id
  name    = data.aws_route53_zone.scandiweb_zone.name
  type    = "A"

  alias {
    name                   = aws_lb.scandiweb_lb.dns_name
    zone_id                = aws_lb.scandiweb_lb.zone_id
    evaluate_target_health = false
  }
}
