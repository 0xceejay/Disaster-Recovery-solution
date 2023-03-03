# Create vpc for both regions
resource "aws_vpc" "east-vpc" {
  provider = aws.east
  cidr_block = var.cidr_block
  tags = {
    Name = "east-vpc"
  }
}

resource "aws_vpc" "west-vpc" {
  provider = aws.west
  cidr_block = var.cidr_block
  tags = {
    Name = "west-vpc"
  }
}


# Create vpc peering connection and vpc peering connection accepter
resource "aws_vpc_peering_connection" "peering" {
  provider = aws.east
  peer_vpc_id = aws_vpc.east-vpc.id
  vpc_id = aws_vpc.west-vpc.id
  auto_accept = false
  tags = {
    Name = "my-vpc-peering-connection"
  }
}

resource "aws_vpc_peering_connection_accepter" "accept-peering" {
  provider = aws.west
  vpc_peering_connection_id = aws_vpc_peering_connection.peering.id
  auto_accept = true
  tags = {
    Side = "Accepter"
  }
}


# Target group
resource "aws_alb_target_group" "target_group" {
  provider = aws.east
  name = "my-target-group"
  port = 80
  protocol = "HTTP"
  target_type = "instance"
  vpc_id = aws_vpc.east-vpc.id
}

# Certificate
resource "aws_acm_certificate" "certificate" {
  provider = aws.east
  domain_name = "ceejay.online"
  validation_method = "DNS"
}

# Application load balancer
resource "aws_lb" "alb" {
  provider = aws.east
  load_balancer_type = "application"

}

# SSL policy
resource "aws_lb_ssl_negotiation_policy" "ssl_policy" {
  provider = aws.east
  name = "ssl_policy"
  load_balancer = aws_lb.alb.id
  lb_port = 443
}

# Load Balancer Listener
resource "aws_lb_listener" "listener" {
  provider = aws.east
  load_balancer_arn = aws_lb.alb.arn
  port = "443"
  protocol = "HTTPS"
  ssl_policy = aws_lb_ssl_negotiation_policy.ssl_policy.name
  certificate_arn = aws_acm_certificate.certificate.arn
  default_action {
    type = "forward"
    target_group_arn = aws_alb_target_group.target_group.arn
  }
}

# Autoscaling group
resource "aws_autoscaling_group" "asg" {
  provider = aws.east
  min_size = 2
  max_size = 4
  launch_configuration = aws_launch_configuration.launch-config.name
  availability_zones = ["us-east-1a", "us-east-1b"]
}

resource "aws_autoscaling_attachment" "asg-attachment" {
  provider = aws.east
  autoscaling_group_name = aws_autoscaling_group.asg.name
  alb_target_group_arn = aws_alb_target_group.target_group.arn
}

resource "aws_autoscaling_policy" "autoscale_policy" {
  provider = aws.east
  autoscaling_group_name = aws_autoscaling_group.asg.name
  name = autoscale_policy
  adjustment_type = "ExactCapacity"
  policy_type = "PredictiveScaling"
  cooldown = 300

  
  
}

# Launch configuration
resource "aws_launch_configuration" "launch-config" {
  provider = aws.east
  instance_type = "t2.micro"
  key_name = "project"
}



# SNS topic for notifications
resource "aws_sns_topic" "my_topic" {
  provider = aws.east
  name = "my-topic"
}

resource "aws_sns_topic_subscription" "subscription" {
  provider = aws.east
  topic_arn = aws_sns_topic.my_topic.arn
  protocol = "email"
  endpoint = "0xceejay@gmail.com"
}

resource "aws_autoscaling_notification" "notif" {
  provider = aws.east
  group_names = [ "my-topic" ]
  topic_arn = aws_sns_topic.my_topic.arn
  notifications = [ 
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR", 
    ]
}