output "bucket_packages" {
    value = aws_s3_bucket.packages.id
}

output "bucket_droplets" {
    value = aws_s3_bucket.droplets.id
}

output "bucket_resources" {
    value = aws_s3_bucket.resources.id
}

output "bucket_buildpacks" {
    value = aws_s3_bucket.buildpacks.id
}
