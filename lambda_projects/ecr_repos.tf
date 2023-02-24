# Create ECR repository
resource "aws_ecr_repository" "pdf_splitter" {
  name = "pdf_splitter"
}

# Add tags to the Docker image
#resource "aws_ecr_image" "pdf_splitter" {
#  repository_name = aws_ecr_repository.pdf_splitter.name
#  image_tag = "latest"
#}

resource "aws_ecr_repository" "page_extractor" {
  name = "page_extractor"
}

# Add tags to the Docker image
#resource "aws_ecr_image" "page_extractor" {
#  repository_name = aws_ecr_repository.page_extractor.name
#  image_tag = "latest"
#}
