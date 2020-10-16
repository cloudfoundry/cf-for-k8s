# Using an external blobstore

1. Create the necessary buckets using `aws-cli`:

    ```
    REGION=<your-region>
    aws s3api create-bucket --bucket <bucket-name-buildpack> --region "$REGION" --create-bucket-configuration LocationConstraint="$REGION" --acl private
    aws s3api create-bucket --bucket <bucket-name-droplet>   --region "$REGION" --create-bucket-configuration LocationConstraint="$REGION" --acl private
    aws s3api create-bucket --bucket <bucket-name-package>   --region "$REGION" --create-bucket-configuration LocationConstraint="$REGION" --acl private
    aws s3api create-bucket --bucket <bucket-name-resource>  --region "$REGION" --create-bucket-configuration LocationConstraint="$REGION" --acl private
    ```

    *Note*: The name of your buckets (`package_directory_key`, `droplet_directory_key`, `resource_directory_key`, `buildpack_directory_key`) need to be globally unique! Also check your needed/supported `aws_signature_version` and configure it accordingly.

1. Create a dedicated user with read/write access to your buckets. When using AWS, take a look at their [documentation](https://docs.aws.amazon.com/AmazonS3/latest/dev/s3-access-control.html).

1. Add the following values to your installation (keep in mind, that these values may vary when using a provider other than AWS):

    ```yaml
    #@data/values
    ---
    blobstore:
      endpoint: https://s3.<your-region>.amazonaws.com/
      region: <your-region>
      access_key_id: <your-access-key-id>
      secret_access_key: <your-secret-access-key>
      package_directory_key: <bucket-name-package>
      droplet_directory_key: <bucket-name-droplet>
      resource_directory_key: <bucket-name-resource>
      buildpack_directory_key: <bucket-name-buildpack>
      aws_signature_version: "4"
    ```
