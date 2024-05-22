data "aws_ami" "main" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "architecture"
    values = [var.architecture]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*"]
  }
}

resource "aws_launch_template" "main" {
  name          = var.name
  image_id      = data.aws_ami.main.id
  instance_type = var.instance_type

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = var.ebs_root_volume_size
      volume_type = "gp3"
    }
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.main.name
  }

  user_data = data.cloudinit_config.main.rendered



  network_interfaces {
    description = "${var.name} ephemeral network interface"
    subnet_id   = var.subnet_id
    #checkov:skip=CKV_AWS_88:Public IP required for direct tailscale connections
    associate_public_ip_address = true
    security_groups             = [aws_security_group.main.id]
  }

  dynamic "tag_specifications" {
    for_each = ["instance", "network-interface", "volume"]

    content {
      resource_type = tag_specifications.value

      tags = merge(var.tags, {
        Name = var.name
      })
    }
  }

  # Enforce IMDSv2
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = var.tags
}
