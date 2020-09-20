import boto3
import json

ses = boto3.client('ses')

RECEIVER = "janellesertyankwok@gmail.com"



def email_handler(event, context):
    print(event["body"])

    json_content = json.loads(event["body"])

    ses.verify_email_identity(
        EmailAddress = json_content["email_address"]
    )

    sender = json_content["email_address"]

    message = "{\"message\":\"" + json_content["message"] + "\"}"

    # template = ses.create_template(
    # Template={
    #     'TemplateName': 'EmailTemplate',
    #     'SubjectPart': 'New Contact Email!',
    #     'TextPart': '{{message}}',
    #     'HtmlPart': '{{message}}'
    # })

    res = ses.send_templated_email(
        Source=sender,
        Destination={
            'ToAddresses': [
                RECEIVER
            ],
        },
        Template="EmailTemplate",
        TemplateData=message
    )

    return {
        'statusCode': 200,
        'headers': {
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'OPTIONS,POST,GET',
            'Access-Control-Allow-Credentials': True
        },
        'body': message
    }
