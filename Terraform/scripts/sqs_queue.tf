resource "aws_sqs_queue" "pdf_page_info" {
  name = "PDFPageInfo"
}

resource "aws_lambda_event_source_mapping" "page_extractor_sqs_mapping" {
  event_source_arn  = aws_sqs_queue.pdf_page_info_queue.arn
  function_name     = aws_lambda_function.page_extractor.arn
  batch_size        = 1
  starting_position = "TRIM_HORIZON"
}
