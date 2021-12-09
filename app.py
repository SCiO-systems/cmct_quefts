#!/usr/bin/env python3

from aws_cdk import core

from quefts_lambda.quefts_lambda_stack import QueftsLambdaStack


app = core.App()
QueftsLambdaStack(app, "quefts-lambda")

app.synth()
