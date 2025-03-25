terraform {
  backend "s3" {
    region = "us-east-1"
    bucket = "k8s-project-bucket"
    key    = "k8s-project/prod-eks/terraform.tfstate"
  }
}