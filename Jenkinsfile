pipeline {
    agent any

    environment {
        JFROG_REGISTRY = 'trialf8lfmw.jfrog.io'
        JFROG_REPO = 'k3s-deploy'
        IMAGE_NAME = 'github-actions-runner'
        IMAGE_TAG = "${BUILD_NUMBER}"
        DOCKERFILE_PATH = 'Dockerfile'
        BUILD_CONTEXT = '.'
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
                    pwd
                    ls -la

                    command -v docker
                    docker --version

                    test -f "$DOCKERFILE_PATH"
                    test -f start.sh
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
                    credentialsId: 'jfrog-cred',
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
            sh 'command -v docker >/dev/null 2>&1 && docker logout "$JFROG_REGISTRY" || true'
        }
    }
}
