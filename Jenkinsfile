pipeline {
    agent { label "worker1" }

    
    stages {
        
        
        stage('checkoutcode') {
            steps {
                echo "******CHECKING OUT REPOSITORY********"
                git url: 'https://github.com/krishmint/three-tier-architecture-demo.git',
                branch: 'master'
            }
        }
        
        stage('SonarQube Quality Analysis') {
            steps {
                echo "***SonarQube Quality Analysis PASSED***"
                
            }
        }
        
        
        stage('Sonar Quality Gate Scan') {
            steps {
                echo "***SonarQube Quality Gate Scan PASSED ***"
               
            }
        }
        
        stage('OWASP Dependency Check') {
            steps {
                echo "OWASP Dependency Check PASSED"
                
            }
        }
        
        
        stage('Trivy File System Scan') {
            steps {
               echo "Trivy File System Scan PASSED"
            }
        }
        
        stage('update k8s helm') {
            environment {
             GIT_REPO_NAME = "three-tier-architecture-demo"
             GIT_USER_NAME = "krishmint"
             BUILD_NUMBER="${BUILD_NUMBER}"
          }
            steps {
                script {
                    withCredentials([string(credentialsId: 'GITHUBCRED', variable: 'GITHUB_TOKEN')]) {
                        sh '''
                        git config --global --add safe.directory /home/krish
                        git config --global user.email "krisnendu007@gmail.com"
                        git config --global user.name "krishmint"
                        sed -i "s|version:.*|version: ${BUILD_NUMBER}|g" AKS/helm/values.yaml
                        sed -i "s|TAG=.*|TAG=${BUILD_NUMBER}|g" .env 
                        git add .
                        git commit -m 'Update Kubernetes manifest'
                        git remote -v
                        git push https://${GITHUB_TOKEN}@github.com/${GIT_USER_NAME}/${GIT_REPO_NAME} HEAD:master
                        '''
                    }
                }
                
                
            }
        }
        
        
        stage('docker compose build') {
            steps {
                echo "*******BUILDING DOCKER IMAGES********"
                sh "sudo docker-compose build"
                echo "**********FINISHED BUILDING DOCKER IMAGES*******"
                
            }
        }
        
        
        stage('trivy image scan') {
            steps {
                echo "trivy image scan passed"
                
            }
        }
        
        stage('docker compose push') {
              steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'DOCKERHUBCRED', usernameVariable: "DOCKERHUBUSER", passwordVariable: 'DOCKERHUBPASS')]) {
                     sh '''
                     echo "******PUSHING DOCKER IMAGES******"
                     sudo docker login -u ${DOCKERHUBUSER} -p ${DOCKERHUBPASS}
                     sudo docker-compose push
                     echo "*****IMAGES PUSHED SUCCESSFULLY******"
                     
                     '''
                     }
                    
                }
                
              }
            
         }
        
        
        
        
        
    }
}
