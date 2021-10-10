resource "random_id" "rando" {
  byte_length = 2
}

variable "top_domain" {
  type    = string
  default = "example.com"
}

data "aws_cloudfront_distribution" "cfdist_edge_applied" {
  id = "E1ORCUW20YPAPU"
}

module "lambda_at_edge" {
  source = "terraform-aws-modules/lambda/aws"

  lambda_at_edge = true

  function_name = "cf-lambda-edge-redirect-${random_id.rando.hex}"
  description   = "Redirect URL's using Lambda@Edge"
  handler       = "index.handler"
  runtime       = "nodejs12.x"

  source_path = "./handler"

  assume_role_policy_statements = {
    account_root = {
      effect  = "Allow",
      actions = ["sts:AssumeRole"],
      principals = {
        account_principal = {
          type        = "Service",
          identifiers = ["edgelambda.amazonaws.com", "lambda.amazonaws.com"]
        }
      }
    }
  }

  tags = {
    Module = "lambda-at-edge"
  }
}

resource "local_file" "redir_file" {
  content  = <<EOF
[
    {
        "source": "/example1234",
        "destination": "https://www.${var.top_domain}/test/example1234"
    }
]
EOF
  filename = "${path.module}/handler/redir.json"
}

resource "local_file" "handler_file" {
  content  = <<EOF
const redirectsStatic = require('./redir.json').map(
    ({ source, destination }) => ({
      source,
      destination
    })
  );
  
  exports.handler = async (event) => {
    const request = event.Records[0].cf.request;
    
    for (const { source, destination } of redirectsStatic) {
      if (source == request.uri) {
        return {
          status: '301',
          statusDescription: 'Moved Permanently',
          headers: {
            location: [{ value: destination }]
          }
        };
      }
    }
  
    return {
      status: '302',
      statusDescription: 'Found',
      headers: {
        location: [{ value: 'https://www.${var.top_domain}' + request.uri }]
      }
    };
    
  };
EOF
  filename = "${path.module}/handler/index.js"
}