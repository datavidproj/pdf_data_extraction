resource "aws_vpc" "datavid-pdf-extractor" {
  cidr_block = var.vpc_cidr
}

resource "aws_internet_gateway" "datavid-pdf-extractor" {
  vpc_id = aws_vpc.datavid-pdf-extractor.id
}

# Create 1 public subnets for each AZ within the regional VPC
resource "aws_subnet" "public" {
  for_each                  = var.public_subnet_numbers
  vpc_id                    = aws_vpc.datavid-pdf-extractor.id
  availability_zone         = each.key
  # 2,048 IP addresses each
  cidr_block                = cidrsubnet(aws_vpc.datavid-pdf-extractor.cidr_block, 4, each.value)
  map_public_ip_on_launch   = true

}

resource "random_id" "sg_suffix" {
  byte_length = 4
}

# TODO: this should be in docdb.tf
resource "aws_security_group" "docdb_sg" {
#  name_prefix = "docdb_sg_"
#  name_suffix = random_id.sg_suffix.hex
  name        = "docdb_sg_${random_id.sg_suffix.hex}"
  description = "Security group for Amazon DocumentDB"
  vpc_id      = aws_vpc.datavid-pdf-extractor.id
  depends_on  = [aws_security_group.tunneling_sg]

  ingress {
    from_port       = 27017
    to_port         = 27017
    protocol        = "tcp"
    security_groups = [aws_security_group.tunneling_sg.id]
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

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.datavid-pdf-extractor.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.datavid-pdf-extractor.id
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.datavid-pdf-extractor.id
  service_name = "com.amazonaws.${var.AWS_REGION}.s3"

#  route_table_ids = [aws_vpc.vpc.main_route_table_id]
  route_table_ids = [aws_route_table.public.id]
}

#resource "aws_route_table_association" "public" {
#  subnet_id      = values(aws_subnet.public)[0].id
#  route_table_id = aws_route_table.public.id
#}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

data "aws_ami" "amazon_2" {
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-*-hvm-*-x86_64-gp2"]
  }
  owners = ["amazon"]
}

data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

resource "aws_security_group" "tunneling_sg" {
  vpc_id      = aws_vpc.datavid-pdf-extractor.id
  name        = "public_subnet"
  description = "Connect Public Subnet"

  ingress {
    cidr_blocks = ["${chomp(data.http.myip.response_body)}/32"]
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
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

resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_s3_object" "file" {
  key     = "${var.key_prefix}${var.key_name}"
  bucket  = var.bucket_name
  content = tls_private_key.pk.private_key_pem
}

resource "aws_key_pair" "kp" {
  key_name   = trimsuffix("${var.key_name}", ".pem")
  public_key = tls_private_key.pk.public_key_openssh
  provisioner "local-exec" {
    command = "echo '${tls_private_key.pk.private_key_pem}' > ./${var.key_name}"
  }
}

resource "aws_instance" "datavid-pdf-extractor" {
  vpc_security_group_ids        = ["${aws_security_group.tunneling_sg.id}"]
  subnet_id                     = values(aws_subnet.public)[0].id
  ami                           = data.aws_ami.amazon_2.id
  instance_type                 = var.ec2_instance_type_name
  key_name                      = trimsuffix("${var.key_name}", ".pem")
  associate_public_ip_address   = true

  tags = {
    Name = "${var.server_name}"
  }
}

output "instance_id" {
  description = "ID of the Server instance"
  value       = aws_instance.datavid-pdf-extractor.id
}

output "instance_public_ip" {
  description = "Public IP address of the Server instance"
  value       = aws_instance.datavid-pdf-extractor.public_ip
}

