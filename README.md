## Deployment Guide

### Project Dependencies
1. Install `eksctl`, `aws-cli`, and `kubectl`.

### Build CI Process
1. Create Dockerfile:
- Utilize the `python:3.10-slim-buster` base image for the Python-based application.
- Specify the working directory as `/app`.
- Copy the `requirements.txt` file from the source code to the workingdirectory.
- Install Python dependencies.
- Copy all Python source code to the working directory.
- Run the application with the `python` command.

2. Create `buildspec.yaml` file:
- Obtain AWS password and log in to Docker to use ECR as the image repository.
```
aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com
```
- Build the source code into an image:
```
docker build -t $IMAGE_REPO_NAME:$CODEBUILD_BUILD_NUMBER .
docker tag $IMAGE_REPO_NAME:$CODEBUILD_BUILD_NUMBER $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:$CODEBUILD_BUILD_NUMBER
```
- Push the built Docker image to ECR:
```
 docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:$CODEBUILD_BUILD_NUMBER
```

3. Create ECR Repository:
Create an Amazon ECR repository in your AWS console.

4. Create CodeBuild Project:
- Source: Select GitHub and choose the repository containing the analytics application.
- Enter `analytics/buildspec.yaml` in Buildspec.
- Enable auto-build when there are new code changes on the GitHub repository or manually start the build.
- After successful build, view the image in the ECR repository.

### Deployment Steps
1. Create EKS Cluster:
`eksctl create cluster --name my-cluster --region us-east-1 --nodegroup-name my-nodes --node-type t3.small --nodes 1 --nodes-min 1 --nodes-max 2`

Connect EKS with local kubectl `aws eks --region us-east-1 update-kubeconfig --name my-cluster`

After done, delete cluster by below command
`eksctl delete cluster --name my-cluster --region us-east-1`

2. Add cloudwatch to the EKS cluster:
- Add new policy `CloudWatchAgentServerPolicy` to EKS Node group role:
`aws iam attach-role-policy --role-name eksctl-my-cluster-nodegroup-my-nod-NodeInstanceRole-jXNNFVvKvpkJ --policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy`

- Add addon cloudwatch to EKS:
`aws eks create-addon --cluster-name my-cluster --addon-name amazon-cloudwatch-observability`

3. Deploy database:
Navigate to the `db` folder inside the repository. 
Review and update the database info inside file `postgresql-deployment.yaml` if needed: POSTGRES_DB, POSTGRES_USER, POSTGRES_PASSWORD
Run the following commands to deploy the PostgreSQL database:
`kubectl apply -f pvc.yaml`
`kubectl apply -f pv.yaml`
`kubectl apply -f postgresql-deployment.yaml`
`kubectl apply -f postgresql-service.yaml`


Connect to the database and run the scripts `1_create_tables.sql`, `2_seed_users.sql`, and `3_seed_tokens.sql` to create test data.

4. Create config map:
Go to the folder deployment
Update the value for below variables: DB_HOST, DB_PORT, DB_USERNAME, DB_PASSWORD, DB_NAME inside file `configmap.yaml`.

Run command to create secret: `kubectl apply -f configmap.yaml`

5. Create secret:
Navigate to the `deployment` folder. Update the password value to match with `db-password` inside `secret.yaml`. 
Run the command to create the secret:
`kubectl apply -f secret.yaml`

6. Deploy Coworking Application:
Whenever there's a new version of the code, change the version in the `image` section. 
Then, deploy the application with:
`kubectl apply -f coworking.yaml`

### Verify
Retrieve all services deployed to the cluster:
`kubectl get svc`

Retrieve all pods:
`kubectl get pods`

You can also check application logs from CloudWatch.

## Stand-Out Suggestions
1. Specify Reasonable Memory and CPU Allocation in Kubernetes Deployment Configuration:
   Start with 2 CPU and 2 GB RAM for development environment. Adjust based on the workload in production.

2. Provide Recommendations for AWS Instance Type:
   For development, use `t3a.small` as it's cost-effective. For production, consider larger `t3a` instances.

3. Cost-Saving Strategies:
   - Select appropriate instance types.
   - Implement autoscaling for the EKS cluster.
   - Set up CloudWatch log retention to 15 days for cost-effective issue investigation.
