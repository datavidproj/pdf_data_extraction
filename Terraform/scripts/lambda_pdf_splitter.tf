data "aws_s3_bucket" "datavid-pdfconverter" {
  bucket = "datavid-pdfconverter"
}

#data "aws_ecr_image" "pdf_splitter" {
#  repository_name = var.repo_name_pdf_splitter
#  image_tag       = "latest"
#}

data "aws_ecr_repository" "pdf_splitter" {
  name = var.repo_name_pdf_splitter
}

#data "aws_sqs_queue" "pdf_page_info" {
#  name = var.sqs_queue_name
#}

resource "aws_lambda_function" "pdf_splitter" {
  function_name = var.lambda_name_pdf_splitter
  package_type  = "Image"
  image_uri     = "${data.aws_ecr_repository.pdf_splitter.repository_url}:latest"
  role          = aws_iam_role.pdf_splitter.arn
  memory_size   = 10240
  timeout       = 900

  environment {
    variables = {
      S3_BUCKET             = data.aws_s3_bucket.datavid-pdfconverter.id
      SQS_QUEUE_URL         = aws_sqs_queue.pdf_page_info.url
      TARGET_IMG_KEY_PREFIX = var.target_img_key_prefix
    }
  }
}

data "aws_iam_policy" "lambda_basic_execution_role_policy" {
  name = "AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role" "pdf_splitter_sqs" {
  name_prefix = "LambdaSQSRole-"
  managed_policy_arns = [
    data.aws_iam_policy.lambda_basic_execution_role_policy.arn,
    aws_iam_policy.lambda_policy.arn
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

resource "aws_iam_role" "pdf_splitter_s3" {
  name_prefix = "LambdaS3Role-"
  managed_policy_arns = [
    data.aws_iam_policy.lambda_basic_execution_role_policy.arn,
    aws_iam_policy.lambda_policy.arn
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

#resource "aws_iam_role" "pdf_splitter" {
#  name = "pdf_splitter_lambda_role"
#
#  assume_role_policy = jsonencode({
#    Version = "2012-10-17"
#    Statement = [
#      {
#        Action = "sts:AssumeRole"
#        Effect = "Allow"
#        Principal = {
#          Service = "lambda.amazonaws.com"
#        }
#      }
#    ]
#  })
#}

data "aws_iam_policy_document" "lambda_policy_document" {
  statement {

    effect = "Allow"

    actions = [
      "sqs:SendMessage*"
    ]

    resources = [
      aws_sqs_queue.pdf_page_info.arn
    ]
    #    condition {
    #      test     = "ArnEquals"
    #      variable = "aws:SourceArn"
    #      values   = [aws_lambda_function.pdf_splitter.arn]
    #    }
  }
}

resource "aws_iam_policy" "lambda_policy" {
  name_prefix = "lambda_policy"
  path        = "/"
  policy      = data.aws_iam_policy_document.lambda_policy_document.json
  #  lifecycle {
  #    create_before_destroy = true
  #  }
}

#resource "aws_iam_role_policy_attachment" "pdf_splitter_policy_attachment" {
#  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
#  role       = aws_iam_role.pdf_splitter.name
#}

resource "aws_lambda_permission" "pdf_splitter" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.pdf_splitter.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = data.aws_s3_bucket.datavid-pdfconverter.arn
}


resource "aws_s3_bucket_notification" "pdf_splitter_s3_bucket_notification" {
  bucket = "datavid-pdfconverter"
  #bucket     = data.aws_s3_bucket.datavid-pdfconverter.id
  depends_on = [aws_lambda_function.pdf_splitter]

  lambda_function {
    lambda_function_arn = aws_lambda_function.pdf_splitter.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = var.source_pdf_key_prefix
  }
}

#resource "aws_iam_policy" "s3_access_policy" {
#  name        = "s3-access-policy"
#  description = "Grants all access to a specific S3 bucket and object"
#
#  policy = jsonencode({
#    Version = "2012-10-17"
#    Statement = [
#      {
#        Effect   = "Allow"
#        Action   = [
#                "s3:*",
#                "s3-object-lambda:*"
#        ]
#        Resource = ["*"]
#      }
#    ]
#  })
#}
#
#resource "aws_iam_role_policy_attachment" "s3_policy_attachment" {
#  policy_arn = aws_iam_policy.s3_access_policy.arn
#  role       = aws_iam_role.pdf_splitter_s3.name
#}

#resource "aws_iam_policy" "s3_read_policy" {
#  name        = "s3-read-policy"
#  description = "Grants read access to a specific S3 bucket and object"
#
#  policy = jsonencode({
#    Version = "2012-10-17"
#    Statement = [
#      {
#        Effect   = "Allow"
#        Action   = [
#          "s3:GetObject"
#        ]
#        Resource = [
#          "arn:aws:s3:::${var.bucket_name}/${var.source_pdf_key_prefix}*"
#        ]
#      }
#    ]
#  })
#}
#
#resource "aws_iam_role_policy_attachment" "s3_read_attachment" {
#  policy_arn = aws_iam_policy.s3_read_policy.arn
##  role       = aws_iam_role.pdf_splitter.role
#  role       = aws_iam_role.pdf_splitter.name
#}
#
#resource "aws_iam_policy" "s3_write_policy_pdf_splitter" {
#  name        = "s3-write-policy"
#  description = "Grants read access to a specific S3 bucket and object"
#
#  policy = jsonencode({
#    Version = "2012-10-17"
#    Statement = [
#      {
#        Effect   = "Allow"
#        Action   = [
#          "s3:PutObject"
#        ]
#        Resource = [
#          "arn:aws:s3:::${var.bucket_name}/${var.target_img_key_prefix}*"
#        ]
#      }
#    ]
#  })
#}
#
#resource "aws_iam_role_policy_attachment" "s3_write_for_pdf_splitter" {
#  policy_arn = aws_iam_policy.s3_write_policy_pdf_splitter.arn
##  role       = aws_iam_role.pdf_splitter.role
#  role       = aws_iam_role.pdf_splitter.name
#}


#resource "null_resource" "delay_creation" {
#  provisioner "local-exec" {
#    command = "sleep 60"
#  }
#
#  depends_on   = [aws_lambda_function.pdf_splitter, aws_sqs_queue.pdf_page_info]
#}

#resource "aws_sqs_queue_policy" "pdf_splitter_sqs_queue_policy" {
#  queue_url = aws_sqs_queue.pdf_page_info.id
#  depends_on   = [aws_lambda_function.pdf_splitter, aws_sqs_queue.pdf_page_info]
#
#  policy = jsonencode({
#    Version = "2012-10-17",
#    Id      = "sqspolicy",
##    Id      = "AllowLambdaToWriteToQueue",
#    Statement = [
#      {
#        Sid = "AllowLambdaToWriteToQueue",
#        Effect = "Allow",
#        Principal = {
#          AWS = aws_lambda_function.pdf_splitter.arn
#        },
#        Action = [
#            "sqs:SendMessage"
#        ],
#        Resource = aws_sqs_queue.pdf_page_info.arn
#      }
#    ]
#  })
#}

resource "aws_iam_role_policy_attachment" "pdf_splitter_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.pdf_splitter_s3.name

  policy {
    policy_json = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "s3:GetObject",
            "s3:PutObject"
          ]
          Resource = [
            "${data.aws_s3_bucket.datavid-pdfconverter.arn}/${var.target_ing_key_prefix}*"
          ]
        }
      ]
    })
  }
}

