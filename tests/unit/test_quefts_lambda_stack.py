import json
import pytest

from aws_cdk import core
from quefts_lambda.quefts_lambda_stack import QueftsLambdaStack


def get_template():
    app = core.App()
    QueftsLambdaStack(app, "quefts-lambda")
    return json.dumps(app.synth().get_stack("quefts-lambda").template)


def test_sqs_queue_created():
    assert("AWS::SQS::Queue" in get_template())


def test_sns_topic_created():
    assert("AWS::SNS::Topic" in get_template())
