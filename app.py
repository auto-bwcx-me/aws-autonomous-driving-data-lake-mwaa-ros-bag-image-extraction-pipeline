#!/usr/bin/env python3

from aws_cdk import core
from infrastructure.ecs_stack import RosbagProcessor
import os
import json

# Load config
project_dir = os.path.dirname(os.path.abspath(__file__))

config_file = os.path.join(project_dir, "config.json")

with open(config_file) as json_file:
    config = json.load(json_file)

print(config)

image_name = config["image-name"]
stack_id = config["stack-id"]
ecr_repository_name = config["ecr-repository-name"]

cpu = config["cpu"]
memory_limit_mib = config["memory-limit-mib"]
timeout_minutes = config["timeout-minutes"]
s3_filters = config["s3-filters"]

default_environment_vars = config["environment-variables"]
input_bucket_name = config["input-bucket-name"]
output_bucket_name = config["output-bucket-name"]

app = core.App()

RosbagProcessor(
    app,
    stack_id,
    image_name=image_name,
    environment_vars=default_environment_vars,
    ecr_repository_name=ecr_repository_name,
    cpu=cpu,
    memory_limit_mib=memory_limit_mib,
    timeout_minutes=timeout_minutes,
    s3_filters=s3_filters,
    input_bucket_name=input_bucket_name,
    output_bucket_name=output_bucket_name,
)

app.synth()
