#!/bin/bash

#
# 【処理内容】
# VPCを作成する
# サブネットをap-northeast-1aとap-northeast-1cに作成する
# ルートテーブルを作成する
# インターネットゲートウェイを作成する
# インターネットゲートウェイをルートに追加する
# ルートテーブルをサブネットと関連づけする
#

VPC_CIDR=10.1.0.0/16
VPC_NAME=test-vpc
PUBLIC_SUBNET_CIDR_1=10.1.1.0/24
PUBLIC_SUBNET_NAME_1=test-public-subnet-ap-northeast-1a
PUBLIC_SUBNET_CIDR_2=10.1.2.0/24
PUBLIC_SUBNET_NAME_2=test-public-subnet-ap-northeast-1c
ROUTE_TABLE_NAME=test-public-route-table
IGE_NAME=test-igw

VPC_ID=`aws ec2 create-vpc \
    --cidr-block $VPC_CIDR \
    --tag-specification ResourceType=vpc,Tags=[{"Key=Name,Value=${VPC_NAME}"}] | jq -r .Vpc.VpcId`

SUBNET_1=`aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block $PUBLIC_SUBNET_CIDR_1 \
    --availability-zone ap-northeast-1a \
    --tag-specifications ResourceType=subnet,Tags=[{"Key=Name,Value=${PUBLIC_SUBNET_NAME_1}"}] | jq -r .Subnet.SubnetId`

SUBNET_2=`aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block $PUBLIC_SUBNET_CIDR_2 \
    --availability-zone ap-northeast-1c \
    --tag-specifications ResourceType=subnet,Tags=[{"Key=Name,Value=${PUBLIC_SUBNET_NAME_2}"}] | jq -r .Subnet.SubnetId`

ROUTE_TABLE_ID=`aws ec2 create-route-table \
  --vpc-id $VPC_ID \
  --tag-specifications ResourceType=route-table,Tags=[{"Key=Name,Value=${ROUTE_TABLE_NAME}"}] | jq -r .RouteTable.RouteTableId`

aws ec2 associate-route-table \
  --subnet-id $SUBNET_1 \
  --route-table-id $ROUTE_TABLE_ID > /dev/null

aws ec2 associate-route-table \
  --subnet-id $SUBNET_2 \
  --route-table-id $ROUTE_TABLE_ID > /dev/null

IGW_ID=`aws ec2 create-internet-gateway \
    --tag-specifications ResourceType=internet-gateway,Tags=[{"Key=Name,Value=${IGE_NAME}"}] | jq -r .InternetGateway.InternetGatewayId`

aws ec2 attach-internet-gateway \
    --internet-gateway-id $IGW_ID \
    --vpc-id $VPC_ID > /dev/null

aws ec2 create-route \
  --route-table-id $ROUTE_TABLE_ID \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id $IGW_ID > /dev/null

echo "created vpc ${VPC_NAME},${VPC_ID}"