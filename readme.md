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
### 2.4. Test the container locally
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