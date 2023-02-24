terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 4.0"
        }
    }
    backend "s3" {
        bucket = "datavid-pdfconverter"
        key    = "terraform/ecr/terraform.tfstate"
        region = "us-east-2"
    }
}
