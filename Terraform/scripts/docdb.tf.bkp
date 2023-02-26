resource "aws_docdb_subnet_group" "datavid-pdf-extractor" {
  name        = "subnet_docdb"
  subnet_ids  = [for subnet in aws_subnet.public : subnet.id]
}

#resource "aws_security_group" "docdb_sg" {
#  name_prefix = "docdb_sg_"
#  description = "Security group for Amazon DocumentDB"
#  vpc_id      = aws_vpc.datavid-pdf-extractor.id
#
#  ingress {
#    from_port       = 27017
#    to_port         = 27017
#    protocol        = "tcp"
#    security_groups = [aws_security_group.tunneling_sg.id]
#  }
#
#  egress {
#    from_port   = 0
#    to_port     = 0
#    protocol    = "-1"
#    cidr_blocks = ["0.0.0.0/0"]
#  }
#}

resource "aws_docdb_cluster_instance" "cluster_instances" {
  count              = length(var.public_subnet_numbers)
  identifier         = format("%s-%d", var.docdb_cluster_id, "${count.index}")
  cluster_identifier = aws_docdb_cluster.datavid-pdf-extractor.id
  instance_class     = var.docdb_instance_class_name
}

resource "aws_docdb_cluster" "datavid-pdf-extractor" {
  cluster_identifier     = var.docdb_cluster_id
  availability_zones     = keys(var.public_subnet_numbers)
  master_username        = var.docdb_cluster_username
  master_password        = var.docdb_cluster_password
  skip_final_snapshot    = true
  deletion_protection    = false
  db_subnet_group_name   = aws_docdb_subnet_group.datavid-pdf-extractor.id
  vpc_security_group_ids = [aws_security_group.docdb_sg.id]
}

output "docdb_instance_id" {
  description = "ID of the DocDB Server instance"
  value       = [for instance in aws_docdb_cluster_instance.cluster_instances : instance.id]
}
