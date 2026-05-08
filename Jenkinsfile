pipeline {
    agent any

    environment {
        JFROG_REGISTRY = 'trialf8lfmw.jfrog.io'
        JFROG_REPO = 'docker-local-docker'
        IMAGE_NAME = 'github-actions-runner'
        IMAGE_TAG = "${BUILD_NUMBER}"
        DOCKERFILE_PATH = 'Dockerfile'
        BUILD_CONTEXT = '.'
        K8S_MANIFEST = 'k8s/deployment.yaml'
        K8S_NAMESPACE = 'github-runner'
        K8S_DEPLOYMENT = 'github-actions-runner'
        K8S_CONTAINER = 'github-actions-runner'
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
                    test -f "$K8S_MANIFEST"
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

        stage('Deploy To k3s') {
            steps {
                withCredentials([
                    file(credentialsId: 'k3s-kubeconfig', variable: 'KUBECONFIG_FILE'),
                    string(credentialsId: 'github-runner-token', variable: 'GITHUB_RUNNER_TOKEN'),
                    usernamePassword(
                        credentialsId: 'jfrog-cred',
                        usernameVariable: 'JFROG_USER',
                        passwordVariable: 'JFROG_PASS'
                    )
                ]) {
                    sh '''
                        command -v kubectl
                        kubectl version --client

                        export KUBECONFIG="$KUBECONFIG_FILE"

                        kubectl create namespace "$K8S_NAMESPACE" \
                          --dry-run=client \
                          -o yaml | kubectl apply -f -

                        kubectl -n "$K8S_NAMESPACE" create secret generic github-runner-secret \
                          --from-literal=RUNNER_TOKEN="$GITHUB_RUNNER_TOKEN" \
                          --dry-run=client \
                          -o yaml | kubectl apply -f -

                        kubectl -n "$K8S_NAMESPACE" create secret docker-registry jfrog-registry-secret \
                          --docker-server="$JFROG_REGISTRY" \
                          --docker-username="$JFROG_USER" \
                          --docker-password="$JFROG_PASS" \
                          --dry-run=client \
                          -o yaml | kubectl apply -f -

                        kubectl apply -f "$K8S_MANIFEST"

                        kubectl -n "$K8S_NAMESPACE" set image \
                          "deployment/$K8S_DEPLOYMENT" \
                          "$K8S_CONTAINER=$FULL_IMAGE"

                        kubectl -n "$K8S_NAMESPACE" rollout status \
                          "deployment/$K8S_DEPLOYMENT" \
                          --timeout=180s
                    '''
                }
            }
        }
    }

    post {
        always {
            sh 'command -v docker >/dev/null 2>&1 && docker logout "$JFROG_REGISTRY" || true'
        }
    }
}
