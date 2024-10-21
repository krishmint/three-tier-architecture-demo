#!/bin/bash

####### (chmod +x filename.sh) command to give necessary permission to script file to make it executable
####### (sh filename.sh or ./filename.sh) to run the script 

## INSTALL= AWS cli, terraform, docker, java-jenkins, Sonarq image, trivy, nexus image,
##      

set -x ## used for debugging and showing command in terminal 
set -e ##Exits the script on any command failure.
set -u ##Exits the script if an undefined variable is used.

sudo apt update  # Update package lists
sudo apt install -y unzip ## install unzip tool req for installation steps later


## check & install aws cli    ( 1st check if aws cli is installed.. if not then install)

if ! command -v aws &> /dev/null;  ##(command -v checks if 'aws' command is present send both stdout and stderr to /dev/null)
then              ##/dev/null = This is a special file (black hole). Any data written to it is discarded and disappears.) effectively silencing any output from the command.
    echo "AWS CLI is not installed. Please install it first."
    echo " aws cli installation started"
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -q awscliv2.zip
    sudo ./aws/install
    aws --version  # Verify installation 
    rm -rf awscliv2.zip ./aws  ## delete zip file after installation
fi



## install terraform(to set up k8s cluster for deployment )
if ! command -v terraform &> /dev/null;
then
    echo "installing terraform started"
    sudo apt-get install -y gnupg software-properties-common
    wget -O- https://apt.releases.hashicorp.com/gpg | \
    gpg --dearmor | \
    sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
    https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
    sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt-get update
    sudo apt-get install terraform -y
fi    





# Install Docker
if ! command -v docker &> /dev/null;
then
    echo " docker installation started"
sudo apt install -y docker.io
fi



# Install Java for jenkins
if ! command -v java  &> /dev/null;
then
    echo " java installation started"
sudo apt install -y openjdk-21-jre-headless
fi


# Add Jenkins repository and key and then install
echo " Jenkins installation started"
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update
sudo apt-get install -y jenkins


## install trivy
if ! command -v trivy  &> /dev/null;
then
    echo " trivy installation started"
sudo apt-get install wget apt-transport-https gnupg lsb-release
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install trivy -y
fi



# Add the current user to the Docker group
sudo usermod -aG docker $USER

# Apply the new group membership
newgrp docker


# Run SonarQube Docker container
echo " run sonarqube image started "
docker run -d --name sonarqube -p 9000:9000 sonarqube


# Run Nexus(artifact storage) Docker container
echo " run nexus image started "
docker run -d --name nexus -p 8081:8081 sonatype/nexus3

echo "Installation and setup complete!"
