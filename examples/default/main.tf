module "waf_ip_block_module" {
  source = "../.."

  PROJECT_NAME = "test_project"
  WAF_IP_ADDRESS_VERSION                = "IPV4"
  WAF_ALLOWED_IP_ADDRESS_LIST           = []
  WAF_IP_SET_SCOPE                      = "REGIONAL"
  WAF_IP_SET_ALLOW                      = "IPSetAllow"
  WAF_SCOPE_CLOUDWATCH_METRICS          = true
  WAF_SCOPE_SAMPLED_REQUESTS            = false
  WAF_IP_SET_ALLOW_CLOUDWATCH_METRICS   = true
  WAF_IP_SET_ALLOW_SAMPLED_REQUESTS     = false
  WEB_ACL_ASSOCIATION_RESOURCE_ARN_LIST = []
  RULES = [
    {
      name                                     = "AWSManagedRulesAmazonIpReputationList"
      managed_rule_group_statement_name        = "AWSManagedRulesAmazonIpReputationList"
      managed_rule_group_statement_vendor_name = "AWS"
      metric_name                              = "AWSManagedRulesAmazonIpReputationList"
      priority                                 = 2
      managed_rule_group_statement = {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    },
    {
      name                                     = "AWSManagedRulesSQLiRuleSet"
      managed_rule_group_statement_name        = "AWSManagedRulesSQLiRuleSet"
      managed_rule_group_statement_vendor_name = "AWS"
      metric_name                              = "AWSManagedRulesSQLiRuleSet"
      priority                                 = 3
      managed_rule_group_statement = {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    },
    {
      name                                     = "AWSManagedRulesAnonymousIpList"
      managed_rule_group_statement_name        = "AWSManagedRulesAnonymousIpList"
      managed_rule_group_statement_vendor_name = "AWS"
      metric_name                              = "AWSManagedRulesAnonymousIpList"
      priority                                 = 4
      managed_rule_group_statement = {
        name        = "AWSManagedRulesAnonymousIpList"
        vendor_name = "AWS"
      }
    }
  ]
}