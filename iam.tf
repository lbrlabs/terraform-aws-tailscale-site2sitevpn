resource "aws_iam_instance_profile" "main" {
  name = var.name
  role = aws_iam_role.main.name

  tags = var.tags
}

data "aws_iam_policy_document" "main" {
  statement {
    sid    = "ManageNetworkInterface"
    effect = "Allow"
    actions = [
      "ec2:AttachNetworkInterface",
      "ec2:ModifyNetworkInterfaceAttribute",
      "ec2:ModifyInstanceAttribute",
    ]
    resources = [
      "*",
    ]
    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/Name"
      values   = [var.name]
    }
  }

  statement {
    sid = "GetParameter"
    effect = "Allow"
    actions = [
        "ssm:GetParameter"
    ]
    resources = [aws_ssm_parameter.tailnet_key.arn]
  }

  statement {
    sid = "ListParameters"
    effect = "Allow"
    actions = [
        "ssm:DescribeParameters"
    ]
    resources = ["*"]
  }

  dynamic "statement" {
    for_each = var.enable_aws_ssm ? ["x"] : []

    content {
      sid    = "SessionManager"
      effect = "Allow"
      actions = [
        "ssmmessages:CreateDataChannel",
        "ssmmessages:OpenDataChannel",
        "ssmmessages:CreateControlChannel",
        "ssmmessages:OpenControlChannel",
        "ssm:UpdateInstanceInformation",
      ]
      resources = [
        "*"
      ]
    }
  }
}

resource "aws_iam_role" "main" {
  name = var.name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ssm.amazonaws.com"
        }
      }
    ]
  })

  inline_policy {
    name   = "main"
    policy = data.aws_iam_policy_document.main.json
  }

  tags = var.tags
}