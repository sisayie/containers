########################
# Prepare the system
########################

#----------------------
# 1. Update cache and instll aws cli
#----------------------
sudo apt update

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt install unzip -y
unzip awscliv2.zip
sudo ./aws/install

# aws iam attach-role-policy \
#   --role-name exam-score-ml-ExamScoreServerRole-PQb9nKLHVkn1 \
#   --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly

#------------------------
# 2. Setup Docker
#------------------------

# Set up Docker's apt repository.
# Add Docker's official GPG key:
sudo apt update
sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt update

# Then install docker
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Make sure docker is running
# Check with sudo systemctl status docker OR start it direclty
sudo systemctl start docker

sudo usermod -aG docker ubuntu

newgrp docker

# # IAM Policy -- done it on CloudFormation
# aws iam attach-role-policy \
#   --role-name exam-score-ml-ExamScoreServerRole-PQb9nKLHVkn1 \
#   --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly

########################
# Fetch and run the container
########################

#------------------------
# 3. Authenticate docker on ECR
#------------------------

# Here you must 
# Authenticate docker -> log docker into the registry
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 339713011628.dkr.ecr.us-east-1.amazonaws.com/exam-score-ml/exam-score-api

#------------------------
# 4. Pull and run the container
#------------------------

docker run -d \
  --name my-app \
  -p 5000:5000 \
  #-e DOCKER_HOST=tcp://docker:2375 \
  339713011628.dkr.ecr.us-east-1.amazonaws.com/exam-score-ml/exam-score-api:latest