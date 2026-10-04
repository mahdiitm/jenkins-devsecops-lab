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
                sh 'python3 -m py_compile app.py'
            }
        }

        stage('Test') {
            steps {
                echo 'Running tests...'
                sh 'python3 -m pytest -v'
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
                  .
                '''
    }
}
    }
}
