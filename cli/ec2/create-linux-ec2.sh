#!/bin/bash

# 【処理内容】
# キーペアを作成する
# セキュリティグループを作成する
# 自身のアドレスからのSSH接続を受け付けるようにインバウンドルールを編集する
# EC2インスタンスを作成する
#
# 【前提条件】
# VPC、サブネットが事前に作成されている必要がある
#

# key pair parameter
KEY_PAIR_NAME=linux-key-pair
KEY_OUTPUT_FILE=~/linux-key-pair.pem
# security group parameter
VPC_ID=vpc-0fc92abf4de9c1989
SECURITY_GROUP_NAME=ec2-security-group
MY_IP=`curl -s https://checkip.amazonaws.com`
# ec2 instsance parameter
SUBNET_ID=subnet-02867c2da4a795260
EC2_NAME=test-ec2
AMI_ID=ami-04beabd6a4fb6ab6f #Amazon Linux 2023 AMI

aws ec2 create-key-pair --key-name $KEY_PAIR_NAME --query 'KeyMaterial' --output text > $KEY_OUTPUT_FILE
chmod 400 $KEY_OUTPUT_FILE

GROUP_ID=`aws ec2 create-security-group --group-name $SECURITY_GROUP_NAME --description "My security group" --vpc-id $VPC_ID | jq -r .GroupId`
aws ec2 authorize-security-group-ingress \
    --group-id $GROUP_ID \
    --protocol tcp --port 22 --cidr ${MY_IP}/32 > /dev/null

INSTANCE_ID=`aws ec2 run-instances --image-id $AMI_ID \
    --count 1 \
    --instance-type t2.micro \
    --key-name $KEY_PAIR_NAME \
    --security-group-ids $GROUP_ID \
    --subnet-id $SUBNET_ID \
    --associate-public-ip-address \
    --tag-specifications ResourceType=instance,Tags=[{"Key=Name,Value=${EC2_NAME}"}] | jq -r .Instances[0].InstanceId`

echo "completed."
echo "ec2 ${EC2_NAME},${INSTANCE_ID}"
echo "keypair ${KEY_PAIR_NAME}"
echo "key file ${KEY_OUTPUT_FILE}"
echo "security group ${GROUP_ID}"