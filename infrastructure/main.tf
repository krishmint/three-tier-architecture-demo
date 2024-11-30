## command "terraform plan" = pre check what resources will be made by the script
## command "terraform apply --auto-approve" = create the resource with auto approve so that it get approval while createing the resources

#####all the resource - vpc+2subnet+securitygroup(ingress+egress rule)+IGW+routetable+ ec2 +elasticip
##                      + s3 + EKS Cluster(master) +node group(worker)+ IAM Role + Policy attachment

## resource vpc

provider "aws" {
  region = "ap-south-1"
}

resource "aws_vpc" "v1" {      #### 'v1' act as vpc id inside terraform script
  cidr_block       = var.cidr  ## var.cidr mean terraform variable named cidr in variable.tf file 
  instance_tenancy = "default"
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "aws-vpc"
  }
}

##### resource subnets-1 inside vpc

resource "aws_subnet" "sub1" {     ## this directy creates 2 subnet by calculting cidr range automatically
  count = 2 

  vpc_id     = aws_vpc.v1.id  #### is of vpc from above is set as 'v1'
  cidr_block = cidrsubnet(aws_vpc.v1.cidr_block, 8, count.index)  ##This function calculates the CIDR block for each subnet.
  availability_zone = element(["ap-south-1a", "ap-south-1b"], count.index)  ##change availability zone acc to iam user region in aws cli
  map_public_ip_on_launch = true  ## create a static(elastic) ip and attact it to ec2
  tags = {
    Name = "aws-subnet-${count.index}"
  }
}


#### resource IGW inside vpc

resource "aws_internet_gateway" "IGW" {  ### all the req access the subnet through internet gatway
  vpc_id = aws_vpc.v1.id

  tags = {
    Name = "aws-igw"
  }
}

##### resource route table inside vpc

resource "aws_route_table" "RT" {
  vpc_id = aws_vpc.v1.id

  route {
    cidr_block = "0.0.0.0/0"    ##this signifies to select every req comming in this vpc 
    gateway_id = aws_internet_gateway.IGW.id   ###  and target it to IGW
  }
  tags = {
    Name = "aws-RT"
  }
}


##### associate the routetable with both subnets
resource "aws_route_table_association" "RT_A" {
  count = 2

  subnet_id      = aws_subnet.sub1[count.index].id
  route_table_id = aws_route_table.RT.id
}


##### create security group for vpc

resource "aws_security_group" "aws-infra-sg" {

  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.v1.id

  tags = {
    Name = "aws-infra"
  }
}

####inbound rule ( ingress) creation for http(port80) ssh(port22)
resource "aws_vpc_security_group_ingress_rule" "aws-infra_ipv4_http" {
  security_group_id = aws_security_group.aws-infra-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80    # exposing port 80 for http req
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "aws-infra_ipv4_ssh" {
  security_group_id = aws_security_group.aws-infra-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22     # exposing port 22 for ssh req 
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "alltraffic_outbound" {
  security_group_id = aws_security_group.aws-infra-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 0  # exposing all port
  ip_protocol       = "tcp"
  to_port           = 0
}



##### create  ec2 instance and associate with vpc subnet and pre created sshkey
#resource "aws_instance" "web" {
#  ami           = "ami-080e1f13689e07408"
#  instance_type = "t2.micro"
#  vpc_security_group_ids = [aws_security_group.aws-infra-sg.id]
#  subnet_id = aws_subnet.sub1[count.index].id
#  key_name = var.ssh_key_name    ## pre created ssh key name-- change it if iam user region is changed in aws cli
#  tags = {
#    Name = "aws-ec2"
#  }
#}

###create elasticip to associate it ec2
#resource "aws_eip" "elastic_ip" {
#  vpc = true
#}


#resource "aws_eip_association" "eip_assoc" {
#  instance_id   = aws_instance.web.id  # Replace with your instance resource name
#  allocation_id = aws_eip.elastic_ip.id
#}

###### create 2 s3 bucket 
#resource "aws_s3_bucket" "aws-s3" {
#  count = 2

#  bucket = "aws-infra-bucket-0398-${count.index + 1}"    ### bucket name should always be unique ans s3 is aws global resource
  
#  tags = {
#    Name        = "demobucket-${count.index + 1}"
#  }
#}


#### create EKS cluster ####

resource "aws_eks_cluster" "demo-cluster" {    ##Master control plane that manages the Kubernetes API server and other critical components
  name     = "eks-cluster"       ##  AWS manages the control plane, ensuring high availability by distributing it across multiple Availability Zones
  role_arn = aws_iam_role.demo_cluster_role.arn   ### this role will be assumed by EKS master control plane  to interact with other service as EC2-node group

  vpc_config {
    subnet_ids         = aws_subnet.sub1[*].id ## [*] signifies to select all subnet ID available at Sub1 
    security_group_ids = [aws_security_group.aws-infra-sg.id]
  }
}

resource "aws_eks_node_group" "demo-nodegroup" {     ## collection of Amazon EC2 instances that are managed as a workernode-group by controlplane/eks-cluster
  cluster_name    = aws_eks_cluster.demo-cluster.name    ##AWS manages the lifecycle of the workernode group, including updates and terminations
  node_group_name = "demo-node-group"
  node_role_arn   = aws_iam_role.demo_node_group_role.arn  ##The IAM role allows the EC2 instances in the node group to perform actions on AWS services
  subnet_ids      = aws_subnet.sub1[*].id

  scaling_config {
    desired_size = 3
    max_size     = 4   ## autoscale when needede
    min_size     = 3
  }

  instance_types = ["t2.large"]

  remote_access {
    ec2_ssh_key = var.ssh_key_name  ## change ssh key acc to iam user region in aws cli config
    source_security_group_ids = [aws_security_group.aws-infra-sg.id]
  }
}

resource "aws_iam_role" "demo_cluster_role" {
  name = "demo-cluster-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",   
      "Principal": {       
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"   
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "demo_cluster_role_policy" {
  role       = aws_iam_role.demo_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"    ## a managed policy provided by AWS that grants the necessary permissions for managing EKS cluster
}

resource "aws_iam_role" "demo_node_group_role" {
  name = "demo-node-group-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"   
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

locals {
  policies = [      ##This defines a local variable policies that contains a list of the policy ARNs 
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ]
}

resource "aws_iam_role_policy_attachment" "demo_node_group_policies" {
  for_each = toset(local.policies)  ## This converts the list of policies into a set, allowing Terraform to iterate over each policy.

  role       = aws_iam_role.demo_node_group_role.name
  policy_arn = each.value
}



################### set -up terraform backed to store tf state file###############
##### req - s3 bucket with versioning enabled to store tf state file
#####     - dynamodb to lock the state file

#resource "aws_s3_bucket" "terraform_state" {
# bucket = "my-terraform-state-bucket"
#  versioning {
#    enabled = true
#  }
#  
#  lifecycle {
#    prevent_destroy = true
#  }
#}

#resource "aws_dynamodb_table" "terraform_lock" {
#  name         = "terraform-lock-table"
#  billing_mode = "PAY_PER_REQUEST"
#  hash_key     = "LockID"
#
#  attribute {
#    name = "LockID"
#    type = "S"
#  }

#  lifecycle {
#    prevent_destroy = true
#  }
#}

#terraform {
#  backend "s3" {
#    bucket         = "my-terraform-state-bucket"
#    key            = "path/to/my/key"
#    region         = "us-east-1"
#    dynamodb_table = "terraform-lock-table"
#  }
#}
