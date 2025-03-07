pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "sampreethds10/weather-app"
        DOCKER_CREDENTIALS = 'docker-hub-credentials'
        GIT_CREDENTIALS = 'github-credentials'
        HELM_CHART_PATH = '$WORKDIR/weather-app-helm-chart'
    }

    stages {
        stage('Clone Git Repository') {
            steps {
                git branch: 'main', url: 'https://github.com/Sampreeth-DS/Weather-Application.git'

                script {
                    def versionFile = readFile('version.txt').trim()
                    def versionParts = versionFile.tokenize('.')
                    def majorVersion = versionParts[0].toInteger()
                    def minorVersion = versionParts[1].toInteger()

                    if (minorVersion == 9) {
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
                    sh "docker build -t $DOCKER_IMAGE:$NEW_VERSION ."
                }
            }
        }

        stage('Push Image to Docker Hub') {
            steps {
                withDockerRegistry([credentialsId: DOCKER_CREDENTIALS, url: '']) {
                    sh "docker push $DOCKER_IMAGE:$NEW_VERSION"
                    sh "docker tag $DOCKER_IMAGE:$NEW_VERSION $DOCKER_IMAGE:latest"
                    sh "docker push $DOCKER_IMAGE:latest"
                    sh "docker rmi $DOCKER_IMAGE:$NEW_VERSION"
                }
            }
        }

        stage('Approval for the deployment') {
            steps {
                script {
                    def userInput = input message: "Do you want to deploy this version?", parameters: [
                        choice(name: 'Approval', choices: ['Approve', 'Reject'], description: 'Select Approve to proceed or Reject to stop.')
                    ]

                    if (userInput == 'Reject') {
                        error("Deployment Rejected. Stopping Pipeline.")
                    }
                }
            }
        }

        stage('Deploying Application in DEV env') {
            steps {
                script {
                    try {
                        sh "helm upgrade --install weather-app $HELM_CHART_PATH -n dev -f $HELM_CHART_PATH/dev_values.yaml --set image.tag=$NEW_VERSION"
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
                    def userInput = input message: "Do you want to approve this version?", parameters: [
                        choice(name: 'Approval', choices: ['Approve', 'Reject'], description: 'Select Approve to proceed or Reject to stop.')
                    ]

                    if (userInput == 'Reject') {
                        sh "helm rollback weather-app -n dev"
                        error("Dev deployment failed! Rolling back Dev and stopping pipeline.")
                    }
                }
            }
        }

        stage('Deploying Application in TEST env') {
            steps {
                script {
                    try {
                        sh "helm upgrade --install weather-app $HELM_CHART_PATH -n test -f $HELM_CHART_PATH/test_values.yaml --set image.tag=$NEW_VERSION"
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
                    def userInput = input message: "Do you want to approve this version?", parameters: [
                        choice(name: 'Approval', choices: ['Approve', 'Reject'], description: 'Select Approve to proceed or Reject to stop.')
                    ]

                    if (userInput == 'Reject') {
                        sh "helm rollback weather-app -n test"
                        error("Test deployment failed! Rolling back Test and stopping pipeline.")
                    }
                }
            }
        }

        stage('Deploying Application in PROD env') {
            steps {
                script {
                    try {
                        sh "helm upgrade --install weather-app $HELM_CHART_PATH -n prod -f $HELM_CHART_PATH/prod_values.yaml --set image.tag=$NEW_VERSION"
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