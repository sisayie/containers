# Containers in AWS

## Step 1. Prerequisites

Install:

* Docker
* AWS CLI
* An AWS account

Verify Docker:

`docker --version`

Verify AWS CLI:

`aws --version`

Configure your AWS credentials:

`aws configure`

You'll be asked for:

```
AWS Access Key ID:
AWS Secret Access Key:
Default region name:
Default output format:
```
For example:

Default region name: eu-central-1

Default output format: json

Security tip: don't put AWS access keys directly into your Dockerfile or source code.

## Step 2. Create a simple Docker application
### 2.1 Create the app
Create a directory:



```
mkdir my-docker-app
cd my-docker-app

```
Create a simple python app and save it as `app.py`

```python
print("Hello from Docker on AWS!")

```
### 2.2 Create the Dockerfile

Create a file named:

`Dockerfile`

Put this inside:

```
FROM node:22-alpine

WORKDIR /app

COPY . ./app

EXPOSE 8000

CMD \["python", "app.py"]
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
### 2.4. Test the container locally
Before involving AWS, make sure the container works.

Run:

`docker run -p 3000:3000 my-docker-app`

Then open:

`http://localhost:8000`

You should see:
```
Hello from Docker on AWS!
```
Stop the container with: `Ctrl+C`

## Step 3. Create an Amazon ECR repository
Next task is to create a private container registry in AWS.

You can do this through the AWS Console, or with the AWS CLI.

Using the CLI:
```
aws ecr create-repository \
  --repository-name my-docker-app \
  --region eu-central-1
```
AWS will return information about the repository.

Your ECR repository will have an address similar to:

`123456789012.dkr.ecr.eu-central-1.amazonaws.com/my-docker-app`

The exact account ID and region will be different for your AWS account.

## Step 4. Authenticate Docker with ECR
Docker needs permission to push images to your ECR repository.

Run:
```
aws ecr get-login-password --region eu-central-1 | \
docker login \
--username AWS \
--password-stdin 123456789012.dkr.ecr.eu-central-1.amazonaws.com
```
You should receive:

`Login Succeeded`

Replace:

`123456789012` with your AWS account ID.

You can retrieve your account ID with:

`aws sts get-caller-identity`

## Step 5. Tag your Docker image
ECR expects the image to be tagged with the ECR repository address.

For example:
```
docker tag my-docker-app:latest \
123456789012.dkr.ecr.eu-central-1.amazonaws.com/my-docker-app:latest
```
You can verify it:

`docker images`

You should now have something like:
```
REPOSITORY
my-docker-app

123456789012.dkr.ecr.eu-central-1.amazonaws.com/my-docker-app
```

## Step 6. Push the image to Amazon ECR
Now push it:
```
docker push \
123456789012.dkr.ecr.eu-central-1.amazonaws.com/my-docker-app:latest
```
You'll see Docker uploading several layers:
```
The push refers to repository [...]
...
latest: digest: sha256:...
```
Congratulations! 

Your Docker image is now stored in Amazon ECR.

You can view it in:

**AWS Console** → **ECR** → **Repositories** → **my-docker-app**