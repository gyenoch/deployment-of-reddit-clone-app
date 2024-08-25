pipeline{
    agent any
    tools{
        jdk 'jdk17'
        nodejs 'node16'
    }
    
    environment {
        SCANNER_HOME=tool 'sonar-scanner'
        NVD_API_KEY = credentials('nvd-api-key')
    }

    stages {
        stage('clean workspace'){
            steps{
                cleanWs()
            }
        }

        stage('Checkout from Git'){
            steps{
                git branch: 'main', url: 'https://github.com/gyenoch/deployment-of-reddit-clone-app.git'
            }
        }

        stage("Sonarqube Analysis "){
            steps{
                withSonarQubeEnv('sonar-server') {
                    sh ''' $SCANNER_HOME/bin/sonar-scanner -Dsonar.projectName=Reddit \
                    -Dsonar.projectKey=Reddit '''
                }
            }
        }

         stage("quality gate"){
           steps {
                script {
                    waitForQualityGate abortPipeline: false, credentialsId: 'jenkins' 
                }
            } 
        }

        stage('Install Dependencies') {
            steps {
                sh "npm install"
            }
        }

        stage('OWASP FS SCAN') {
            steps {
                dependencyCheck additionalArguments: '--scan ./ --disableYarnAudit --disableNodeAudit --nvdApiKey ${NVD_API_KEY}', odcInstallation: 'DP-Check'
                dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
            }
        }

        stage('TRIVY FS SCAN') {
            steps {
                sh "trivy fs . > trivyfs.txt"
            }
        }

        stage("Docker Build & Push"){
            steps{
                script{
                   withDockerRegistry(credentialsId: 'docker', toolName: 'docker'){   
                       sh "docker build -t reddit-clone ."
                       sh "docker tag reddit-clone gyenoch/reddit-clone:latest "
                       sh "docker push gyenoch/reddit-clone:latest "
                    }
                }
            }
        }

        stage("TRIVY"){
            steps{
                sh "trivy image gyenoch/reddit-clone:latest > trivyimage.txt" 
            }
        }

        stage ("Remove container") {
            steps{
                sh "docker stop reddit-clone | true"
                sh "docker rm reddit-clone | true"
             }
        }

        stage('Deploy to container'){
            steps{
                sh 'docker run -d --name reddit-clone -p 3000:3000 gyenoch/reddit-clone:latest'
            }
        }
    }

    post {
        always {
            script {
                def jobName = env.JOB_NAME 
                def buildNumber = env.BUILD_NUMBER 
                def pipelineStatus = currentBuild.result ?: 'UNKNOWN' 
                def bannerColor = pipelineStatus.toUpperCase() == 'SUCCESS' ? 'green' : 'red'

                def body = """
                    <html> <body>
                    <div style="border: 4px solid ${bannerColor}; padding: 10px;">
                    <h2>${jobName} - Build ${buildNumber}</h2>
                    <div style="background-color: ${bannerColor}; padding: 10px;">
                    <h3 style="color: white;">Pipeline Status: 
                    ${pipelineStatus.toUpperCase()}</h3>
                    </div>
                    <p>Check the <a href="${BUILD_URL}">console output</a>.</p>
                    </div>
                    </body> </html> """

                emailext ( 
                    subject: "${jobName} - Build ${buildNumber} - ${pipelineStatus.toUpperCase()}", 
                    body: body, to: 'www.gyenoch@gmail.com', 
                    from: 'jenkins@example.com', 
                    replyTo: 'www.gyenoch@gmail.com', 
                    mimeType: 'text/html', 
                    attachmentsPattern: 'trivy-image-report.html' 
                )
            }
        }
    }
}