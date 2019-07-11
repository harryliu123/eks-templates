SECRETS_FILE ?= secrets.mk
ifeq ($(shell test -e $(SECRETS_FILE) && echo -n yes),yes)
    include $(SECRETS_FILE)
endif
ROOT ?= $(shell pwd)
AWS_ACCOUNT_ID := $(shell aws sts get-caller-identity --query 'Account' --output text)
EKS_YAML_URL ?= https://s3-us-west-2.amazonaws.com/pahud-cfn-us-west-2/eks-templates/cloudformation/eks-dev.yaml
CLUSTER_YAML ?= https://s3-us-west-2.amazonaws.com/pahud-cfn-us-west-2/eks-templates/cloudformation/cluster.yaml
CLUSTER_STACK_NAME ?= eksdemo
CLUSTER_NAME ?= $(CLUSTER_STACK_NAME)
EKS_ADMIN_ROLE ?= arn:aws:iam::620154271401:role/AmazonEKSAdminRole
REGION ?= us-east-2
SSH_KEY_NAME ?= eksworkshop
VPC_ID ?= vpc-09de8f1ee191ebcd6
SUBNET1 ?= subnet-0b813a12742980ef3
SUBNET2 ?= subnet-0efda4e0f142e2ef4
SUBNET3 ?= subnet-03c7521455b3e029b
OnDemandBaseCapacity ?= 3
NodeAutoScalingGroupMinSize ?= 0
NodeAutoScalingGroupDesiredSize ?= 4
NodeAutoScalingGroupMaxSize ?= 6


.PHONY: sam-dev-package
sam-dev-package:
	@docker run -ti \
	-v $(PWD):/home/samcli/workdir \
	-v $(HOME)/.aws:/home/samcli/.aws \
	-w /home/samcli/workdir \
	-e AWS_DEFAULT_REGION=$(REGION) \
	pahud/aws-sam-cli:latest sam package --template-file ./cloudformation/configmap-sar.yaml --s3-bucket $(S3BUCKET) --output-template-file ./cloudformation/configmap-sar-packaged.yaml
	

.PHONY: all
all: deploy

.PHONY: sync
sync: deploy

.PHONY: update-ami
update-ami:
	@aws s3 cp files/eks-latest-ami.yaml s3://pahud-eks-templates/eks-latest-ami.yaml --acl public-read


.PHONY: update-yaml
update-yaml:
	#aws --region us-west-2 s3 sync cloudformation s3://pahud-cfn-us-west-2/eks-templates/cloudformation/ --acl public-read
	@aws --region us-west-2 s3 cp cloudformation/nodegroup.yaml s3://pahud-cfn-us-west-2/eks-templates/cloudformation/nodegroup.yaml --acl public-read
	@aws --region us-west-2 s3 cp cloudformation/eks.yaml s3://pahud-cfn-us-west-2/eks-templates/cloudformation/eks.yaml --acl public-read
	@aws --region us-west-2 s3 cp cloudformation/ami.yaml s3://pahud-cfn-us-west-2/eks-templates/cloudformation/ami.yaml --acl public-read
	@echo https://s3-us-west-2.amazonaws.com/pahud-cfn-us-west-2/eks-templates/cloudformation/eks.yaml

.PHONY: update-dev-yaml	
update-dev-yaml: 
	@aws --region us-west-2 s3 cp cloudformation/eks.yaml s3://pahud-cfn-us-west-2/eks-templates/cloudformation/eks-dev.yaml --acl public-read
	@aws --region us-west-2 s3 cp cloudformation/ami.yaml s3://pahud-cfn-us-west-2/eks-templates/cloudformation/ami-dev.yaml --acl public-read
	@aws --region us-west-2 s3 cp cloudformation/cluster.yaml s3://pahud-cfn-us-west-2/eks-templates/cloudformation/cluster-dev.yaml --acl public-read
	@aws --region us-west-2 s3 cp cloudformation/nodegroup.yaml s3://pahud-cfn-us-west-2/eks-templates/cloudformation/nodegroup-dev.yaml --acl public-read
	@aws --region us-west-2 s3 cp cloudformation/configmap.yaml s3://pahud-cfn-us-west-2/eks-templates/cloudformation/configmap-dev.yaml --acl public-read
	@aws --region us-west-2 s3 cp cloudformation/configmap-sar.yaml s3://pahud-cfn-us-west-2/eks-templates/cloudformation/configmap-sar-dev.yaml --acl public-read
	@echo https://s3-us-west-2.amazonaws.com/pahud-cfn-us-west-2/eks-templates/cloudformation/eks-dev.yaml

.PHONY: clean
clean:
	echo "done"

.PHONY: create-eks-cluster	
create-eks-cluster:
	@aws --region $(REGION) cloudformation create-stack --template-url $(EKS_YAML_URL) \
	--stack-name  $(CLUSTER_STACK_NAME) \
	--role-arn $(EKS_ADMIN_ROLE) \
	--capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
	--parameters \
	ParameterKey=VpcId,ParameterValue=$(VPC_ID) \
	ParameterKey=ClusterName,ParameterValue=$(CLUSTER_NAME) \
	ParameterKey=KeyName,ParameterValue=$(SSH_KEY_NAME) \
	ParameterKey=LambdaRoleArn,ParameterValue=$(EKS_ADMIN_ROLE) \
	ParameterKey=OnDemandBaseCapacity,ParameterValue=$(OnDemandBaseCapacity) \
	ParameterKey=NodeAutoScalingGroupMinSize,ParameterValue=$(NodeAutoScalingGroupMinSize) \
	ParameterKey=NodeAutoScalingGroupDesiredSize,ParameterValue=$(NodeAutoScalingGroupDesiredSize) \
	ParameterKey=NodeAutoScalingGroupMaxSize,ParameterValue=$(NodeAutoScalingGroupMaxSize) \
	ParameterKey=SubnetIds,ParameterValue=$(SUBNET1)\\,$(SUBNET2)\\,$(SUBNET3)

.PHONY: update-eks-cluster	
update-eks-cluster:
	@aws --region $(REGION) cloudformation update-stack --template-url $(EKS_YAML_URL) \
	--stack-name  $(CLUSTER_STACK_NAME) \
	--role-arn  $(EKS_ADMIN_ROLE) \
	--capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
	--parameters \
	ParameterKey=VpcId,ParameterValue=$(VPC_ID) \
	ParameterKey=ClusterName,ParameterValue=$(CLUSTER_NAME) \
	ParameterKey=KeyName,ParameterValue=$(SSH_KEY_NAME) \
	ParameterKey=LambdaRoleArn,ParameterValue=$(EKS_ADMIN_ROLE) \
	ParameterKey=OnDemandBaseCapacity,ParameterValue=$(OnDemandBaseCapacity) \
	ParameterKey=NodeAutoScalingGroupMinSize,ParameterValue=$(NodeAutoScalingGroupMinSize) \
	ParameterKey=NodeAutoScalingGroupDesiredSize,ParameterValue=$(NodeAutoScalingGroupDesiredSize) \
	ParameterKey=NodeAutoScalingGroupMaxSize,ParameterValue=$(NodeAutoScalingGroupMaxSize) \
	ParameterKey=SubnetIds,ParameterValue=$(SUBNET1)\\,$(SUBNET2)\\,$(SUBNET3)
	
.PHONY: delete-eks-cluster	
delete-eks-cluster:
	@aws --region $(REGION) cloudformation delete-stack --role-arn $(EKS_ADMIN_ROLE) --stack-name "$(CLUSTER_STACK_NAME)"


.PHONY: deploy-pl
deploy-pl:
	@aws --region us-west-2 cloudformation create-stack --template-body file://cloudformation/codepipeline.yml \
	--stack-name  eksGlobalPL \
	--parameters \
	ParameterKey=GitHubToken,ParameterValue=$(GitHubToken) \
	ParameterKey=CloudFormationExecutionRole,ParameterValue=$(EKS_ADMIN_ROLE) \
	ParameterKey=OnDemandBaseCapacity,ParameterValue=$(OnDemandBaseCapacity) \
	--capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND 

.PHONY: update-pl
update-pl:
	@aws --region us-west-2 cloudformation update-stack --template-body file://cloudformation/codepipeline.yml \
	--stack-name  eksGlobalPL \
	--parameters \
	ParameterKey=GitHubToken,ParameterValue=$(GitHubToken) \
	ParameterKey=CloudFormationExecutionRole,ParameterValue=$(EKS_ADMIN_ROLE) \
	ParameterKey=OnDemandBaseCapacity,ParameterValue=$(OnDemandBaseCapacity) \
	ParameterKey=NodeAutoScalingGroupDesiredSize,ParameterValue=$(NodeAutoScalingGroupDesiredSize) \
	--capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND 
	
.PHONY: delete-pl-stacks
delete-pl-stacks:
	# delete all cfn stacks provisioned from the pipeline
	@aws --region us-west-2 cloudformation update-stack --template-body file://cloudformation/codepipeline.yml \
	--stack-name  eksGlobalPL \
	--parameters \
	ParameterKey=GitHubToken,ParameterValue=$(GitHubToken) \
	ParameterKey=ActionMode,ParameterValue=DELETE_ONLY \
	ParameterKey=CloudFormationExecutionRole,ParameterValue=$(EKS_ADMIN_ROLE) \
	--capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND 	
	
.PHONY: delete-pl
delete-pl:
	@aws --region us-west-2 cloudformation delete-stack --stack-name eksGlobalPL
