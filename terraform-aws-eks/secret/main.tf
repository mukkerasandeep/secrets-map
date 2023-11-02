locals {
  oidc_provider = trimprefix(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://")

  all_secrets_w_dups = flatten([
    for namespace, pod_secrets in var.namespace_pod_secrets: [
      for pod, secretList in pod_secrets :  [
        for secret in secretList : secret
      ]
    ]
  ])

  all_secrets = distinct(local.all_secrets_w_dups)
  
  all_roles_map_w_secrets = flatten([
    for namespace, pod_secrets in var.namespace_pod_secrets: [
      for pod, secretList in pod_secrets : [ 
         for secret in secretList: {
          namespace = namespace 
          role_name = "${namespace}-${pod}" 
          pod_name = pod
          policy_name = secret
        }
      ]
    ]
  ])

  all_roles_map = flatten([
    for namespace, pod_secrets in var.namespace_pod_secrets: [
      for pod, secretList in pod_secrets :  {
          namespace = namespace 
          role_name = "${namespace}-${pod}" 
          sa_name = pod
        }
    ]
  ])

}

# Define the Kubernetes provider
provider "kubernetes" {
  config_path   = "~/.kube/config"  # Path to your kubeconfig file
  config_context = var.eks_cluster_arn
}

# Create AWS Secrets Manager secrets using a "for_each" loop
resource "aws_secretsmanager_secret" "secrets" {
  for_each = toset(local.all_secrets)

  name = each.value  # Secret name is based on the list of secret names
}

# Create AWS IAM policies for each secret
resource "aws_iam_policy" "secrets_policies" {
  for_each = aws_secretsmanager_secret.secrets

  name        = "${each.key}"
  description = "Access policy for ${each.key} secret"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        Effect   = "Allow",
        Resource = each.value.arn
      }
      # Add more statements for other resources and actions if needed
    ]
  })
}

# Create AWS IAM roles for each secret
resource "aws_iam_role" "roles" {
  for_each = {
    for role_map in local.all_roles_map : role_map.role_name => role_map
  }

  name = each.value.role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "sts:AssumeRoleWithWebIdentity",
        Principal = {
          Federated = "arn:aws:iam::${local.account_id}:oidc-provider/${local.oidc_provider}"
        },
        Condition = {
          StringEquals = {
            "${local.oidc_provider}:aud" = "sts.amazonaws.com",
            "${local.oidc_provider}:sub" = "system:serviceaccount:${each.value.namespace}:${each.value.sa_name}"
          }
        }
      }
    ]
  })
}
 
resource "aws_iam_role_policy_attachment" "template-policy-attachment" {
  for_each = {
    for permission in local.all_roles_map_w_secrets : "${permission.role_name}.${permission.policy_name}" => permission
  }

  role       = aws_iam_role.roles[each.value.role_name].name
  policy_arn = "arn:aws:iam::${local.account_id}:policy/${each.value.policy_name}" 
}