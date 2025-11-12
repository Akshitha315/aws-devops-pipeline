pipeline {
    agent any

    environment {
        AWS_REGION = 'ap-south-1'
        DOCKER_IMAGE = 'yourdockerhubusername/aws-devops-demo:latest'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/Akshitha315/aws-devops-pipeline.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh 'docker build -t $DOCKER_IMAGE .'
                }
            }
        }

        stage('Push to Docker Hub') {
            steps {
                script {
                    withCredentials([string(credentialsId: 'dockerhub-token', variable: 'DOCKERHUB_TOKEN')]) {
                        sh '''
                            echo $DOCKERHUB_TOKEN | docker login -u yourdockerhubusername --password-stdin
                            docker push $DOCKER_IMAGE
                        '''
                    }
                }
            }
        }

        stage('Deploy with Terraform') {
            steps {
                script {
                    sh '''
                        terraform init
                        terraform apply -auto-approve
                    '''
                }
            }
        }
    }

    post {
        success {
            echo 'Deployment successful!'
        }
        failure {
            echo 'Deployment failed!'
        }
    }
}
