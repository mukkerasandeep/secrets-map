variable "cluster_name" {
  type        = string
  description = "Name of the AWS EKS cluster."
}
variable "eks_cluster_arn" {
  description = "The ARN of your AWS EKS cluster"
  type        = string
}
variable "namespace_pod_secrets" {
  type = map(map(list(string)))
}