# # EKS currently documents this required userdata for EKS worker nodes to
# # properly configure Kubernetes applications on the EC2 instance.
# # We utilize a Terraform local here to simplify Base64 encoding this
# # information into the AutoScaling Launch Configuration.
# # More information: https://docs.aws.amazon.com/eks/latest/userguide/launch-workers.html

# locals {
#   node-userdata = <<USERDATA
# #!/bin/bash
# set -o xtrace
# /etc/eks/bootstrap.sh '${var.cluster-name}' \
#   --apiserver-endpoint '${aws_eks_cluster.cluster_eks.endpoint}' \
#   --b64-cluster-ca '${aws_eks_cluster.cluster_eks.certificate_authority[0].data}' \
#   --use-max-pods false
# USERDATA
# }

# locals {
#   node-userdata = <<USERDATA
# #!/bin/bash
# set -o xtrace

# if ! command -v nodeadm &> /dev/null; then
#   dnf install -y nodeadm
# fi

# nodeadm init --apiserver-endpoint '${aws_eks_cluster.cluster_eks.endpoint}' \
#              --b64-cluster-ca '${aws_eks_cluster.cluster_eks.certificate_authority[0].data}' \
#              --kubernetes-version $(nodeadm version --short)

# USERDATA
# }
locals {
  node-userdata = <<USERDATA
#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh --apiserver-endpoint '${aws_eks_cluster.cluster_eks.endpoint}' --b64-cluster-ca '${aws_eks_cluster.cluster_eks.certificate_authority[0].data}' '${var.cluster-name}'
USERDATA

}

# Define the Launch Template
resource "aws_launch_template" "cluster_eks" {
  name_prefix   = "terraform-eks-${var.env}"
  image_id      = var.image_id
  instance_type = "t3.medium"
  iam_instance_profile {
    name = aws_iam_instance_profile.node.name
  }
  vpc_security_group_ids = [aws_security_group.node.id]

  user_data = base64encode(local.node-userdata)

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "terraform-eks-test-${var.env}"
    }
  }
}

# Update Auto Scaling Group to use Launch Template
resource "aws_autoscaling_group" "cluster_eks" {
  desired_capacity     = 3
  max_size            = 4
  min_size            = 2
  vpc_zone_identifier = var.private_subnets

  launch_template {
    id      = aws_launch_template.cluster_eks.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "terraform-eks-${var.env}"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${var.cluster-name}"
    value               = "owned"
    propagate_at_launch = true
  }
}
