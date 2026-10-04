pipeline {
    agent any

    stages {

        stage('Checkout') {
            steps {
                echo 'Getting source code...'
                checkout scm
            }
        }

        stage('Build') {
            steps {
                echo 'Building application...'
                sh '/opt/jenkins-tools/app-env/bin/python3 -m py_compile app.py'
            }
        }

        stage('Test') {
            steps {
                echo 'Running tests...'
                sh '/opt/jenkins-tools/app-env/bin/python3 -m pytest -v'
            }
        }

        stage('SAST - Semgrep') {
            steps {
                echo 'Running Semgrep security scan...'
                sh '/opt/jenkins-tools/semgrep-env/bin/semgrep scan --config auto --error'
            }
        }
        stage('SCA - Trivy') {
            steps {
                echo 'Running Trivy dependency scan...'
                sh '''
                trivy fs \
                  --scanners vuln \
                  --config /dev/null \
                  --db-repository ghcr.io/aquasecurity/trivy-db \
                  --severity HIGH,CRITICAL \
                  --exit-code 1 \
                  .
                '''
            }
        }
        stage('Secret Scan - Gitleaks') {
            steps {
                echo 'Scanning for secrets...'
                sh 'gitleaks detect --source . --no-banner --redact'
            }
        }
        stage('Docker Build') {
            steps {
                echo 'Building Docker image...'
                sh 'docker build -t jenkins-devsecops-lab:${BUILD_NUMBER} .'
            }
        }
        stage('Container Scan - Trivy') {
            steps {
                echo 'Scanning Docker image for vulnerabilities...'
                sh '''
                    trivy image \
                      --severity HIGH,CRITICAL \
                      --exit-code 1 \
                      jenkins-devsecops-lab:${BUILD_NUMBER}
                '''
            }
        }
       stage('Push Image') {
    steps {
        echo 'Pushing Docker image to Docker Hub...'

        withCredentials([
            usernamePassword(
                credentialsId: 'dockerhub-credentials',
                usernameVariable: 'DOCKERHUB_USER',
                passwordVariable: 'DOCKERHUB_TOKEN'
            )
        ]) {
            sh '''
                echo "$DOCKERHUB_TOKEN" | docker login \
                    -u "$DOCKERHUB_USER" \
                    --password-stdin

                docker tag jenkins-devsecops-lab:${BUILD_NUMBER} \
                    ${DOCKERHUB_USER}/jenkins-devsecops-lab:${BUILD_NUMBER}

                docker tag jenkins-devsecops-lab:${BUILD_NUMBER} \
                    ${DOCKERHUB_USER}/jenkins-devsecops-lab:latest

                docker push \
                    ${DOCKERHUB_USER}/jenkins-devsecops-lab:${BUILD_NUMBER}

                docker push \
                    ${DOCKERHUB_USER}/jenkins-devsecops-lab:latest

                docker logout
            '''
        }
    }
}
        stage('Deploy - Docker Compose') {
            steps {
                echo 'Deploying application with Docker Compose...'
        
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-credentials',
                        usernameVariable: 'DOCKERHUB_USER',
                        passwordVariable: 'DOCKERHUB_TOKEN'
                    )
                ]) {
                    sh '''
                        echo "$DOCKERHUB_TOKEN" | docker login \
                            -u "$DOCKERHUB_USER" \
                            --password-stdin
        
                        export DOCKERHUB_USER="$DOCKERHUB_USER"
                        export IMAGE_TAG="${BUILD_NUMBER}"
        
                        docker compose pull
                        docker compose up -d
        
                        docker compose ps
        
                        docker logout
                    '''
                }
            }
        }
       stage('Post-Deployment Test') {
            steps {
                echo 'Waiting for application to become healthy...'
        
                sh '''
                    for i in $(seq 1 12); do
                        STATUS=$(docker inspect \
                            --format='{{.State.Health.Status}}' \
                            devsecops-app 2>/dev/null || true)
        
                        echo "Health status: $STATUS"
        
                        if [ "$STATUS" = "healthy" ]; then
                            echo "Application is healthy."
                            exit 0
                        fi
        
                        if [ "$STATUS" = "unhealthy" ]; then
                            echo "Application is unhealthy."
                            docker logs devsecops-app
                            exit 1
                        fi
        
                        sleep 5
                    done
        
                    echo "Application did not become healthy within 60 seconds."
                    docker logs devsecops-app
                    exit 1
                '''
        
                sh '''
                    curl --fail --silent http://localhost:8080/health
                    echo
                    echo "External health check passed."
                '''
            }
        }
            }
        }
