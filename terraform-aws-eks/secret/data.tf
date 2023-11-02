data "aws_caller_identity" "current" {}
locals {
  account_id = data.aws_caller_identity.current.account_id
}

data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}
