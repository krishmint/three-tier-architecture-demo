### create aws infra( vpc with  public +private subnet , attach nat-gateway and load balancer for  and deploy ec2 in private subnet )


##### terraform block

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.45.0"
    }
  }
}


