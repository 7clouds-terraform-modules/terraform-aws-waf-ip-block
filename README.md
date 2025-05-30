# WAF IP Block Module by 7Clouds

Base Networking Resources Module by 7Clouds
Thank you for riding with us! Feel free to download or reference this respository in your terraform projects and studies

This module is a part of our product SCA — An automated API and Serverless Infrastructure generator that can reduce your API development time by 40-60% and automate your deployments up to 90%! Check it out at <https://seventechnologies.cloud>

Please rank this repo 5 starts if you like our job!

## Requirements

This module requires:
*   Terraform version `v1.3.0` or later.
*   AWS Provider version `v5.0.0` or later.

These versions are specified in the `versions.tf` file. It's recommended to use these versions or newer for compatibility with all features.

## Module Functionality

This Terraform module is designed to create and configure an AWS Web Application Firewall (WAFv2). Its primary purpose is to enhance security by controlling web access based on IP addresses.

The key functionalities are:

*   **IP Set Creation**: It creates an AWS WAF IP set based on a list of allowed IP addresses provided by the `WAF_ALLOWED_IP_ADDRESS_LIST` variable.
*   **Web ACL Configuration**:
    *   A Web Access Control List (ACL) is established with a **default action to block** all incoming requests.
    *   A rule is then configured within this Web ACL to **allow** requests originating from the IP addresses defined in the aforementioned IP set.
*   **Resource Association**: The configured Web ACL can be associated with AWS resources such as Application Load Balancers or API Gateway stages using the `WEB_ACL_ASSOCIATION_RESOURCE_ARN_LIST` variable.

In essence, this module implements an IP whitelisting mechanism: it blocks all traffic by default and only permits access from explicitly specified IP addresses. It can also be extended with additional WAF rules.

## Key AWS Resources Managed

This module provisions the following core AWS WAFv2 resources:

*   **`aws_wafv2_ip_set`**:
    *   This resource creates and manages a set of IP addresses.
    *   In this module, it holds the list of explicitly allowed IP addresses (`WAF_ALLOWED_IP_ADDRESS_LIST`) that will be granted access.

*   **`aws_wafv2_web_acl`**:
    *   This is the central component of the WAF, representing the Web Access Control List.
    *   It is configured with a default action to `block` all incoming web requests.
    *   It contains rules that define how requests are handled. A primary rule is set up to `allow` requests originating from the IPs in the `aws_wafv2_ip_set`.
    *   Additional rules (e.g., for rate limiting or managed rule groups like SQL injection protection) can also be added.

*   **`aws_wafv2_web_acl_association`**:
    *   This resource links the configured `aws_wafv2_web_acl` to specific AWS resources.
    *   Supported resources include Application Load Balancers (ALBs) and Amazon API Gateway stages. Once associated, the WAF rules are enforced on the traffic to these resources.

## Configuration and Customization

This module provides several options to tailor the WAF setup to your specific requirements. The primary mechanism for IP whitelisting is supplemented by the following configurations:

*   **Allowed IP Addresses**:
    *   The core of the IP whitelisting functionality is defined by the `WAF_ALLOWED_IP_ADDRESS_LIST` variable. This list should contain the IP addresses or CIDR blocks that are permitted access.
    *   For IPv4 addresses, ensure they include the `/32` suffix (e.g., `"192.0.2.44/32"`).

*   **IP Address Version (`WAF_IP_ADDRESS_VERSION`)**:
    *   Specifies the IP version (`"IPV4"` or `"IPV6"`) for the IP set. (Default: `"IPV4"`)
    *   Ensure `WAF_ALLOWED_IP_ADDRESS_LIST` entries match this version (e.g., `/32` for IPv4, `/128` for IPv6).

*   **Deployment Scope (`WAF_IP_SET_SCOPE`)**:
    *   Determines if the WAF is for regional resources or CloudFront. (Default: `"REGIONAL"`)
    *   `"REGIONAL"`: For Application Load Balancers, API Gateways, etc.
    *   `"CLOUDFRONT"`: For Amazon CloudFront distributions.

*   **Resource Association**:
    *   To apply the WAF rules, you must associate the Web ACL with specific AWS resources.
    *   The `WEB_ACL_ASSOCIATION_RESOURCE_ARN_LIST` variable takes a list of ARNs for the resources to be protected (e.g., ARN of an Application Load Balancer or an Amazon API Gateway stage). If left empty, the Web ACL is created but not attached.

*   **Additional WAF Rules (`RULES`)**:
    *   Beyond the primary IP whitelisting, you can incorporate additional rules, particularly AWS Managed Rule Groups, using the `RULES` variable. This variable expects a list of objects, where each object defines a rule.
    *   **Rule Object Attributes**:
        *   `name` (string, required): A unique name for the rule within the Web ACL.
        *   `priority` (number, required): The evaluation order for the rule. Rules are evaluated from lowest priority number to highest. Ensure this doesn't conflict with the default IP Set Allow rule which has priority 1.
        *   `override_action` (string, optional, default: `"none"`): For managed rule groups, this determines how the rule group's actions are handled. Set to `"none"` to use the actions defined within the rule group, or `"count"` to only count matching requests without applying the rule group's block/allow actions. Must be one of `"none"` or `"count"`.
        *   `metric_name` (string, optional): A name for the CloudWatch metric associated with this rule. If not provided, it defaults to the rule's `name` (e.g., `name = "MyRule"` results in `metric_name = "MyRule"`).
        *   `cloudwatch_metrics_enabled` (bool, optional, default: `false`): Set to `true` to enable CloudWatch metrics for this specific rule.
        *   `sampled_requests_enabled` (bool, optional, default: `false`): Set to `true` to enable request sampling for this specific rule.
        *   `managed_rule_group_statement` (object, required): Defines the managed rule group to use.
            *   `vendor_name` (string, required): The vendor of the managed rule group (e.g., `"AWS"`).
            *   `name` (string, required): The name of the managed rule group (e.g., `"AWSManagedRulesCommonRuleSet"`).
    *   _Example of a rule object within the `RULES` list_:
      ```hcl
      {
        name                       = "AWSManagedRulesCommon"
        priority                   = 10
        override_action            = "none"
        cloudwatch_metrics_enabled = true
        // metric_name will default to "AWSManagedRulesCommon"
        // sampled_requests_enabled will default to false
        managed_rule_group_statement = {
          vendor_name = "AWS"
          name        = "AWSManagedRulesCommonRuleSet"
        }
      }
      ```

*   **WAF Logging**:
    *   `enable_waf_logging` (bool, default: `false`): Set to `true` to enable logging for the Web ACL.
    *   `waf_logging_firehose_arn` (string, default: `null`): Required if `enable_waf_logging` is `true`. This is the ARN of the Kinesis Data Firehose delivery stream to which WAF logs will be sent.
    *   `waf_logging_redacted_fields` (list of objects, default: `[]`): Specifies fields to redact from WAF logs. Each object in the list defines a single field type to redact. This helps protect sensitive data from appearing in logs.
        *   To redact the HTTP method: `{ method = {} }`
        *   To redact the URI path: `{ uri_path = {} }`
        *   To redact the query string: `{ query_string = {} }`
        *   To redact a single request header (e.g., "Authorization"): `{ single_header = { name = "Authorization" } }`
    *   _Example for `waf_logging_redacted_fields`_: `[{ method = {} }, { uri_path = {} }, { single_header = { name = "User-Agent" } }]`

*   **Common Tags (`common_tags`)**:
    *   `common_tags` (map of string, default: `{}`): A map of tags to apply to all taggable WAF resources created by this module (specifically, the WAF IP Set and the WAF Web ACL). These tags are merged with resource-specific default `Name` tags, where the specific `Name` tag takes precedence in case of a conflict.

*   **CloudWatch Metrics Configuration**:
    *   Metrics for the module's default IP set allow rule (priority 1):
        *   `WAF_IP_SET_ALLOW_CLOUDWATCH_METRICS` (bool): Set to `true` to enable CloudWatch metrics for this specific rule.
        *   `WAF_IP_SET_ALLOW_SAMPLED_REQUESTS` (bool): Set to `true` to enable request sampling for this specific rule.
    *   Metrics for the overall Web ACL resource:
        *   `WAF_SCOPE_CLOUDWATCH_METRICS` (bool): Set to `true` to enable CloudWatch metrics for the Web ACL as a whole.
        *   `WAF_SCOPE_SAMPLED_REQUESTS` (bool): Set to `true` to enable request sampling for the Web ACL as a whole.
    *   Note: For rules defined via the `RULES` variable, metrics and sampling are configured within each rule object (`cloudwatch_metrics_enabled` and `sampled_requests_enabled` attributes).

## Conclusion

In summary, this Terraform module offers a standardized and reusable solution for bolstering the security of your AWS-hosted applications. By enabling IP-based access control (whitelisting) and providing the flexibility to integrate additional AWS Managed Rules, it helps establish a critical layer of defense against common web threats and unauthorized access. Its various customization options allow you to adapt the WAF deployment to diverse application needs and existing AWS environments.

## Example

The following example demonstrates how to use the module with various configurations, including AWS Managed Rules, logging, and custom tags.
**Note:** The example values for ARNs (like the Firehose ARN and resource association ARN) are placeholders and should be replaced with actual resource ARNs in a real deployment.

```hcl
module "waf_ip_block_module" {
  source = "./modules/waf" # Example: using a local path to the module

  PROJECT_NAME                  = "my-web-app"
  WAF_IP_SET_ALLOW              = "AllowOfficeAndVPNIPs" # Name for the default IP set allow rule
  WAF_ALLOWED_IP_ADDRESS_LIST   = ["192.0.2.10/32", "203.0.113.0/28"]

  # WAF_IP_ADDRESS_VERSION defaults to "IPV4" in the module.
  # WAF_IP_SET_SCOPE defaults to "REGIONAL" in the module.

  # Enable metrics for the default IP set allow rule (priority 1) and the Web ACL resource itself
  WAF_IP_SET_ALLOW_CLOUDWATCH_METRICS = true
  WAF_IP_SET_ALLOW_SAMPLED_REQUESTS   = true
  WAF_SCOPE_CLOUDWATCH_METRICS        = true
  WAF_SCOPE_SAMPLED_REQUESTS          = true

  # Add AWS Managed Rules using the new 'RULES' structure
  RULES = [
    {
      name                       = "BlockCommonExploits"
      priority                   = 10 # Ensure priority doesn't clash with the default IP set rule (priority 1)
      override_action            = "none" # Use actions from rule group; change to "count" to only count
      cloudwatch_metrics_enabled = true
      sampled_requests_enabled   = true
      # metric_name is optional, defaults to rule name if not set (e.g., "BlockCommonExploits")
      managed_rule_group_statement = {
        vendor_name = "AWS"
        name        = "AWSManagedRulesCommonRuleSet"
      }
    },
    {
      name                       = "BlockKnownBadInputs"
      priority                   = 20
      # Using default override_action ("none") from the variable definition
      # Using default cloudwatch_metrics_enabled (false) and sampled_requests_enabled (false) from variable definition
      managed_rule_group_statement = {
        vendor_name = "AWS"
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
      }
    },
    {
      name                       = "BlockAmazonIPReputationList"
      priority                   = 30
      override_action            = "count" # Only count for this one, perhaps for monitoring
      cloudwatch_metrics_enabled = true
      managed_rule_group_statement = {
        vendor_name = "AWS"
        name        = "AWSManagedRulesAmazonIpReputationList"
      }
    }
  ]

  # Configure WAF Logging (ensure the Kinesis Data Firehose delivery stream exists)
  enable_waf_logging       = true
  # IMPORTANT: Replace with your actual Kinesis Data Firehose ARN. This is a placeholder.
  waf_logging_firehose_arn = "arn:aws:firehose:us-east-1:123456789012:deliverystream/my-app-waf-logs"

  # Redact specific fields from WAF logs to protect sensitive information
  waf_logging_redacted_fields = [
    { method = {} },      # Redact the HTTP method (e.g., GET, POST)
    { uri_path = {} },    # Redact the URI path (e.g., /login.php)
    { query_string = {} },# Redact the query string (e.g., token=secret)
    {                       # Redact a sensitive header like 'Authorization'
      single_header = {
        name = "Authorization"
      }
    },
    {                       # Redact another potentially sensitive header
      single_header = {
        name = "Cookie"
      }
    }
  ]

  # Apply common tags to the WAF IP Set and Web ACL resources
  common_tags = {
    Environment   = "Production"
    ApplicationID = "WebApp123"
    ManagedBy     = "Terraform"
    Team          = "Security"
  }

  # Associate the Web ACL with an AWS resource (e.g., Application Load Balancer ARN)
  # Replace with your actual resource ARN(s) or leave empty if not associating immediately.
  # WEB_ACL_ASSOCIATION_RESOURCE_ARN_LIST = ["arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/my-load-balancer/abcdef1234567890"]
  WEB_ACL_ASSOCIATION_RESOURCE_ARN_LIST = [] # Defaults to empty list (no association) in the module
}
```
<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

</br>

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

</br>

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_waf_ip_block_module"></a> [waf\_ip\_block\_module](#module\_waf\_ip\_block\_module) | ../.. | n/a |

</br>

## Resources

| Name | Type |
|------|------|
| [aws_wafv2_ip_set.waf_ip_set](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_ip_set) | resource |
| [aws_wafv2_web_acl.waf_web_acl_rules](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl) | resource |
| [aws_wafv2_web_acl_association.waf_association](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl_association) | resource |

</br>
Key outputs from this module include the ARNs of the created WAF IP Set (`waf_ip_set_arn`) and Web ACL (`waf_web_acl_arn`), which can be used to reference these resources elsewhere in your Terraform configuration. Other outputs generally mirror the input variables for completeness.
</br>

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_PROJECT_NAME"></a> [PROJECT\_NAME](#input\_PROJECT\_NAME) | The project name that will be prefixed to resource names | `string` | "" | yes |
| <a name="input_RULES"></a> [RULES](#input\_RULES) | Rule blocks used to identify the web requests that you want to allow, block, or count | `list(any)` | `[]` | no |
| <a name="input_WAF_ALLOWED_IP_ADDRESS_LIST"></a> [WAF\_ALLOWED\_IP\_ADDRESS\_LIST](#input\_WAF\_ALLOWED\_IP\_ADDRESS\_LIST) | Contains an array of strings that specify one or more IP addresses or blocks of IP addresses in Classless Inter-Domain Routing (CIDR / with /32) notation. | `list(string)` | n/a | yes |
| <a name="input_WAF_IP_ADDRESS_VERSION"></a> [WAF\_IP\_ADDRESS\_VERSION](#input\_WAF\_IP\_ADDRESS\_VERSION) | Specify IPV4 or IPV6. Valid values are IPV4 or IPV6 | `string` | n/a | yes |
| <a name="input_WAF_IP_SET_ALLOW"></a> [WAF\_IP\_SET\_ALLOW](#input\_WAF\_IP\_SET\_ALLOW) | Name for AWS Managed IP Set Allowing Rules | `string` | n/a | yes |
| <a name="input_WAF_IP_SET_ALLOW_CLOUDWATCH_METRICS"></a> [WAF\_IP\_SET\_ALLOW\_CLOUDWATCH\_METRICS](#input\_WAF\_IP\_SET\_ALLOW\_CLOUDWATCH\_METRICS) | Whether the associated resource sends metrics to CloudWatch | `bool` | n/a | yes |
| <a name="input_WAF_IP_SET_ALLOW_SAMPLED_REQUESTS"></a> [WAF\_IP\_SET\_ALLOW\_SAMPLED\_REQUESTS](#input\_WAF\_IP\_SET\_ALLOW\_SAMPLED\_REQUESTS) | Whether AWS WAF should store a sampling of the web requests that match the rules | `bool` | n/a | yes |
| <a name="input_WAF_IP_SET_SCOPE"></a> [WAF\_IP\_SET\_SCOPE](#input\_WAF\_IP\_SET\_SCOPE) | Specifies whether this is for an AWS CloudFront distribution or for a regional application | `string` | n/a | yes |
| <a name="input_WAF_SCOPE_CLOUDWATCH_METRICS"></a> [WAF\_SCOPE\_CLOUDWATCH\_METRICS](#input\_WAF\_SCOPE\_CLOUDWATCH\_METRICS) | Whether the associated resource sends metrics to CloudWatch | `bool` | n/a | yes |
| <a name="input_WAF_SCOPE_SAMPLED_REQUESTS"></a> [WAF\_SCOPE\_SAMPLED\_REQUESTS](#input\_WAF\_SCOPE\_SAMPLED\_REQUESTS) | Whether AWS WAF should store a sampling of the web requests that match the rules | `bool` | n/a | yes |
| <a name="input_WEB_ACL_ASSOCIATION_RESOURCE_ARN_LIST"></a> [WEB\_ACL\_ASSOCIATION\_RESOURCE\_ARN\_LIST](#input\_WEB\_ACL\_ASSOCIATION\_RESOURCE\_ARN\_LIST) | A list for the Amazon Resource Name (ARN) of the resources to associate with the web ACL. Must be ARN(S) of an Application Load Balancer or an Amazon API Gateway stage | `list(string)` | `[]` | no |

</br>

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_PROJECT_NAME"></a> [PROJECT\_NAME](#output\_PROJECT\_NAME) | The project name that will be prefixed to resource names |
| <a name="output_RULES"></a> [RULES](#output\_RULES) | Rule blocks used to identify the web requests that you want to allow, block, or count |
| <a name="output_WAF_ALLOWED_IP_ADDRESS_LIST"></a> [WAF\_ALLOWED\_IP\_ADDRESS\_LIST](#output\_WAF\_ALLOWED\_IP\_ADDRESS\_LIST) | Contains an array of strings that specify one or more IP addresses or blocks of IP addresses in Classless Inter-Domain Routing (CIDR / with /32) notation. |
| <a name="output_WAF_IP_ADDRESS_VERSION"></a> [WAF\_IP\_ADDRESS\_VERSION](#output\_WAF\_IP\_ADDRESS\_VERSION) | Specify IPV4 or IPV6. Valid values are IPV4 or IPV6 |
| <a name="output_WAF_IP_SET_ALLOW"></a> [WAF\_IP\_SET\_ALLOW](#output\_WAF\_IP\_SET\_ALLOW) | Name for AWS Managed IP Set Allowing Rules |
| <a name="output_WAF_IP_SET_ALLOW_CLOUDWATCH_METRICS"></a> [WAF\_IP\_SET\_ALLOW\_CLOUDWATCH\_METRICS](#output\_WAF\_IP\_SET\_ALLOW\_CLOUDWATCH\_METRICS) | Whether the associated resource sends metrics to CloudWatch |
| <a name="output_WAF_IP_SET_ALLOW_SAMPLED_REQUESTS"></a> [WAF\_IP\_SET\_ALLOW\_SAMPLED\_REQUESTS](#output\_WAF\_IP\_SET\_ALLOW\_SAMPLED\_REQUESTS) | Whether AWS WAF should store a sampling of the web requests that match the rules |
| <a name="output_WAF_IP_SET_SCOPE"></a> [WAF\_IP\_SET\_SCOPE](#output\_WAF\_IP\_SET\_SCOPE) | Specifies whether this is for an AWS CloudFront distribution or for a regional application |
| <a name="output_WAF_SCOPE_CLOUDWATCH_METRICS"></a> [WAF\_SCOPE\_CLOUDWATCH\_METRICS](#output\_WAF\_SCOPE\_CLOUDWATCH\_METRICS) | Whether the associated resource sends metrics to CloudWatch |
| <a name="output_WAF_SCOPE_SAMPLED_REQUESTS"></a> [WAF\_SCOPE\_SAMPLED\_REQUESTS](#output\_WAF\_SCOPE\_SAMPLED\_REQUESTS) | Whether AWS WAF should store a sampling of the web requests that match the rules |
| <a name="output_WEB_ACL_ASSOCIATION_RESOURCE_ARN_LIST"></a> [WEB\_ACL\_ASSOCIATION\_RESOURCE\_ARN\_LIST](#output\_WEB\_ACL\_ASSOCIATION\_RESOURCE\_ARN\_LIST) | A list for the Amazon Resource Name (ARN) of the resources to associate with the web ACL. Must be ARN(S) of an Application Load Balancer or an Amazon API Gateway stage |
<!-- END_TF_DOCS -->