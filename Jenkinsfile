pipeline {
    agent any

    environment {
        AWS_REGION      = 'us-east-2'
        FRONTEND_REPO   = '<your-frontend-ecr-url>'
        BACKEND_REPO    = '<your-backend-ecr-url>'
        CLUSTER_NAME    = 'devops-challenge-cluster'
        FRONTEND_SVC    = 'devops-challenge-frontend-service'
        BACKEND_SVC     = 'devops-challenge-backend-service'
    }

    stages {

        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Images') {
            steps {
                script {
                    sh 'docker build -t frontend:latest ./frontend'
                    sh 'docker build -t backend:latest ./backend'
                }
            }
        }

        stage('Authenticate to ECR') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-credentials'
                ]]) {
                    script {
                        sh '''
                            aws ecr get-login-password --region $AWS_REGION \
                                | docker login --username AWS --password-stdin $FRONTEND_REPO

                            aws ecr get-login-password --region $AWS_REGION \
                                | docker login --username AWS --password-stdin $BACKEND_REPO
                        '''
                    }
                }
            }
        }

        stage('Tag and Push to ECR') {
            steps {
                script {
                    sh '''
                        docker tag frontend:latest $FRONTEND_REPO:latest
                        docker tag backend:latest $BACKEND_REPO:latest

                        docker push $FRONTEND_REPO:latest
                        docker push $BACKEND_REPO:latest
                    '''
                }
            }
        }

        stage('Update ECS Services') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-credentials'
                ]]) {
                    script {
                        sh '''
                            aws ecs update-service \
                                --cluster $CLUSTER_NAME \
                                --service $FRONTEND_SVC \
                                --force-new-deployment \
                                --region $AWS_REGION

                            aws ecs update-service \
                                --cluster $CLUSTER_NAME \
                                --service $BACKEND_SVC \
                                --force-new-deployment \
                                --region $AWS_REGION
                        '''
                    }
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}