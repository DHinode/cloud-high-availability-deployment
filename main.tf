terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "eu-west-3"
}


resource "aws_s3_bucket" "example" {
  bucket = "volume1-persistant-memory-storage"
  force_destroy = true
}

resource "aws_s3_object" "aws_storage" {
  bucket = aws_s3_bucket.example.id
  key = "index.html"
  source = "./assets/cuisine_du_poulet_site_interactif_aws_ready.html"
}

data "aws_iam_policy_document" "assume_ec2" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_role" {
  name               = "ec2-s3-read-role"
  assume_role_policy = data.aws_iam_policy_document.assume_ec2.json
}

data "aws_iam_policy_document" "s3_read" {
  statement {
    sid     = "AllowReadSiteBucket"
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.example.arn,
      "${aws_s3_bucket.example.arn}/*"
    ]
  }
}


resource "aws_iam_policy" "s3_read" {
  name   = "ec2-s3-read-policy"
  policy = data.aws_iam_policy_document.s3_read.json
}

resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.s3_read.arn
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-s3-read-profile"
  role = aws_iam_role.ec2_role.name
}


### SG 

resource "aws_security_group" "web" {
  name        = "web-allow-http"
  description = "Allow HTTP"
  # Par défaut dans le VPC par défaut (si tu n'as pas créé de VPC custom)

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Notre ami ubuntu le best

data "aws_ami" "al2023" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}


# EC2

resource "aws_instance" "web" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = "t3.micro"
  vpc_security_group_ids      = [aws_security_group.web.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = true

  user_data = <<-EOF
#!/bin/bash
echo "<h1>test</h1>" > /index.html # CORRECTION 1: Ajout du chemin complet et guillemet
 
apt update -y
apt install -y nginx awscli nyancat

systemctl enable --now nginx

# Petit délai pour s'assurer que les services sont prêts
sleep 10

# Téléchargement depuis S3 (vers l'emplacement par défaut de NGINX sur Ubuntu)
for i in {1..10}; do
  if aws s3 cp "s3://volume1-persistant-memory-storage/index.html" "/var/www/html/index.html"; then
    echo "Fichier S3 téléchargé avec succès"
    break
  fi
  echo "Tentative $i: Échec du téléchargement S3. Réessai dans 5 secondes."
  sleep 5
done

# Le propriétaire du fichier par défaut est root. NGINX sous Ubuntu utilise 'www-data'.
# /var/www/html est l'emplacement correct pour l'index par défaut sur Ubuntu avec NGINX.
chown www-data:www-data "/var/www/html/index.html"
systemctl restart nginx
EOF

  tags = {
    Name = "s3-backed-web"
  }

  depends_on = [aws_s3_object.aws_storage, aws_iam_role_policy_attachment.attach]
}

output "ec2_public_ip" {
  value = aws_instance.web.public_ip
}

output "site_url" {
  value = "http://${aws_instance.web.public_ip}"
}