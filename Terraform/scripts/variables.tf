variable "bucket_name" {
    type    = string
    default = "datavid-pdfconverter"
}

variable "sqs_queue_name" {
    type    = string
    default = "PDFPageInfo"
}

variable "batch_size" {
    type    = integer
    default = 1
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
    default = "project/data/documents"
}

variable "target_key_prefix" {
    type    = string
    default = "project/data/opensearch"
}

variable "target_img_key_prefix" {
    type    = string
    default = "project/data/imgpages"
}

variable "bbox_images_key_prefix" {
    type    = string
    default = "project/data/bbox_images"
}

variable "masked_images_key_prefix" {
    type    = string
    default = "project/data/masked_images"
}

variable "table_corners_key_prefix" {
    type    = string
    default = "project/data/table_corners"
}
