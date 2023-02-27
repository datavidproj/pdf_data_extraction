data "aws_s3_bucket" "datavid_pdfconverter" {
  bucket = "datavid-pdfconverter"
}

resource "aws_s3_object" "project_source_data" {
  bucket = data.aws_s3_bucket.datavid_pdfconverter.id
  key    = var.source_pdf_key_prefix
  acl    = "private"
}

resource "aws_s3_object" "project_data_masked_images" {
  bucket = data.aws_s3_bucket.datavid_pdfconverter.id
  key    = var.masked_images_key_prefix
  acl    = "private"
}

resource "aws_s3_object" "project_data_opensearch_data" {
  bucket = data.aws_s3_bucket.datavid_pdfconverter.id
  key    = var.target_key_prefix
  acl    = "private"
}

resource "aws_s3_object" "project_data_table_corners" {
  bucket = data.aws_s3_bucket.datavid_pdfconverter.id
  key    = var.table_corners_key_prefix
  acl    = "private"
}

resource "aws_s3_object" "project_data_bbox_images" {
  bucket = data.aws_s3_bucket.datavid_pdfconverter.id
  key    = var.bbox_images_key_prefix
  acl    = "private"
}
