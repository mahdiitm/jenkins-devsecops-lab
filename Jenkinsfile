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
            }
        }
