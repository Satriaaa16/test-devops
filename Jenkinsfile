pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                // Checkout code from version control
                checkout scm
            }
        }
        stage('Build') {
            steps {
                // Build your project
                sh 'go --version'
            }
        }
        stage('Test') {
            steps {
                // Run tests
                sh 'go test -run main_test.go'
            }
        }
        stage('code') {
            steps {
                // run the code
                sh './deploy.sh'
            }
        }
    }
}

