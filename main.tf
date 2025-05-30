resource "aws_wafv2_web_acl" "waf_web_acl_rules" {
  name        = "${var.PROJECT_NAME}WafWebAclRules"
  description = "WAF WEB ACL for API Gateway"
  scope       = var.WAF_IP_SET_SCOPE

  default_action {
    block {}
  }

  tags = merge(var.common_tags, { Name = "${var.PROJECT_NAME}WafWebAclRules" })

  visibility_config {
    cloudwatch_metrics_enabled = var.WAF_SCOPE_CLOUDWATCH_METRICS
    metric_name                = "${var.PROJECT_NAME}WafWebAclRules"
    sampled_requests_enabled   = var.WAF_SCOPE_SAMPLED_REQUESTS
  }

  rule {
    name     = var.WAF_IP_SET_ALLOW
    priority = 1
    action {
      allow {}
    }
    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.waf_ip_set.arn
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = var.WAF_IP_SET_ALLOW_CLOUDWATCH_METRICS
      metric_name                = var.WAF_IP_SET_ALLOW
      sampled_requests_enabled   = var.WAF_IP_SET_ALLOW_SAMPLED_REQUESTS
    }
  }

  dynamic "rule" {
    for_each = toset(var.RULES)
    content {
      name     = rule.value.name
      priority = rule.value.priority

      override_action {
        dynamic "none" {
          for_each = rule.value.override_action == "none" ? [1] : []
          content {}
        }
        dynamic "count" {
          for_each = rule.value.override_action == "count" ? [1] : []
          content {}
        }
      }

      statement {
        managed_rule_group_statement {
          name        = rule.value.managed_rule_group_statement.name
          vendor_name = rule.value.managed_rule_group_statement.vendor_name
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = rule.value.cloudwatch_metrics_enabled
        metric_name                = coalesce(rule.value.metric_name, rule.value.name)
        sampled_requests_enabled   = rule.value.sampled_requests_enabled
      }
    }
  }
}

# ✅ This block must be OUTSIDE of the acl block
resource "aws_wafv2_web_acl_logging_configuration" "this" {
  count = var.enable_waf_logging ? 1 : 0

  resource_arn         = aws_wafv2_web_acl.waf_web_acl_rules.arn
  log_destination_configs = [var.waf_logging_firehose_arn]

  dynamic "redacted_fields" {
    for_each = var.waf_logging_redacted_fields
    iterator = field_to_redact
    content {
      dynamic "method" {
        for_each = field_to_redact.value.method != null ? [1] : []
        content {}
      }
      dynamic "query_string" {
        for_each = field_to_redact.value.query_string != null ? [1] : []
        content {}
      }
      dynamic "uri_path" {
        for_each = field_to_redact.value.uri_path != null ? [1] : []
        content {}
      }
      dynamic "single_header" {
        for_each = field_to_redact.value.single_header != null ? [1] : []
        content {
          name = field_to_redact.value.single_header.name
        }
      }
    }
  }
}

resource "aws_wafv2_ip_set" "waf_ip_set" {
  name               = "${var.PROJECT_NAME}-WAF-IP-Set"
  description        = "Waf Ip Set for allowing specific IPs"
  scope              = var.WAF_IP_SET_SCOPE
  ip_address_version = var.WAF_IP_ADDRESS_VERSION
  addresses          = var.WAF_ALLOWED_IP_ADDRESS_LIST
  tags               = merge(var.common_tags, { Name = "${var.PROJECT_NAME}-WAF-IP-Set" })
}