#data "aws_ecr_image" "page_extractor" {
#  repository_name = var.repo_name_page_extractor
#  image_tag       = "latest"
#}
data "aws_ecr_repository" "page_extractor" {
    name = var.repo_name_page_extractor
}

#data "aws_sqs_queue" "pdf_page_info" {
#  name = var.sqs_queue_name
#}

resource "aws_lambda_function" "page_extractor" {
  function_name    = "page_extractor"
  package_type     = "Image"
#  image_uri        = data.aws_ecr_image.page_extractor.id
  image_uri        = "${data.aws_ecr_repository.page_extractor.repository_url}:latest"
  role             = aws_iam_role.page_extractor.arn
  memory_size      = 10240
  timeout          = 900

  environment {
    variables = {
      S3_BUCKET = "datavid-pdfconverter"
      BATCH_SIZE=var.batch_size
      TARGET_KEY_PREFIX=var.target_key_prefix
      TEMP_KEY_PREFIX=var.bbox_images_key_prefix
      MASKED_KEY_PREFIX=var.masked_images_key_prefix
      TABLE_CORNERS_KEY_PREFIX=var.table_corners_key_prefix
      SQS_QUEUE_URL=aws_sqs_queue.pdf_page_info.url
    }
  }
}

resource "aws_iam_role" "page_extractor" {
  name = "page_extractor_lambda_role"

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

resource "aws_iam_role_policy_attachment" "page_extractor_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.page_extractor.name
}

