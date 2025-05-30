###########################################################################################
#                                     ESSENTIAL                                           #
###########################################################################################
output "PROJECT_NAME" {
  value       = var.PROJECT_NAME
  description = "A descriptive name for the project. This will be used as a prefix for AWS resource names created by this module to ensure uniqueness and easy identification."
}

############################################################################################
#                                      STRUCTURAL                                          #
############################################################################################
output "WAF_IP_ADDRESS_VERSION" {
  value       = var.WAF_IP_ADDRESS_VERSION
  description = "The IP address version for the WAF IP Set. Must be either 'IPV4' or 'IPV6'."
}

output "WAF_ALLOWED_IP_ADDRESS_LIST" {
  value       = var.WAF_ALLOWED_IP_ADDRESS_LIST
  description = "A list of IP addresses or CIDR blocks to allow. Each IPv4 address must include a '/32' prefix (e.g., '192.0.2.44/32'), and each IPv6 address must include a '/128' prefix (e.g., '2001:db8::/128')."
}

output "WAF_IP_SET_SCOPE" {
  value       = var.WAF_IP_SET_SCOPE
  description = "Specifies the scope of the WAF IP Set and Web ACL. Use 'REGIONAL' for resources like Application Load Balancers and API Gateways, or 'CLOUDFRONT' for Amazon CloudFront distributions."
}

output "WAF_IP_SET_ALLOW" {
  value       = var.WAF_IP_SET_ALLOW
  description = "A descriptive name for the WAF rule that allows traffic from the specified IP set (e.g., 'AllowListedIPsRule')."
}

output "WAF_SCOPE_CLOUDWATCH_METRICS" {
  value       = var.WAF_SCOPE_CLOUDWATCH_METRICS
  description = "Whether to enable CloudWatch metrics for the main Web ACL. Set to `true` to send metrics, `false` otherwise."
}

output "WAF_SCOPE_SAMPLED_REQUESTS" {
  value       = var.WAF_SCOPE_SAMPLED_REQUESTS
  description = "Whether AWS WAF should store a sample of web requests that match the main Web ACL rules. Set to `true` to enable, `false` otherwise."
}

output "WAF_IP_SET_ALLOW_CLOUDWATCH_METRICS" {
  value       = var.WAF_IP_SET_ALLOW_CLOUDWATCH_METRICS
  description = "Whether to enable CloudWatch metrics for the specific rule that allows traffic from the IP set. Set to `true` to send metrics, `false` otherwise."
}

output "WAF_IP_SET_ALLOW_SAMPLED_REQUESTS" {
  value       = var.WAF_IP_SET_ALLOW_SAMPLED_REQUESTS
  description = "Whether AWS WAF should store a sample of web requests that match the IP set allow rule. Set to `true` to enable, `false` otherwise."
}

output "RULES" {
  value       = var.RULES
  description = "A list of AWS Managed Rules to apply. See AWS documentation for available rule groups and their names."
}

output "WEB_ACL_ASSOCIATION_RESOURCE_ARN_LIST" {
  value       = var.WEB_ACL_ASSOCIATION_RESOURCE_ARN_LIST
  description = "A list of Amazon Resource Names (ARNs) for the AWS resources (e.g., Application Load Balancer, API Gateway stage) to associate with this Web ACL. An empty list means the Web ACL will be created but not associated with any resource."
}

############################################################################################
#                                 AWS Resource Outputs                                     #
############################################################################################

output "waf_ip_set_arn" {
  description = "The ARN of the WAF IP set."
  value       = aws_wafv2_ip_set.waf_ip_set.arn
}

output "waf_web_acl_arn" {
  description = "The ARN of the WAF Web ACL."
  value       = aws_wafv2_web_acl.waf_web_acl_rules.arn
}