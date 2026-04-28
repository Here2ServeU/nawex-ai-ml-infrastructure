output "vpc_id" {
  value       = aws_vpc.this.id
  description = "VPC ID."
}

output "private_subnet_ids" {
  value       = aws_subnet.private[*].id
  description = "Private subnet IDs (used by EKS node groups)."
}

output "public_subnet_ids" {
  value       = aws_subnet.public[*].id
  description = "Public subnet IDs (used by ALBs/NLBs that face the internet)."
}

output "azs" {
  value = local.azs
}
