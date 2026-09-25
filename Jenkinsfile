node {
    def APP_NAME = 'devops-go-app'
    def GIT_COMMIT_SHORT = ''
    def REGISTRY_CRED_ID = 'docker-hub-credentials'

    // Memanggil Go tool yang baru saja kamu daftarkan di Manage Jenkins -> Tools
    def goHome = tool name: 'go-1.23', type: 'golang'
    env.PATH = "${goHome}/bin:${env.PATH}"

    try {
        stage('Checkout') {
            checkout scm
            GIT_COMMIT_SHORT = sh(
                script: "git rev-parse --short HEAD",
                returnStdout: true
            ).trim()
        }

        stage('Test') {
            echo 'Running unit tests...'
            sh 'go test -v ./...'
        }

        stage('Build Binary') {
            echo "Building app version: ${GIT_COMMIT_SHORT}"
            sh "CGO_ENABLED=0 GOOS=linux go build -ldflags=\"-X 'main.version=${GIT_COMMIT_SHORT}'\" -o ./bin/app main.go"
        }

        stage('Push Image (Simulated)') {
            withCredentials([usernamePassword(credentialsId: REGISTRY_CRED_ID, usernameVariable: 'REG_USER', passwordVariable: 'REG_PASS')]) {
                echo "Simulating push image ${APP_NAME}:${GIT_COMMIT_SHORT} using credentials for user: ${REG_USER}"
            }
        }

        stage('Deploy (Hotfix / Swap Binary)') {
            echo 'Deploying via binary swap strategy...'
            
            sh '''
                if [ -f ./bin/app.bak ]; then rm ./bin/app.bak; fi
                if [ -f ./bin/app_running ]; then cp ./bin/app_running ./bin/app.bak; fi
                cp ./bin/app ./bin/app_running
            '''

            echo "Binary version ${GIT_COMMIT_SHORT} successfully built and ready for hotfix deployment."
            sh 'test -f ./bin/app && echo "Deployment verification success!"'
        }
    } catch (exc) {
        echo "Pipeline Gagal! Menjalankan rollback otomatis..."
        sh '''
            if [ -f ./bin/app.bak ]; then
                echo "Mengembalikan binary ke versi sebelumnya..."
                cp ./bin/app.bak ./bin/app
                echo "Rollback sukses dilakukan."
            fi
        '''
        throw exc
    } finally {
        deleteDir()
    }
}
