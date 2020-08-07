# Using terraform with AWS

1. Add secrets to secret manager:
* ci_k8s_aws_region
* ci_k8s_aws_access_key_id
* ci_k8s_aws_secret_access_key
* ci_k8s_aws_rds_database_password

2. Ensure the following entries exist within the `cf_for_k8s_private_dockerhub` secret

* cf_for_k8s_private_dockerhub.repository_prefix
* cf_for_k8s_private_dockerhub.hostname

