locals {
  http_port = 80
  any_port = 0
  any_protocol = "-1"
  tcp_protocol = "tcp"
  all_ips = ["0.0.0.0/0"]
}

data "terraform_remote_state" "db" {
  backend = "s3"

  config = {
    bucket = var.remote_state_bucket
    key = var.db_remote_state_key
    region = var.region
  }
}

data "aws_vpc" "default" {
    default = true
}

data "aws_subnets" "default" {
    filter {
        name = "vpc-id"
        values = [data.aws_vpc.default.id]
    }
}

resource "aws_security_group" "sg-for-ec2-instance" {
    name = "${var.cluster_name}-sg-for-ec2-instance"
    
    ingress {
        from_port = var.server_port
        to_port = var.server_port
        protocol = local.tcp_protocol
        cidr_blocks = local.all_ips
    }
}

resource "aws_launch_template" "launch-template" {
  name_prefix   = "${var.cluster_name}-"
  image_id      = "ami-0c1fe732b5494dc14"
  instance_type = var.instance_type

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.sg-for-ec2-instance.id]
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    db_address  = data.terraform_remote_state.db.outputs.address
    db_port     = data.terraform_remote_state.db.outputs.port
    server_port = var.server_port
  }))

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "asg" {
  name_prefix = "${var.cluster_name}-asg-"
  launch_template {
    id      = aws_launch_template.launch-template.id
    version = "$Latest"
  }
  vpc_zone_identifier = data.aws_subnets.default.ids
  target_group_arns = [aws_lb_target_group.alb-tg.arn]
  health_check_type = "ELB"
  health_check_grace_period = 120

  min_size = var.min_size
  max_size = var.max_size

  tag {
    key = "Name"
    value = "terraform-asg-example"
    propagate_at_launch = true
  }
}

resource "aws_lb" "alb" {
    name = "${var.cluster_name}-alb"
    load_balancer_type = "application"
    subnets = data.aws_subnets.default.ids
    security_groups = [aws_security_group.sg-for-alb.id]
}

resource "aws_lb_listener" "http" {
    load_balancer_arn = aws_lb.alb.arn
    port = local.http_port
    protocol = "HTTP"

    # By default, return a simple 404 page
    default_action {
        type = "fixed-response"

        fixed_response {
            content_type = "text/plain"
            message_body = "404: page not found"
            status_code = 404
        }
    }
}

resource "aws_security_group" "sg-for-alb" {
    name = "${var.cluster_name}-sg-for-alb"

    # Allow inbound HTTP requests
    ingress {
        from_port = local.http_port
        to_port = local.http_port
        protocol = local.tcp_protocol
        cidr_blocks = local.all_ips
    }

    # Allow all outbound requests
    egress {
        from_port = local.any_port
        to_port = local.any_port
        protocol = local.any_protocol
        cidr_blocks = local.all_ips
    }
}

resource "aws_lb_target_group" "alb-tg" {
    name = "${var.cluster_name}-alb-tg"
    port = var.server_port
    protocol = "HTTP"
    vpc_id = data.aws_vpc.default.id

    health_check {
        path = "/"
        protocol = "HTTP"
        matcher = "200"
        interval= 15
        timeout = 3
        healthy_threshold = 2
        unhealthy_threshold = 2
    }
}

resource "aws_lb_listener_rule" "alb_listener_rule" {
    listener_arn = aws_lb_listener.http.arn
    priority = 100

    condition {
        path_pattern {
          values = ["*"]
        }
    }

    action {
      type = "forward"
      target_group_arn = aws_lb_target_group.alb-tg.arn
    }
  
}
