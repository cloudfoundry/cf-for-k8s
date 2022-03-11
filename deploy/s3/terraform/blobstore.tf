resource "aws_s3_bucket" "packages" {
  bucket        = "cc-packages-${var.bucket_suffix}"
  force_destroy = true
}

resource "aws_s3_bucket_acl" "packages" {
  bucket = aws_s3_bucket.packages.id
  acl    = "private"
}

resource "aws_s3_bucket" "droplets" {
  bucket        = "cc-droplets-${var.bucket_suffix}"
  force_destroy = true
}

resource "aws_s3_bucket_acl" "droplets" {
  bucket = aws_s3_bucket.droplets.id
  acl    = "private"
}

resource "aws_s3_bucket" "resources" {
  bucket        = "cc-resources-${var.bucket_suffix}"
  force_destroy = true
}

resource "aws_s3_bucket_acl" "resources" {
  bucket = aws_s3_bucket.resources.id
  acl    = "private"
}

resource "aws_s3_bucket" "buildpacks" {
  bucket        = "cc-buildpacks-${var.bucket_suffix}"
  force_destroy = true
}

resource "aws_s3_bucket_acl" "buildpacks" {
  bucket = aws_s3_bucket.buildpacks.id
  acl    = "private"
}
