resource "aws_s3_bucket" "packages" {
  bucket        = "cc-packages-${var.bucket_suffix}"
  acl           = "private"
  force_destroy = true
}

resource "aws_s3_bucket" "droplets" {
  bucket        = "cc-droplets-${var.bucket_suffix}"
  acl           = "private"
  force_destroy = true
}

resource "aws_s3_bucket" "resources" {
  bucket        = "cc-resources-${var.bucket_suffix}"
  acl           = "private"
  force_destroy = true
}

resource "aws_s3_bucket" "buildpacks" {
  bucket        = "cc-buildpacks-${var.bucket_suffix}"
  acl           = "private"
  force_destroy = true
}
