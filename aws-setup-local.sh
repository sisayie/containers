# Configure Credentials
aws configure #avoid storing credentials on EC2

# Create KeyPair
aws ec2 create-key-pair \
--key-name exam-score-server-key \
--query 'KeyMaterial' \
--output text > exam-score-server-key.pem

mv exam-score-server-key.pem ~/.ssh/exam-score-server-key.pem

chmod 400 ~/.ssh/exam-score-server-key.pem


# Deploy
aws cloudformation deploy \
--template-file aws-container-stack/exam-score-ml-stack_v3.yml \
--stack-name exam-score-ml \
--region $(aws configure get region) \
--parameter-overrides \
BucketName=exam-score-ml-data-20260901-12345 \
KeyName=exam-score-server-key \
MyIp="$(curl -s https://checkip.amazonaws.com | tr -d '\n')/32" \
--capabilities CAPABILITY_IAM

# Authenticate docker -> log docker into the registry
aws ecr get-login-password --region $(aws configure get region) | docker login --username AWS --password-stdin $(aws sts get-caller-identity --query Account --output text).dkr.ecr.$(aws configure get region).amazonaws.com/exam-score-ml/exam-score-api

# Tag Docker Image
docker tag my-docker-app:latest $(aws sts get-caller-identity --query Account --output text).dkr.ecr.$(aws configure get region).amazonaws.com/exam-score-ml/exam-score-api:latest

# Push Docker Image
docker push $(aws sts get-caller-identity --query Account --output text).dkr.ecr.$(aws configure get region).amazonaws.com/exam-score-ml/exam-score-api:latest

# Test locally
## Pull Docekr Image
docker pull $(aws sts get-caller-identity --query Account --output text).dkr.ecr.$(aws configure get region).amazonaws.com/exam-score-ml/exam-score-api:latest