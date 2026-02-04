resource "aws_wafv2_web_acl" "web_acl" {
  name      =  "myapp-web-acl"
  description  =  "WAF for myapp.com"
  scope        =  "REGIONAL"

  default_action  {
    allow {}

}

visibility_config  {
  cloudwatch_metrics_enabled    =  true
  metric_name                   =  "myapp-waf"

}

rule  {
  name  = "SQLInjectionRule"
  priority  = 1

  action {
    block {}

}

visibility_config {
    cloudwatch_metrics_enabled  =  true
    metric_name                 =  "SQLInjectionRule"
    sampled_requests_enabled    =  true
  }
}

rule {
  name  =  "XSSRule"
  priorty  =  2

  action  {
    block {}
}

statement {
  managed_rule_group_statement {
    name      =  "AWSMangedRuleXSSRulesSet
    vendor_name  =  "AWS"
  }
}

visibility_config {
  cloudwatch_metrics_enabled  = true
  metric_name                 =  "XSSRule"
  sampled_requests_enabled    =  true
    }
  }
}

#### Create Application Load Balancer (ALB)

resource "aws_lb" "app_alb" {
  name        =  "myapp-alb"
  internal    =  false
  
