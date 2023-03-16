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

# Create a private subnet for the EC2 instances
resource "aws_subnet" "scandiweb_private_subnet" {
  vpc_id            = aws_vpc.scandiweb_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-central-1a"

  tags = {
    Name = "scandiweb_stack_private_subnet"
    Type = "private"
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

# Create association between subnet and route table which will allow to access the internet
resource "aws_route_table_association" "scandiweb_rtassoc1" {
  subnet_id      = aws_subnet.scandiweb_public_subnet1.id
  route_table_id = aws_route_table.scandiweb_route_table.id
}
resource "aws_route_table_association" "scandiweb_rtassoc2" {
  subnet_id      = aws_subnet.scandiweb_public_subnet2.id
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
  public_key = file("~/.ssh/terratest.pub")
}

# Create a magento2 instance
resource "aws_instance" "scandiweb_magento2" {
  instance_type          = "t2.medium"
  ami                    = data.aws_ami.server_ami_ubuntu_22.id
  subnet_id              = aws_subnet.scandiweb_private_subnet.id
  vpc_security_group_ids = [aws_security_group.scandiweb_sg.id]
  key_name               = aws_key_pair.scandiweb_auth.key_name
#   user_data              = file("magento2.sh")s

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
  subnet_id              = aws_subnet.scandiweb_private_subnet.id
  vpc_security_group_ids = [aws_security_group.scandiweb_sg.id]
  key_name               = aws_key_pair.scandiweb_auth.key_name
#   user_data              = file("varnish.sh")

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
resource "aws_lb_target_group" "scandiweb_lb_target_group" {
  name        = "scandiweb-stack-lb-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.scandiweb_vpc.id
  target_type = "instance"

  depends_on = [aws_security_group.scandiweb_lb_sg]

  #   health_check {
  #     path = "/"
  #   }
}

# This resource provides us the ability to register containers and instances with load balancers
resource "aws_lb_target_group_attachment" "scandiweb_lb_target_group_attachment" {
  count            = length(data.aws_instances.ec2_list.ids)
  target_group_arn = aws_lb_target_group.scandiweb_lb_target_group.arn
  target_id        = data.aws_instances.ec2_list.ids[count.index]
  port             = 80
  depends_on       = [aws_lb_target_group.scandiweb_lb_target_group]
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

# This resource is used to create a listener for the load balancer.
resource "aws_lb_listener" "scandiweb_lb_listener" {
  load_balancer_arn = aws_lb.scandiweb_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.scandiweb_lb_target_group.arn
  }

  depends_on = [aws_lb_target_group_attachment.scandiweb_lb_target_group_attachment]
}


# Create a rule for the listener to forward the traffic to the magento2 instance
resource "aws_lb_listener_rule" "scandiweb_lb_listener_rule_magento2" {
  listener_arn = aws_lb_listener.scandiweb_lb_listener.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.scandiweb_lb_target_group.arn
  }

  condition {
    path_pattern {
       values = ["/media/*", "/static/*"]
    }
  }
}

# Create a rule for the listener to forward the traffic to the varnish instance
resource "aws_lb_listener_rule" "scandiweb_lb_listener_rule" {
  listener_arn = aws_lb_listener.scandiweb_lb_listener.arn
  priority     = 101

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.scandiweb_lb_target_group.arn
  }

  condition {
    path_pattern {
       values = ["/*"]
    }
  }
}




# Create a load balancer
# The entry point to the infrastructure will be AWS load-balancer, which will be terminating SSL and taking care of correct routing.
# The load-balancer will be placed in the public subnet and will have a public IP address.
# The load-balancer will be configured to forward all traffic to the private subnet where the EC2 instances will be placed.
# The load-balancer will send all the requests of /media/* and /static/* to the magento2 instance directly and the rest of the requests will be forwarded to the varnish instance.
# The load-balancer will be configured to use the health checks to check the status of the varnish instance and the magento2 instance.


# # Create a listener for the load balancer
# resource "aws_lb_listener" "scandiweb_lb_listener" {
#   load_balancer_arn = aws_lb.scandiweb_lb.arn
#   port              = "443"
#   protocol          = "HTTPS"

#   default_action {
#     target_group_arn = aws_lb_target_group.scandiweb_varnish_tg.arn
#     type             = "forward"
#   }

#   certificate_arn = "arn:aws:acm:eu-central-1:000000000000:certificate/00000000-0000-0000-0000-000000000000"

#   depends_on = [
#     aws_lb_target_group.scandiweb_varnish_tg,
#     aws_lb_target_group.scandiweb_magento2_tg
#   ]
# }

# Create a rule for the listener
# resource "aws_lb_listener_rule" "scandiweb_lb_listener_rule" {
#   listener_arn = aws_lb_listener.scandiweb_lb_listener.arn
#   priority     = 1

#   action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.scandiweb_magento2_tg.arn
#   }

#   condition {
#     field  = "path-pattern"
#     values = ["/media/*", "/static/*"]
#   }
# }

# # Create a listener