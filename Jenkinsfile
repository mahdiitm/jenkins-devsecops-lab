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
                sh '~/semgrep-env/bin/semgrep scan --config auto'
            }
        }
    }
}
