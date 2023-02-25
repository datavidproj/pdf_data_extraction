resource "aws_sqs_queue" "pdf_page_info" {
  name = "PDFPageInfo"
  visibility_timeout_seconds = 900
}

resource "aws_lambda_event_source_mapping" "page_extractor_sqs_mapping" {
  event_source_arn  = aws_sqs_queue.pdf_page_info.arn
  function_name     = aws_lambda_function.page_extractor.arn
}

#data "aws_iam_policy_document" "sqs_queue_policy" {
#  statement {
#    effect  = "Allow"
#    actions = ["sqs:SendMessage"]
#    resources = [aws_sqs_queue.pdf_page_info.arn]
#
#    condition {
#      test     = "ArnEquals"
#      variable = "aws:SourceArn"
#      values   = [aws_lambda_function.pdf_splitter.arn]
#    }
#  }
#}
#  starting_position = "LATEST"
