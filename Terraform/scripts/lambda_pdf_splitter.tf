data "aws_s3_bucket" "datavid-pdfconverter" {
    bucket  = "datavid-pdfconverter"
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
  function_name    = var.lambda_name_pdf_splitter
  package_type     = "Image"
  image_uri        = "${data.aws_ecr_repository.pdf_splitter.repository_url}:latest"
  role             = aws_iam_role.pdf_splitter.arn
  memory_size      = 10240
  timeout          = 900

  environment {
    variables = {
      S3_BUCKET = data.aws_s3_bucket.datavid-pdfconverter.id
      SQS_QUEUE_URL = aws_sqs_queue.pdf_page_info.url
      TARGET_IMG_KEY_PREFIX=var.target_img_key_prefix
    }
  }
}

resource "aws_iam_role" "pdf_splitter" {
  name = "pdf_splitter_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "pdf_splitter_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.pdf_splitter.name
}

resource "aws_lambda_permission" "pdf_splitter" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.pdf_splitter.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.datavid-pdfconverter.arn
}


resource "aws_s3_bucket_notification" "pdf_splitter_s3_bucket_notification" {
#  bucket = "datavid-pdfconverter"
  bucket = data.aws_s3_bucket.datavid-pdfconverter.id
  depends_on   = ["${aws_lambda_function.pdf_splitter.id}", "${aws_s3_bucket.datavid-pdfconverter.id}"]

  lambda_function {
    lambda_function_arn = aws_lambda_function.pdf_splitter.arn
    events              = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
    filter_prefix       = var.source_pdf_key_prefix
  }
}

resource "aws_sqs_queue_policy" "pdf_splitter_sqs_queue_policy" {
  queue_url = aws_sqs_queue.pdf_page_info.url

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid = "AllowLambdaToWriteToQueue",
        Effect = "Allow",
        Principal = {
          AWS = aws_lambda_function.pdf_splitter.arn
        },
        Action = "sqs:SendMessage",
        Resource = aws_sqs_queue.pdf_page_info.arn
      }
    ]
  })
}

#resource "aws_iam_role_policy_attachment" "pdf_splitter_policy_attachment" {
#  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
#  role       = aws_iam_role.pdf_splitter.name
#
#  policy {
#    policy_json = jsonencode({
#      Version = "2012-10-17"
#      Statement = [
#        {
#          Effect = "Allow"
#          Action = [
#            "s3:GetObject",
#            "s3:PutObject"
#          ]
#          Resource = [
#            concat("${aws_s3_bucket.datavid-pdfconverter.arn}", "/", var.target_pdf_key_prefix, "/*"),
#            concat("${aws_s3_bucket.datavid-pdfconverter.arn}", "/", var.target_ing_key_prefix, "/*")
#          ]
#        }
#      ]
#    })
#  }
#}

