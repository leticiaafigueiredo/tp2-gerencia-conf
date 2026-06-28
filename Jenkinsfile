pipeline {
    agent any

    triggers {
        githubPush()
    }

    environment {
        IMAGE_NAME = 'biblioteca-api'
        IMAGE_TAG  = "${env.BUILD_NUMBER}"
        PYTHONPATH = "${WORKSPACE}"
        VENV_DIR   = "${WORKSPACE}/.venv"
    }

    stages {
        stage('Build') {
            steps {
                sh '''
                    python3 -m venv "${VENV_DIR}"
                    . "${VENV_DIR}/bin/activate"
                    pip install -r requirements.txt
                    make build
                '''
            }
        }

        stage('Test') {
            parallel {
                stage('Unit') {
                    steps {
                        sh '''
                            . "${VENV_DIR}/bin/activate"
                            make test-unit
                        '''
                    }
                }
                stage('Integration') {
                    steps {
                        sh '''
                            . "${VENV_DIR}/bin/activate"
                            make test-integration
                        '''
                    }
                }
            }
        }

        stage('Acceptance') {
            steps {
                sh '''
                    . "${VENV_DIR}/bin/activate"
                    make test-acceptance
                '''
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
        failure {
            echo 'Pipeline falhou — verificar logs.'
        }
        success {
            echo 'Pipeline concluído com sucesso.'
        }
    }
}
