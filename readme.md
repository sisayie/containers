# Containers in AWS
<details>

<summary>

## Step 1. Preparation

</summary>

### 1.1 Install Required Tools:

* Docker
* AWS CLI -- refer to step [1.1](https://github.com/sisayie/exam-score-prediction/blob/main/README.md)
* An AWS account

Verify Docker:

`docker --version`

Verify AWS CLI:

`aws --version`

### 1.2 Configure your AWS credentials

`aws configure`

Enter the following when prompted:

```
AWS Access Key ID:
AWS Secret Access Key:
Default region name:
Default output format:
```
For example:

Default region name: us-east-1

Default output format: json

>**Security tip:** don't put AWS access keys directly into your Dockerfile or source code.

</details>

---
<details>

<summary>

## Step 2. Create Containerized Application

</summary>

### 2.1 Create the app
Create a directory:

```
mkdir my-docker-app
cd my-docker-app

```

- Create `requirement.txt` file that should contain the dependencies. For this example the dependency is: `Flask==3.1.2`

- Create a simple python app and save it as `app.py`

```python
print("Hello from Docker on AWS!")
```
### 2.2 Create the Dockerfile

Create a file named:

`Dockerfile`

Put this inside:

```
FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 5000

CMD ["python", "app.py"]
```

### 2.3 Build the Docker image

Run:

`docker build -t my-docker-app .`

Check that the image exists:

`docker images`

You should see something similar to:
```
REPOSITORY      TAG       IMAGE ID       CREATED
my-docker-app   latest    abc123...      ...
```
### 2.4. Run the Container
Before involving AWS, make sure the container works.

Run:

`docker run -p 5000:5000 my-docker-app`

Then open:

`http://localhost:5000`

You should see:
```
Hello from Docker on AWS!
```
You can stop the container with: `Ctrl+C`

</details>

---

<details>

<summary>

## Step 3. Upload the Image to Amazon ECR Repository

</summary>

ECR repositories are where Docker images are stored.

### 3.1 Create Amazon ECR Repository
Next task is to create a private container registry in AWS.

You can do this through the AWS Console, or with the AWS CLI.

Using the CLI:
```
aws ecr create-repository \
  --repository-name my-docker-repo \
  --region us-east-1
```
AWS will return information about the repository.

Your ECR repository will have URI (an address) similar to:

`123456789012.dkr.ecr.us-east-1.amazonaws.com/my-docker-app`

The exact account ID and region will be different for your AWS account.

### 3.2. Authenticate Docker with ECR
Docker needs permission to push images to your ECR repository.

Run:
```
aws ecr get-login-password --region us-east-1 | \
docker login \
--username AWS \
--password-stdin 123456789012.dkr.ecr.us-east-1.amazonaws.com
```
If you are using a specific profile, use the command:
```
aws ecr get-login-password \
  --region us-east-1 \
  --profile my-profile \
  | docker login \
      --username AWS \
      --password-stdin 123456789012.dkr.ecr.eu-central-1.amazonaws.com
```

If login is successful, you should receive:

`Login Succeeded`

Replace:

`123456789012` with your AWS account ID. 

You can retrieve your account ID with:

`aws sts get-caller-identity`

### 3.3. Tag the Docker image
ECR expects the image to be tagged with the ECR repository address.

For example:
```
docker tag my-docker-app:latest \
123456789012.dkr.ecr.us-east-1.amazonaws.com/my-docker-app:latest
```
You can verify it:

`docker images`

You should now have something like:

REPOSITORY my-docker-app
```
123456789012.dkr.ecr.us-east-1.amazonaws.com/my-docker-app
```

### 3.4. Push the image to Amazon ECR
Now push it:
```
docker push \
123456789012.dkr.ecr.us-east-1.amazonaws.com/my-docker-app:latest
```
Docker will upload several layers:
```
The push refers to repository [...]
...
latest: digest: sha256:...
```
Congratulations! 

Your Docker image is now stored in Amazon ECR.

You can view it listed in:

**AWS Console** → **ECR** → **Repositories**

</details>

---

<details>

<summary>

## Step 4. Running the Container

</summary>

### 4.1 Running the Container on local machine

Pull the Docker image from Amazon ECR. 

You can pull docker images stored in Amazon ECR and run them on your local host or any other server. 

Because your have already set up your credentials on your local machine, you can just run
```
docker pull 123456789012.dkr.ecr.us-east-1.amazonaws.com/my-app:latest
```

You can then run it using as you did in step `2.4` above.

---
### 4.2 Running the Container on on EC2 or other server
You can pull docker images stored in Amazon ECR and run them on EC2 server. But before that you need set up permissions. 

**Required AWS permissions**
The IAM user/role doing this needs permissions such as:
```
ecr:GetAuthorizationToken
ecr:BatchCheckLayerAvailability
ecr:GetDownloadUrlForLayer
ecr:BatchGetImage
```
For a private ECR repository, you also need network access to ECR if you are pulling from a private environment.

Once the permissions are set, you need to authenticate like we did in step `3.2` above and run the command:
```
docker pull 123456789012.dkr.ecr.us-east-1.amazonaws.com/my-app:latest
```
Here again, you need to replace `123456789012` with your account id and the region to your region. Or you can use command substitution ;)

Verify it using `docker images`. 

Once the image is available, you can run it as we did in step `2.4` above.

Summing it up, to run the container, you need to pull the Docker image from Amazon ECR. 

- Make sure the docker image is on ECR. If not, push it using `Step 3`
- Set up EC2 and associated infrastructure
- Prepare the EC2 using the information in `Step 1`. If you already set up IAM (e.g., using stack_v2.yml from the session on IaC), only do step `1.1` and skip step `1.2`.
- Pull the image from the registry as shown in step `4.1`

### 4.3 Running the Container using ECS

ECR is essentially your container image storage.

To actually run the container, you will use Amazon ECS.

#### 4.3.1 Create an ECS cluster
Make sure you have created an IAM role for container services.

Open the AWS Console and go to:

ECS → Clusters → Create cluster

Choose a cluster name such as:

`my-docker-cluster`

For the infrastructure, choose:

`AWS Fargate`

Create the cluster.

#### 4.3.2 Create an ECS Task Definition
An ECS task definition tells AWS how your container should run.

Go to:

**ECS** → **Task definitions** → **Create new task definition*

Choose:
```
Task definition family:
my-docker-app
```
For compute, choose a small configuration suitable for testing, for example:
```
CPU: 0.5 vCPU
Memory: 1 GB
```
Then configure the container.

Container name: `my-docker-app
`
Image URI: `123456789012.dkr.ecr.us-east-1.amazonaws.com/my-docker-app:latest`

Container port: `5000`

Create the task definition.

#### 4.3.3 Create an ECS Service
Now we need ECS to actually start the container.

Go to:

**ECS** → **Clusters** → **my-docker-cluster** → **Create**

Select your task definition: `my-docker-app`

Choose:
```
Compute options:
Launch type

Launch type:
Fargate
```

Set the desired number of tasks: `1`

For networking, select:

- Your VPC
- At least one subnet
- A security group

For a simple public test application, the task needs a public IP, so enable: `Public IP: Turn On`

#### 4.3.4 Configure the security group
Your container listens on port: `5000`

Therefore, the security group needs to allow inbound TCP traffic on port 5000.

For a quick test:
```
Type: Custom TCP
Port: 5000
Source: 0.0.0.0/0
```
>**Important:** this exposes the application publicly. That is acceptable for a temporary tutorial, but for production you would normally put the service behind an Application Load Balancer, use HTTPS, and restrict network access appropriately.

#### 4.3.5 Deploy the service
Click: **Create**

ECS will now:
```
- Start a Fargate task.
- Pull your image from ECR.
- Create the container.
- Start your python application.
- Assign networking to the task.
```
You should eventually see:
```
Running: 1
Desired: 1
```
#### 4.3.6 Find the Application's public IP
Go to:

**ECS** → **Cluster** → **Service** → **Tasks**

Click the running task.

Find: `Public IP`

For example, assuming the public IP you found is `3.120.50.100`, you need to open `http://3.120.50.100:5000`

You should see:

`Hello from Docker on AWS!`

The application is running inside a container.

You have deployed your Docker container to AWS!

</details>
