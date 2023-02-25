data "aws_ecr_repository" "page_extractor" {
  name = var.repo_name_page_extractor
}

resource "aws_lambda_function" "page_extractor" {
  function_name = "page_extractor"
  package_type  = "Image"
  #  image_uri        = data.aws_ecr_image.page_extractor.id
  image_uri = "${data.aws_ecr_repository.page_extractor.repository_url}:latest"
  role      = aws_iam_role.page_extractor.arn
  #role             = "${aws_iam_role.iam_for_lambda.arn}"
  memory_size = 10240
  timeout     = 900
  environment {
    variables = {
      S3_BUCKET                = "datavid-pdfconverter"
      BATCH_SIZE               = var.batch_size
      TARGET_KEY_PREFIX        = var.target_key_prefix
      TEMP_KEY_PREFIX          = var.bbox_images_key_prefix
      MASKED_KEY_PREFIX        = var.masked_images_key_prefix
      TABLE_CORNERS_KEY_PREFIX = var.table_corners_key_prefix
      SQS_QUEUE_URL            = aws_sqs_queue.pdf_page_info.url
    }
  }
  vpc_config {
    security_group_ids = [aws_security_group.docdb_sg.id]
#    subnet_ids         = [aws_subnet.public.id]
    subnet_ids         = values(aws_subnet.public)[*].id
  }
}

resource "aws_iam_role_policy_attachment" "lambda_network_permissions" {
#  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"  # or another policy that grants permissions to DescribeNetworkInterfaces
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"  # or another policy that grants permissions to DescribeNetworkInterfaces
#  role       = "${aws_lambda_function.page_extractor.role}"
  role       = "${aws_iam_role.page_extractor.name}"
}

resource "aws_iam_role" "page_extractor" {
  name = "iam_for_page_extractor"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

#resource "aws_iam_role" "docdb_lambda_role" {
#  name = "docdb_lambda_role"
#
#  assume_role_policy = jsonencode({
#    Version = "2012-10-17"
#    Statement = [
#      {
#        Action = "sts:AssumeRole",
#        Effect = "Allow",
#        Principal = {
#          Service = "lambda.amazonaws.com"
#        }
#      }
#    ]
#  })
#}

resource "aws_iam_policy" "docdb_policy" {
  name        = "docdb_policy"
  description = "Policy for accessing DocumentDB from Lambda"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Action    = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
        Resource  = ["arn:aws:logs:*:*:*"]
      },
      {
        Effect    = "Allow",
        Action    = ["docdb:Describe*", "docdb:List*", "docdb:Connect"],
        Resource  = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "docdb_lambda_policy_attachment" {
  policy_arn = aws_iam_policy.docdb_policy.arn
  role       = aws_iam_role.page_extractor.name
}

resource "aws_iam_policy" "lambda_eni_policy" {
  name        = "lambda-eni-policy"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeNetworkInterfaces",
          "ec2:CreateNetworkInterface",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeInstances",
          "ec2:AttachNetworkInterface"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_eni_attachment" {
  policy_arn = aws_iam_policy.lambda_eni_policy.arn
  role       = aws_iam_role.page_extractor.name
}

data "aws_iam_policy_document" "lambda_sqs_policy" {
  statement {
    effect = "Allow"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes"
    ]
    resources = [
      aws_sqs_queue.pdf_page_info.arn
    ]
  }
}

resource "aws_iam_role_policy_attachment" "lambda_sqs_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.page_extractor.name
}

resource "aws_iam_policy" "lambda_sqs_policy" {
  name        = "lambda-sqs-policy"
  policy      = data.aws_iam_policy_document.lambda_sqs_policy.json
  description = "Policy for allowing Lambda to receive messages from SQS"
}

resource "aws_iam_role_policy_attachment" "lambda_sqs_policy_attachment" {
  policy_arn = aws_iam_policy.lambda_sqs_policy.arn
  role       = aws_iam_role.page_extractor.name
}

