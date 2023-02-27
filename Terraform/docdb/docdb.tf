#data "aws_subnet" "public" {
#  filter {
#    name   = "tag:name"
#    values = [var.public_subnet_name]
#  }
#}
#
#data "aws_subnet" "private" {
#  filter {
#    name   = "tag:name"
#    values = [var.private_subnet_name]
#  }
#}
#
#data "aws_security_group" "tunnelling_sg" {
#    name    = var.tunnelling_sg_name
#}
#
#data "aws_vpc" "datavid-pdf-extractor" {
#    name    = var.datavid-pdf-extractor
#}

resource "aws_docdb_subnet_group" "datavid-pdf-extractor" {
  name        = var.subnet_group_docdb
  subnet_ids  = [aws_subnet.public.id, aws_subnet.private.id]
}

resource "aws_security_group" "docdb_sg" {
  name        = var.docdb_sg
  description = "Security group for Amazon DocumentDB"
  vpc_id      = aws_vpc.datavid-pdf-extractor.id
  depends_on  = [aws_security_group.tunnelling_sg]

  ingress {
    from_port       = 27017
    to_port         = 27017
    protocol        = "tcp"
    security_groups = [aws_security_group.tunnelling_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  lifecycle {
    create_before_destroy = true
  }
}

#resource "aws_docdb_cluster_instance" "cluster_instances" {
#  count              = length(var.public_subnet_numbers)
#  identifier         = format("%s-%d", var.docdb_cluster_id, "${count.index}")
#  cluster_identifier = aws_docdb_cluster.datavid-pdf-extractor.id
#  instance_class     = var.docdb_instance_class_name
#}

resource "aws_docdb_cluster_instance" "cluster_instance_public" {
  identifier         = var.docdb_cluster_public_id
  cluster_identifier = aws_docdb_cluster.datavid-pdf-extractor.id
  instance_class     = var.docdb_instance_class_name
}

resource "aws_docdb_cluster_instance" "cluster_instance_private" {
  identifier         = var.docdb_cluster_private_id
  cluster_identifier = aws_docdb_cluster.datavid-pdf-extractor.id
  instance_class     = var.docdb_instance_class_name
}

resource "aws_docdb_cluster" "datavid-pdf-extractor" {
  cluster_identifier     = var.docdb_cluster_id
  availability_zones     = [var.availability_zone_public, var.availability_zone_private]
  master_username        = var.docdb_cluster_username
  master_password        = var.docdb_cluster_password
  skip_final_snapshot    = true
  deletion_protection    = false
  db_subnet_group_name   = aws_docdb_subnet_group.datavid-pdf-extractor.id
  vpc_security_group_ids = [aws_security_group.docdb_sg.id]
}

output "docdb_instance_id" {
  description = "ID of the DocDB Server instance"
  value       = [aws_docdb_cluster_instance.cluster_instance_public.id, aws_docdb_cluster_instance.cluster_instance_private.id]
}
