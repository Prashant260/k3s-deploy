pipeline {
    agent any

    environment {
        JFROG_REGISTRY = 'YOUR_COMPANY.jfrog.io'
        JFROG_REPO = 'docker-local'
        IMAGE_NAME = 'github-actions-runner'
        IMAGE_TAG = "${BUILD_NUMBER}"
        DOCKERFILE_PATH = 'runner/Dockerfile'
        BUILD_CONTEXT = 'runner'
        FULL_IMAGE = "${JFROG_REGISTRY}/${JFROG_REPO}/${IMAGE_NAME}:${IMAGE_TAG}"
        LATEST_IMAGE = "${JFROG_REGISTRY}/${JFROG_REPO}/${IMAGE_NAME}:latest"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Verify Docker Files') {
            steps {
                sh '''
                    test -f "$DOCKERFILE_PATH"
                    test -f "$BUILD_CONTEXT/start.sh"
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    docker build \
                      -t "$FULL_IMAGE" \
                      -t "$LATEST_IMAGE" \
                      -f "$DOCKERFILE_PATH" \
                      "$BUILD_CONTEXT"
                '''
            }
        }

        stage('Login To JFrog') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'jfrog-docker-creds',
                    usernameVariable: 'JFROG_USER',
                    passwordVariable: 'JFROG_PASS'
                )]) {
                    sh '''
                        echo "$JFROG_PASS" | docker login "$JFROG_REGISTRY" \
                          -u "$JFROG_USER" \
                          --password-stdin
                    '''
                }
            }
        }

        stage('Push Image To JFrog') {
            steps {
                sh '''
                    docker push "$FULL_IMAGE"
                    docker push "$LATEST_IMAGE"
                '''
            }
        }
    }

    post {
        always {
            sh 'docker logout "$JFROG_REGISTRY" || true'
        }
    }
}
