pipeline {
    agent { label "worker1" }

    
    stages {
        
        
        stage('checkoutcode') {
            steps {
                echo "******CHECKING OUT REPOSITORY********"
                git url: 'https://github.com/krishmint/three-tier-architecture-demo.git',
                branch: 'main'
            }
        }
        
        stage('SonarQube Quality Analysis') {
            steps {
                
            }
        }
        
        
        stage('Sonar Quality Gate Scan') {
            steps {
               
            }
        }
        
        stage('OWASP Dependency Check') {
            steps {
                
            }
        }
        
        
        stage('Trivy File System Scan') {
            steps {
               
            }
        }
        
        stage('update k8s helm') {
            environment {
             GIT_REPO_NAME = "three-tier-architecture-demo.git"
             GIT_USER_NAME = "krishmint"
             BUILD_NUMBER=${BUILD_NUMBER}
          }
            steps {
                script {
                    withCredentials([string(credentialsId: 'GITHUBCRED', variable: 'GITHUB_TOKEN')]) {
                        sh '''
                        sed -i "s|version:.*|version: ${BUILD_NUMBER}|g" AKS/helm/values.yaml
                        sed -i "s|TAG=.*|TAG=${BUILD_NUMBER}|g" .env 
                        cat AKS/helm/values.yaml
                        cat .env
                        git add .
                        git commit -m 'Update Kubernetes manifest'
                        git remote -v
                        git push https://${GITHUB_TOKEN}@github.com/${GIT_USER_NAME}/${GIT_REPO_NAME} HEAD:main
                        '''
                    }
                }
                
                
            }
        }
        
        
        stage('docker compose build') {
            steps {
                echo "*******BUILDING DOCKER IMAGES********"
                sh "docker-compose build"
                echo "**********FINISHED BUILDING DOCKER IMAGES*******"
                
            }
        }
        
        
        stage('trivy image scan') {
            steps {
                
            }
        }
        
        stage('docker compose push') {
              steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'DOCKERHUBCRED', usernameVariable: "DOCKERHUBUSER", passwordVariable: 'DOCKERHUBPASS')]) {
                     sh '''
                     echo "******PUSHING DOCKER IMAGES******"
                     docker login -u ${DOCKERHUBUSER} -p ${DOCKERHUBPASS}
                     docker-compose push
                     echo "*****IMAGES PUSHED SUCCESSFULLY******"
                     
                     '''
                     }
                    
                }
                
              }
            
         }
        
        
        
        
        
    }
}
