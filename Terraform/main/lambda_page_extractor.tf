data "aws_security_group" "docdb_sg" {
    name    = var.docdb_sg
}

data "aws_subnet" "private" {
    filter {
        name     = "tag:name"
        values   = [var.private_subnet_name]
    }
}

data "aws_ecr_repository" "page_extractor" {
  name  = var.repo_name_page_extractor
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
      S3_BUCKET                = var.bucket_name
      BATCH_SIZE               = var.batch_size
      TARGET_KEY_PREFIX        = var.target_key_prefix
      TEMP_KEY_PREFIX          = var.bbox_images_key_prefix
      MASKED_KEY_PREFIX        = var.masked_images_key_prefix
      TABLE_CORNERS_KEY_PREFIX = var.table_corners_key_prefix
      SQS_QUEUE_URL            = aws_sqs_queue.pdf_page_info.url
    }
  }
#  vpc_config {
#    security_group_ids = [data.aws_security_group.docdb_sg.id]
#    subnet_ids         = [data.aws_subnet.private.id]
##    subnet_ids         = values(aws_subnet.public)[*].id
#  }
}

#data "aws_iam_policy" "lambda_basic_execution_role_policy" {
#  name = "AWSLambdaBasicExecutionRole"
#}
#
#data "aws_iam_policy" "lambda_s3_full_access_role_policy" {
#  name = "AmazonS3FullAccess"
#}
#data "aws_iam_policy" "lambda_sqs_full_access_role_policy" {
#  name = "AmazonSQSFullAccess"
#}

#data "aws_subnet" "private" {
#   filter {
#        name    = "tag:name"
#        values  = [var.private_subnet_name]
#    } 
#}

data "aws_security_group" "docdb" {
    name    = "docdb_sg"
}

data "aws_vpc" "datavid-pdf-extractor" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

resource "aws_vpc_endpoint" "s3" {
    vpc_id              = data.aws_vpc.datavid-pdf-extractor.id
    service_name        = "com.amazonaws.${var.AWS_REGION}.s3"
    vpc_endpoint_type   = "Interface"
    subnet_ids          = [data.aws_subnet.private.id]
    security_group_ids  = [data.aws_security_group.docdb.id]
}

resource "aws_iam_role" "page_extractor" {
  name_prefix = "LambdaPageExtractorRole-"
  managed_policy_arns = [
    data.aws_iam_policy.lambda_basic_execution_role_policy.arn,
    data.aws_iam_policy.lambda_s3_full_access_role_policy.arn
#    data.aws_iam_policy.lambda_sqs_full_access_role_policy.arn
#    aws_iam_policy.lambda_policy.arn
  ]

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

resource "aws_iam_role_policy_attachment" "lambda_network_permissions" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"  # or another policy that grants permissions to DescribeNetworkInterfaces
  role       = "${aws_iam_role.page_extractor.name}"
}

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

output "s3_endpoint_id" {
  value = aws_vpc_endpoint.s3.id
}

