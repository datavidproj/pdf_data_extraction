variable "bucket_name" {
  type    = string
  default = "datavid-pdfconverter"
}

variable "sqs_queue_name" {
  type    = string
  default = "PDFPageInfo"
}

variable "batch_size" {
  type    = number
  default = 1
}

variable "AWS_REGION" {
  type      = string
  default   = "us-east-2"
}

variable "repo_name_pdf_splitter" {
  type    = string
  default = "pdf_splitter"
}

variable "repo_name_page_extractor" {
  type    = string
  default = "page_extractor"
}

variable "source_pdf_key_prefix" {
  type    = string
  default = "project/data/documents/"
}

variable "target_key_prefix" {
  type    = string
  default = "project/data/json/"
}

variable "target_img_key_prefix" {
  type    = string
  default = "project/data/imgpages/"
}

variable "bbox_images_key_prefix" {
  type    = string
  default = "project/data/bbox_images/"
}

variable "masked_images_key_prefix" {
  type    = string
  default = "project/data/masked_images/"
}

variable "table_corners_key_prefix" {
  type    = string
  default = "project/data/table_corners/"
}

variable "AWS_ACCOUNT_ID" {
  type    = string
  default = "093487613626"
}

#variable "key_storage_bucket" {
#  type    = string
#  default = "datavid-test-docdb"
#
#}
#
variable "public_subnet_numbers" {
  type = map(number)

  description = "Map of AZ to a number that should be used for public subnets"

  default = {
    "us-east-2a" = 1
    "us-east-2b" = 2
  }
}

#variable "private_subnet_numbers" {
#  type = map(number)
#
#  description = "Map of AZ to a number that should be used for private subnets"
#
#  default = {
#    "us-east-2a" = 2
#  }
#}

#variable "availability_zone" {
#    type    = string
#    default = "us-east-2a"
#}
#
#variable "availability_zone_names" {
#    type    = list(string)
#    default = ["us-east-2a", "us-east-2b"]
#}

variable "ec2_instance_type_name" {
  type    = string
  default = "t3.nano"
}

variable "key_name" {
  type    = string
  default = "datavid-key.pem"
}

variable "key_prefix" {
  type    = string
  default = "private_key/"
}

variable "vpc_cidr" {
  type        = string
  description = "The IP range to use for the VPC"
  default     = "10.18.0.0/16"
}

variable "subnet_cidr" {
  type        = string
  description = "The IP range to use for the VPC"
  default     = "10.18.0.0/20"
}

variable "server_name" {
  type    = string
  default = "datavid-tunneling-server"
}

variable "docdb_instance_class_name" {
  type    = string
  default = "db.t3.medium"
}

variable "docdb_cluster_username" {
  type = string
}

variable "docdb_cluster_password" {
  type = string
}

variable "docdb_cluster_id" {
  type    = string
  default = "docdb-cluster-demo"
}

variable "lambda_name_pdf_splitter" {
  type    = string
  default = "pdf_splitter"
}

variable "lambda_name_page_extractor" {
  type    = string
  default = "page_extractor"
}
