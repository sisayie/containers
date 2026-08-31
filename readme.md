# Containers in AWS

## Step 1. Preparation

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

---

## Step 2. Create Containerized Application
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

---
## Step 3. Upload the Image to Amazon ECR Repository
ECR repositories are where Docker images are stored.

### 3.1 Create Amazon ECR Repository
Next task is to create a private container registry in AWS.

You can do this through the AWS Console, or with the AWS CLI.

Using the CLI:
```
aws ecr create-repository \
  --repository-name my-docker-app \
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
You should receive:

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
```
REPOSITORY
my-docker-app

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

### 3.5 Pull the Docker image from Amazon ECR
You can pull docker images stored in Amazon ECR and run them on your local host or EC2 server or any other server. But before that you need set up permissions. 

**Required AWS permissions**
The IAM user/role doing this needs permissions such as:
```
ecr:GetAuthorizationToken
ecr:BatchCheckLayerAvailability
ecr:GetDownloadUrlForLayer
ecr:BatchGetImage
```
For a private ECR repository, you also need network access to ECR if you're pulling from a private environment.

Once the permissions are set, you need to authenticate like we did in step `3.2` above and run the command:
```
docker pull 123456789012.dkr.ecr.us-east-1.amazonaws.com/my-app:latest
```
Here again, you need to replace `123456789012` with your account id and the region to your region.

Verify it using `docker images`. 

Once the image is available, you can run it as we did in step `2.4` above.