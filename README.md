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

![alt text](https://github.com/gauravkothiyal/graylog-take-home/blob/master/Infra.png?raw=true)
# Getting Started
This getting started guide will help you deploy Hello Graylog app to eks cluster.

## Prerequisites
1. Terraform code is executed from an Amazon Linux2 backed EC2 instance with the correct permissions.
2. Ensure that you have installed the following tools on the EC2 instance.

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) |  0.14.11 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.66.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.4.1 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | >= 1.18.0 |
| <a name="requirement_docker"></a> [docker](#requirement\_docker) | 3.1.0 |
3. Route53 domain ID e.g.  Domain id: ZEDELALDDN, domain name graylogtest.com.
4. A wildcard acm certificate for the Route53 domain e.g. *graylogtest.com
5. Route53 dns record for the app. e.g. test.graylogtest.com

## Tools installation
```bash
cd /tmp
```
Terraform install
```bash
curl -O https://releases.hashicorp.com/terraform/0.14.11/terraform_0.14.11_linux_amd64.zip
unzip terraform_0.14.11_linux_amd64.zip 
chmod a+x terraform
sudo mv terraform /usr/bin/
terraform version
```
Helm install
```bash
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
```
kubectl install
```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```
docker install and start service
```bash
sudo yum install git -y
sudo amazon-linux-extras install docker -y
sudo usermod -a -G docker ec2-user
sudo systemctl start docker
```
Log out and log back in again to pick up the new docker group permissions. You can accomplish this by closing your current SSH terminal window and reconnecting to your instance in a new one. Your new SSH session will have the appropriate docker group permissions.

## Configuration
Clone the git repo
```bash
git clone https://github.com/gauravkothiyal/graylog-take-home.git
```
Change directory to graylog-take-home/terraform
```bash
cd graylog-take-home/terraform
```

At a minimum the following input variables needs to change in variables.tf Uncomment # default and add the new values:
| Name                      | Description                        | Default  |
| ------------------------- | ---------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `acm`            | AWS Certificate certificate arn for the domain   | `""` |                                 |
| `region`              | The AWS Region to deploy EKS       | `us-east-1` |
| `route53_domain`      |  route53 domain ID where the dns record for the k8s will be created. For example ZP2XDW6HJBXZT | `""`   |
| `app_dns_name`             | Route53 dns record name. graylog.DOMAIN-NAME.com. Where the domain name depends on route53_domain above  | `""`           |
| `app_version`             | Docker image version  | `1.0.0`           |

### Terraform

Once the variables.tf file is updated run the following commands: 

```bash
terraform init
terraform plan
terraform apply --auto-approve=true
```
This might take around 20 minutes the provision all the resources. After terraform apply is successful curl the `app_dns_name` name that was defined in the variables.tf. It will be part of the outputs as `app_url_endpoint`
```bash

Outputs:

app_url_endpoint = "https://graylog-gk.*********.com"

curl https://graylog.DOMAIN-NAME.com
```
### Cleaning up

You can destroy this cluster entirely by running:

```bash
terraform plan -destroy
terraform destroy  --force
```
