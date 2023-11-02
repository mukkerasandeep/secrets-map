output "secret_arns" {
  value = [for secret in aws_secretsmanager_secret.secrets : secret.arn]
}

output "role_arns" {
  value = [for role in aws_iam_role.roles : role.arn]
}