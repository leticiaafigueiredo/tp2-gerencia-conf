pipeline {
    agent any

    triggers {
        githubPush()
    }

    environment {
        IMAGE_NAME = 'biblioteca-api'
        IMAGE_TAG  = "${env.BUILD_NUMBER}"
        PYTHONPATH = "${WORKSPACE}"
    }

    stages {
        stage('Build') {
            steps {
                sh 'pip3 install -r requirements.txt'
                sh 'make build'
            }
        }

        stage('Test') {
            parallel {
                stage('Unit') {
                    steps {
                        sh 'make test-unit'
                    }
                }
                stage('Integration') {
                    steps {
                        sh 'make test-integration'
                    }
                }
            }
        }

        stage('Acceptance') {
            steps {
                sh 'make test-acceptance'
            }
        }

        stage('Deploy') {
            when {
                branch 'main'
            }
            steps {
                sh 'bash scripts/deploy.sh'
            }
        }
    }

    post {
        always {
            cleanWs()
        }
        failure {
            echo 'Pipeline falhou — verificar logs.'
        }
        success {
            echo 'Pipeline concluído com sucesso.'
        }
    }
}
