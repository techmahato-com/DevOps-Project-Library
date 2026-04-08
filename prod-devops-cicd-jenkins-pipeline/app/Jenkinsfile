pipeline {
    agent any

    environment {
        APP_NAME       = "myapp-dev-app"
        AWS_REGION     = "us-east-1"
        AWS_ACCOUNT_ID = "441345502954"
        ECR_REPO       = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${APP_NAME}"
        IMAGE_TAG      = "${BUILD_NUMBER}"
        SONARQUBE_ENV  = "sonarqube-server"
        MAVEN          = "/opt/maven/bin/mvn"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Compile') {
            steps {
                dir('app') { sh '${MAVEN} clean compile -q' }
            }
        }

        stage('Unit Test') {
            steps {
                dir('app') { sh '${MAVEN} test -q' }
            }
            post {
                always {
                    junit 'app/target/surefire-reports/*.xml'
                }
            }
        }

        stage('SonarQube Scan') {
            steps {
                dir('app') {
                    withSonarQubeEnv("${SONARQUBE_ENV}") {
                        sh '${MAVEN} sonar:sonar -q'
                    }
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 10, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('OWASP Dependency Check') {
            steps {
                dir('app') {
                    sh '${MAVEN} org.owasp:dependency-check-maven:check -q'
                }
            }
            post {
                always {
                    publishHTML(target: [
                        allowMissing: true,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: 'app/target/dependency-check',
                        reportFiles: 'dependency-check-report.html',
                        reportName: 'OWASP Dependency Check'
                    ])
                }
            }
        }

        stage('Trivy FS Scan') {
            steps {
                sh 'trivy fs --exit-code 1 --severity CRITICAL,HIGH app/'
            }
        }

        stage('Build JAR') {
            steps {
                dir('app') { sh '${MAVEN} package -DskipTests -q' }
            }
        }

        stage('Docker Build') {
            steps {
                dir('app') {
                    sh 'docker build -t ${APP_NAME}:${IMAGE_TAG} .'
                }
            }
        }

        stage('Trivy Image Scan') {
            steps {
                sh 'trivy image --exit-code 1 --severity CRITICAL,HIGH ${APP_NAME}:${IMAGE_TAG}'
            }
        }

        stage('Push to ECR') {
            steps {
                sh '''
                aws ecr get-login-password --region ${AWS_REGION} | \
                  docker login --username AWS --password-stdin ${ECR_REPO}

                docker tag ${APP_NAME}:${IMAGE_TAG} ${ECR_REPO}:${IMAGE_TAG}
                docker push ${ECR_REPO}:${IMAGE_TAG}

                docker tag ${APP_NAME}:${IMAGE_TAG} ${ECR_REPO}:latest
                docker push ${ECR_REPO}:latest
                '''
            }
        }

        stage('Deploy') {
            steps {
                sh '''
                docker stop hello-service 2>/dev/null || true
                docker rm   hello-service 2>/dev/null || true
                docker run -d \
                  --name hello-service \
                  --restart unless-stopped \
                  -p 8080:8080 \
                  ${ECR_REPO}:${IMAGE_TAG}
                '''
            }
        }
    }

    post {
        success { echo "✅ Build #${BUILD_NUMBER} deployed: ${ECR_REPO}:${IMAGE_TAG}" }
        failure { echo "❌ Build #${BUILD_NUMBER} failed" }
        always  { sh 'docker image prune -f || true' }
    }
}
