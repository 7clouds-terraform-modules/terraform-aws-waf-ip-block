############################################################################################
#                                      ESSENTIAL                                           #
############################################################################################
variable "PROJECT_NAME" {
  type        = string
  description = "A descriptive name for the project. This will be used as a prefix for AWS resource names created by this module to ensure uniqueness and easy identification."
  default     = ""
}

############################################################################################
#                                      STRUCTURAL                                          #
############################################################################################

variable "WAF_IP_ADDRESS_VERSION" {
  type        = string
  description = "The IP address version for the WAF IP Set. Must be either 'IPV4' or 'IPV6'."
  default     = "IPV4"
  validation {
    condition     = contains(["IPV4", "IPV6"], var.WAF_IP_ADDRESS_VERSION)
    error_message = "Valid values for WAF_IP_ADDRESS_VERSION are 'IPV4' or 'IPV6'."
  }
}

variable "WAF_ALLOWED_IP_ADDRESS_LIST" {
  type        = list(string)
  description = "A list of IP addresses or CIDR blocks to allow. Each IPv4 address must include a '/32' prefix (e.g., '192.0.2.44/32'), and each IPv6 address must include a '/128' prefix (e.g., '2001:db8::/128')."
}

variable "WAF_IP_SET_SCOPE" {
  type        = string
  description = "Specifies the scope of the WAF IP Set and Web ACL. Use 'REGIONAL' for resources like Application Load Balancers and API Gateways, or 'CLOUDFRONT' for Amazon CloudFront distributions."
  default     = "REGIONAL"
  validation {
    condition     = contains(["REGIONAL", "CLOUDFRONT"], var.WAF_IP_SET_SCOPE)
    error_message = "Valid values for WAF_IP_SET_SCOPE are 'REGIONAL' or 'CLOUDFRONT'."
  }
}

variable "WAF_IP_SET_ALLOW" {
  type        = string
  description = "A descriptive name for the WAF rule that allows traffic from the specified IP set (e.g., 'AllowListedIPsRule')."
}

variable "WAF_SCOPE_CLOUDWATCH_METRICS" {
  type        = bool
  description = "Whether to enable CloudWatch metrics for the main Web ACL. Set to `true` to send metrics, `false` otherwise."
}

variable "WAF_SCOPE_SAMPLED_REQUESTS" {
  type        = bool
  description = "Whether AWS WAF should store a sample of web requests that match the main Web ACL rules. Set to `true` to enable, `false` otherwise."
}

variable "WAF_IP_SET_ALLOW_CLOUDWATCH_METRICS" {
  type        = bool
  description = "Whether to enable CloudWatch metrics for the specific rule that allows traffic from the IP set. Set to `true` to send metrics, `false` otherwise."
}

variable "WAF_IP_SET_ALLOW_SAMPLED_REQUESTS" {
  type        = bool
  description = "Whether AWS WAF should store a sample of web requests that match the IP set allow rule. Set to `true` to enable, `false` otherwise."
}

variable "RULES" {
  description = "A list of AWS Managed Rules to apply. See AWS documentation for available rule groups and their names."
  type = list(object({
    name                       = string # Name for this rule in the Web ACL
    priority                   = number # Evaluation order for the rule
    override_action            = optional(string, "none") # For managed rules, usually "none" to use actions from rule group, or "count".
    metric_name                = optional(string)         # CloudWatch metric name, defaults to rule name if not set
    cloudwatch_metrics_enabled = optional(bool, false)    # Enable CloudWatch metrics for this rule
    sampled_requests_enabled   = optional(bool, false)    # Enable sampled requests for this rule
    managed_rule_group_statement = object({
      vendor_name = string # e.g., "AWS"
      name        = string # e.g., "AWSManagedRulesCommonRuleSet"
      # Potentially add excluded_rules here later if needed: list(object({ name = string }))
    })
  }))
  default = []
  validation {
    condition = alltrue([
      for rule in var.RULES :
      contains(["none", "count"], rule.override_action)
    ])
    error_message = "Each rule's 'override_action' in RULES must be either 'none' or 'count'."
  }
}

variable "WEB_ACL_ASSOCIATION_RESOURCE_ARN_LIST" {
  type        = list(string)
  description = "A list of Amazon Resource Names (ARNs) for the AWS resources (e.g., Application Load Balancer, API Gateway stage) to associate with this Web ACL. An empty list means the Web ACL will be created but not associated with any resource."
  default     = []
}

variable "common_tags" {
  description = "A map of common tags to apply to all taggable WAF resources."
  type        = map(string)
  default     = {}
}

variable "enable_waf_logging" {
  description = "Set to true to enable WAF logging. If true, `waf_logging_firehose_arn` must be provided."
  type        = bool
  default     = false
}

variable "waf_logging_firehose_arn" {
  description = "The ARN of the Kinesis Data Firehose delivery stream to send WAF logs to. Required if `enable_waf_logging` is true."
  type        = string
  default     = null
}

variable "waf_logging_redacted_fields" {
  description = "A list of objects representing fields to redact from WAF logs. Each object should have one of the specific field match type blocks defined (e.g., method, uri_path, query_string, single_header)."
  type = list(object({
    method = optional(object({}), null) # Redact the HTTP method. Block is empty.
    uri_path = optional(object({}), null) # Redact the URI path. Block is empty.
    query_string = optional(object({}), null) # Redact the query string. Block is empty.
    single_header = optional(object({ # Redact a single request header.
      name = string # The name of the header to redact.
    }), null)
  }))
  default = []
}