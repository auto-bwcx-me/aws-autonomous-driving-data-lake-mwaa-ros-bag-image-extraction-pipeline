#!/bin/bash

cmd=$1
build=$2

run_region="ap-southeast-1"

export aws_account_id=$(aws sts get-caller-identity --query Account --output text)

REPO_NAME="adas-rosbag-workflow-with-airflow"  # Should match the ecr repository name given in config.json
IMAGE_NAME="adas-rosbag-workflow-with-airflow" # Should match the image name given in config.json

python3.9 -m venv .env
source .env/bin/activate
pip install -r requirements.txt --use-deprecated=legacy-resolver | grep -v 'already satisfied'
cdk bootstrap aws://$aws_account_id/${run_region}

if [ $build = true ]; then
    export repo_url=$aws_account_id.dkr.ecr.${run_region}.amazonaws.com/$REPO_NAME
    docker build ./service -t $IMAGE_NAME:latest
    last_image_id=$(docker images | awk '{print $3}' | awk 'NR==2')
    echo login ecr
    aws ecr get-login-password --region ${run_region} | docker login --username AWS --password-stdin "$aws_account_id.dkr.ecr.${run_region}.amazonaws.com"
    docker tag $last_image_id $repo_url
    echo docker push $repo_url
    aws ecr describe-repositories --repository-names $REPO_NAME --region ${run_region}
    docker push $repo_url
else
    echo Skipping build
fi

cdk $cmd --region ${run_region}
