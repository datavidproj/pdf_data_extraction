data "aws_s3_bucket" "datavid_pdfconverter" {
  bucket = "datavid-pdfconverter"
}
resource "aws_s3_bucket_object" "project_data_masked_images" {
  bucket = data.aws_s3_bucket.datavid_pdfconverter.id
  key    = "project/data/masked_images/"
  acl    = "private"
}

resource "aws_s3_bucket_object" "project_data_opensearch_data" {
  bucket = data.aws_s3_bucket.datavid_pdfconverter.id
  key    = "project/data/opensearch_data/"
  acl    = "private"
}

resource "aws_s3_bucket_object" "project_data_table_corners" {
  bucket = data.aws_s3_bucket.datavid_pdfconverter.id
  key    = "project/data/table_corners/"
  acl    = "private"
}

resource "aws_s3_bucket_object" "project_data_bbox_images" {
  bucket = data.aws_s3_bucket.datavid_pdfconverter.id
  key    = "project/data/bbox_images/"
  acl    = "private"
}
