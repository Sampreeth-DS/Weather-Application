pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "sampreethds10/weather-app"
        DOCKER_CREDENTIALS = 'docker-hub-credentials'
        GIT_CREDENTIALS = 'github-credentials'
        HELM_CHART_PATH = './Weather-App-Helm-Chart'
    }

    stages {
        stage('Clone Git Repository') {
            steps {
                checkout scm

                script {
                    def versionFile = readFile('version.txt').trim()
                    def versionParts = versionFile.tokenize('.')
                    def majorVersion = versionParts[0].toInteger()
                    def minorVersion = versionParts[1].toInteger()

                    if (minorVersion == 10) {
                        majorVersion += 1
                        minorVersion = 0
                    } else {
                        minorVersion += 1
                    }

                    def newVersion = "${majorVersion}.${minorVersion}"
                    writeFile file: 'version.txt', text: newVersion
                    env.NEW_VERSION = newVersion
                    echo "New Docker Image Version: $NEW_VERSION"
                }

                withCredentials([usernamePassword(credentialsId: GIT_CREDENTIALS, usernameVariable: 'GIT_USER', passwordVariable: 'GIT_PASS')]) {
                    script {
                        sh """
                            git config --global user.email "sampreethdsgowda@gmail.com"
                            git config --global user.name "Sampreeth"
                            git add version.txt
                            git commit -m "Update version to $NEW_VERSION"
                            git push https://$GIT_USER:$GIT_PASS@github.com/Sampreeth-DS/Weather-Application.git HEAD:main
                        """
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    try {
                        sh "docker build -t $DOCKER_IMAGE:$NEW_VERSION ."
                    }
                    catch (Exception e) {
                        echo "Error while building the image!!!"
                        error("Stopping pipeline due to image build failure.")
                    } 
                }
            }
        }

        stage('Push Image to Docker Hub') {
            steps {
                script {
                    try {
                        withDockerRegistry([credentialsId: DOCKER_CREDENTIALS, url: '']) {
                            sh """
                            docker push $DOCKER_IMAGE:$NEW_VERSION
                            docker tag $DOCKER_IMAGE:$NEW_VERSION $DOCKER_IMAGE:latest
                            docker push $DOCKER_IMAGE:latest
                            docker rmi $DOCKER_IMAGE:$NEW_VERSION
                            """
                        }
                    } catch (Exception e) {
                        echo "Error while pushing image to Docker Hub!!!"
                        error("Stopping pipeline due to Docker push failure.")
                    }
                }
            }
        }

        stage('Approval for the deployment') {
            steps {
                script {
                    input message: "Approve deployment to the DEV for version $NEW_VERSION?"
                }
            }
        }

        stage('Deploying Application in DEV env') {
            steps {
                script {
                    try {
                        sh "helm upgrade --install weather-app $HELM_CHART_PATH -n dev -f $HELM_CHART_PATH/dev_values.yaml --set image.tag=$NEW_VERSION"
                        sleep(30)

                        if (sh(script: "curl -s -o /dev/null -w \"%{http_code}\" http://192.168.49.2:31001", returnStdout: true).trim() != "200") {
                            sh "helm rollback weather-app -n dev"
                            error("Deployment failed! Rolling back.")
                        }
                    }
                    catch (Exception e) {
                        sh "helm rollback weather-app -n dev"
                        error("Dev deployment failed! Rolling back Dev and stopping pipeline.")
                    }
                }
            }
        }

        stage('Approval from the DEV team') {
            steps {
                script {
                    input message: "Approve deployment to the TEST for version $NEW_VERSION?"
                }
            }
        }

        stage('Deploying Application in TEST env') {
            steps {
                script {
                    try {
                        sh "helm upgrade --install weather-app $HELM_CHART_PATH -n test -f $HELM_CHART_PATH/test_values.yaml --set image.tag=$NEW_VERSION"
                        sleep(30)

                        if (sh(script: "curl -s -o /dev/null -w \"%{http_code}\" http://192.168.49.2:31002", returnStdout: true).trim() != "200") {
                            sh "helm rollback weather-app -n test"
                            error("Deployment failed! Rolling back.")
                        }
                    }
                    catch (Exception e) {
                        sh "helm rollback weather-app -n test"
                        error("Test deployment failed! Rolling back Test and stopping pipeline.")
                    }
                }
            }
        }

        stage('Approval from TEST team') {
            steps {
                script {
                    input message: "Approve deployment to the PROD for version $NEW_VERSION?"
                }
            }
        }

        stage('Deploying Application in PROD env') {
            steps {
                script {
                    try {
                        sh "helm upgrade --install weather-app $HELM_CHART_PATH -n prod -f $HELM_CHART_PATH/prod_values.yaml --set image.tag=$NEW_VERSION"
                        sleep(30)

                        if (sh(script: "curl -s -o /dev/null -w \"%{http_code}\" http://192.168.49.2:31003", returnStdout: true).trim() != "200") {
                            sh "helm rollback weather-app -n prod"
                            error("Deployment failed! Rolling back.")
                        }
                    }
                    catch (Exception e) {
                        sh "helm rollback weather-app -n prod"
                        error("Prod deployment failed! Rolling back Prod and stopping pipeline.")
                    }
                }
            }
        }
    }
}