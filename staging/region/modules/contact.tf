resource "aws_api_gateway_rest_api" "contact_email_api" {
    name = "ContactEmailAPI"
    description = "API that handles sending information from a contact form to my email."

    endpoint_configuration {
        types = ["REGIONAL"]
    }
}

resource "aws_api_gateway_resource" "contact_email_resource" {
    rest_api_id = aws_api_gateway_rest_api.contact_email_api.id
    parent_id = aws_api_gateway_rest_api.contact_email_api.root_resource_id

    path_part = "contact_email_resource"
}

resource "aws_api_gateway_method" "contact_email_post_method" {
    rest_api_id = aws_api_gateway_rest_api.contact_email_api.id
    resource_id = aws_api_gateway_resource.contact_email_resource.id

    http_method = "POST"
    authorization = "NONE"
}

resource "aws_api_gateway_integration" "contact_email_integration" {
    rest_api_id = aws_api_gateway_rest_api.contact_email_api.id
    resource_id = aws_api_gateway_resource.contact_email_resource.id
    http_method = aws_api_gateway_method.contact_email_post_method.http_method

    integration_http_method = "POST"
    type = "AWS_PROXY"
    uri = aws_lambda_function.contact_lambda.invoke_arn
}

resource "aws_api_gateway_method_response" "response_200" {
    rest_api_id = aws_api_gateway_rest_api.contact_email_api.id
    resource_id = aws_api_gateway_resource.contact_email_resource.id
    http_method = aws_api_gateway_method.contact_email_post_method.http_method

    status_code = "200"
}

resource "aws_api_gateway_integration_response" "contact_email_integration_response" {
    rest_api_id = aws_api_gateway_rest_api.contact_email_api.id
    resource_id = aws_api_gateway_resource.contact_email_resource.id
    http_method = aws_api_gateway_method.contact_email_post_method.http_method
    status_code = aws_api_gateway_method_response.response_200.status_code

    response_templates = {
        "application/xml" = <<EOF
#set($inputRoot = $input.path('$'))
<?xml version="1.0" encoding="UTF-8"?>
<message>
    $inputRoot.body
</message>
EOF
    }
}

data "archive_file" "lambda_zip" {
    type = "zip"
    source_dir = "../lambda"
    output_path = "lambda.zip"
}

module "cors" {
    source = "squidfunk/api-gateway-enable-cors/aws"
    version = "0.3.1"

    api_id = aws_api_gateway_rest_api.contact_email_api.id
    api_resource_id = aws_api_gateway_resource.contact_email_resource.id
}

resource "aws_lambda_permission" "apigw_lambda" {
    statement_id = "AllowExecutionFromAPIGateway"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.contact_lambda.function_name
    principal     = "apigateway.amazonaws.com"

    source_arn = "${aws_api_gateway_rest_api.contact_email_api.execution_arn}/*/*/*"
}

resource "aws_lambda_function" "contact_lambda" {
    filename = "lambda.zip"
    function_name = "email_handler"
    role= aws_iam_role.role.arn
    handler = "contact_form.email_handler"
    runtime = "python3.8"

    environment {
        variables = {
            SEND_TO = "janellesertyankwok@gmail.com"
        }
    }

    source_code_hash = filebase64sha256(data.archive_file.lambda_zip.output_path)
}

resource "aws_iam_role" "role" {
    name = "contact_email_lambda_execution_role"

    assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy" "ses_permissions" {
    name = "ses_lambda_permissions"
    role = aws_iam_role.role.id

    policy = <<EOF
{
     "Version": "2012-10-17",
            "Statement": [
                {
                    "Sid": "SESUsePolicy",
                    "Effect": "Allow",
                    "Action": [
                        "ses:*"
                    ],
                    "Resource": "*"
                }
            ]
}    
    EOF   
}