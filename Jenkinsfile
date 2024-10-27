pipeline {
    agent { label "worker1" }

    environment {
        SONAR_HOME = tool "sonar"
        BUILD_NUMBER="${BUILD_NUMBER}"
    }

    
    stages {

        stage("Workspace cleanup"){
            steps{
                script{
                    cleanWs()
                }
            }
        }

        
        
        stage('checkoutcode') {
            steps {
                echo "******CHECKING OUT REPOSITORY********"
                git url: 'https://github.com/krishmint/three-tier-architecture-demo.git',
                branch: 'master'
            }
        }
        
        stage('SonarQube Code Quality Analysis') {
            steps {
                withSonarQubeEnv("sonar"){
                sh "$SONAR_HOME/bin/sonar-scanner -Dsonar.projectName=ultimatecicd -Dsonar.projectKey=ultimatecicd -Dsonar.exclusions=**/*.java -X"
                       
                echo "***SonarQube Quality Analysis PASSED***"
                }
                
            }
        }
        
        
        stage('Sonar Quality Gate Scan') {
            steps {
                timeout(time: 1, unit: "MINUTES"){
                waitForQualityGate abortPipeline: false
                echo "***SonarQube Quality Gate Scan PASSED ***"
               
            }
        }
        
        stage('OWASP Dependency Check') {
            steps {
                dependencyCheck additionalArguments: '--scan ./', odcInstallation: 'OWASP'
                dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
                echo "********OWASP Dependency Check PASSED*********"
                
            }
        }
        
        
        stage('Trivy File System Scan') {
            steps {
               sh "trivy fs -o filesystemcheckreport.html ."
               echo "*********Trivy File System Scan PASSED*********"
            }
        }
        
        stage('update k8s helm') {
            environment {
             GIT_REPO_NAME = "three-tier-architecture-demo"
             GIT_USER_NAME = "krishmint"
             
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
                sh '''
                sudo docker images --format "{{.Repository}}:{{.Tag}}" | grep "krishmint:${BUILD_NUMBER}" | xargs -I {} trivy image -o imageScanreport.html {}
                '''
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
