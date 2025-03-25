terraform {
  backend "s3" {
    bucket = "k8s-project-bucket"
    key    = "k8s-project/prod-vpc/terraform.tfstate"
    region = "us-east-1"
  }
}
