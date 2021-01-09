import boto3
import json
import os

ses = boto3.client('ses')

RECEIVER = os.environ["SEND_TO"]

def email_handler(event, context):
    email_confirmed_already = False
    print(event["body"])

    json_content = json.loads(event["body"])
    
    # Grabs all identities confirmed on AWS SES
    response = ses.list_identities(
        IdentityType = 'EmailAddress'
    )
    
    print(response)
    
    # Will confirm an email if it is not confirmed
    for item in response["Identities"]:
        if item == json_content["email_address"]:
            email_confirmed_already = True
        
    if email_confirmed_already == False :
        ses.verify_email_identity(
            EmailAddress = json_content["email_address"]
        )

    sender = json_content["email_address"]

    # Parsing the message from the JSON content 
    message = "{\"message\":\"" + json_content["message"] + "\"}"
    
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

    # Returns a 200 to signify that the message was sent.
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
