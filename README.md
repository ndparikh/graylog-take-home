# Hello Graylog! Infrastructure in Terraform
This repository contains the source code for a Terraform templates to deploy Hello GrayLog app to EKS cluster.
## Repository directory layout

    .
    ├── teraform            # Terraform templates
    ├── app                 # Simple nginx app
    └── README.md

In the terraform directory you will see the following files:

| Terraform files | Purpose |
| --------------- | --------------- |
| vpc.tf | Provisions a VPC, subnets and availability zones |
| data.tf | Choose right subnets, ami id etc for eks |
| docker_image.tf | Build and push docker image to ECR repo |
| ecr.tf | Create an ecr repository  |
| eks.tf | Provisions all the resources (IAM Role, Security Groups etc...) required to set up an EKS cluster |
| iam.tf | Create IAM roles that are used by eks node groups |
| node-workers.tf| Create self managed node group for eks|
| security_group.tf | Security group that allows access within the VPC |
| providers.tf | Providers used by terraform  |
| variables.tf | Variables used by terraform templates |
| output.tf | defines the output configuration  |
