# Hello Graylog! Infrastructure in Terraform
This repository contains the source code for a Terraform templates to deploy Hello GrayLog app to EKS cluster.
## Repository directory layout

    .
    ├── teraform            # Terraform templates
    ├── helm                # Helm charts to deploy cluster components
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
| helm.tf | Install cluster components like external dns, cluster autoscaler, ALB controller etc need to run the app |
| iam.tf | Create IAM roles that are used by eks node groups |
| node-workers.tf| Create self managed node group for eks|
| security_group.tf | Security group that allows access within the VPC |
| providers.tf | Providers used by terraform  |
| variables.tf | Variables used by terraform templates |
| output.tf | defines the output configuration  |

The code above will provision the following: \
✅  Amazon VPC with 2 private and public subnets.\
✅  Internet Gateway for public subnets and 2 NAT gateways with EIP attached for each private subnets .\
✅  Security Groups, Route Tables and Route Table Associations .\
✅  IAM roles, instance profiles and policies.\
✅  A new EKS Cluster with a self managed node group. Worker Nodes in a private Subnets and ALB in public subnets.\
✅  RDS postgres instance.\
✅  `Cluster Autoscaler` and `Metrics Server` for scaling your workloads.\
✅  `External DNS` for creating route53 entries.\
✅  `AWS Load Balancer Controller` for ingress and distributing traffic.\
✅  `Route53` dns for accessing the app.
