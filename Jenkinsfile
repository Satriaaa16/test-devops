node {
    def APP_NAME = 'devops-go-app'
    def GIT_COMMIT_SHORT = ''
    def REGISTRY_CRED_ID = 'docker-hub-credentials'

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
            // Menggunakan container Go ephemeral agar tidak perlu install Go di host Jenkins
            sh 'docker run --rm -v $(pwd):/app -w /app golang:1.23-alpine go test -v ./...'
        }

        stage('Build Binary') {
            echo "Building app version: ${GIT_COMMIT_SHORT}"
            sh "docker run --rm -v \$(pwd):/app -w /app golang:1.23-alpine sh -c \"CGO_ENABLED=0 GOOS=linux go build -ldflags=\\\"-X 'main.version=${GIT_COMMIT_SHORT}'\\\" -o ./bin/app main.go\""
            sh "docker build --build-arg VERSION=${GIT_COMMIT_SHORT} -t ${APP_NAME}:${GIT_COMMIT_SHORT} ."
        }

        stage('Push Image (Simulated)') {
            // Memanggil secret dari Credentials Manager Jenkins yang baru kamu buat
            withCredentials([usernamePassword(credentialsId: REGISTRY_CRED_ID, usernameVariable: 'REG_USER', passwordVariable: 'REG_PASS')]) {
                echo "Simulating image push using credentials for user: ${REG_USER}"
            }
        }

        stage('Deploy (Hotfix / Swap Binary)') {
            echo 'Deploying via binary swap strategy...'
            
            // Simpan backup binary lama jika ada
            sh '''
                if [ -f ./bin/app.bak ]; then rm ./bin/app.bak; fi
                if [ -f ./bin/app_running ]; then cp ./bin/app_running ./bin/app.bak; fi
            '''

            // Pemicu restart / jalankan container
            sh """
                if [ \$(docker ps -q -f name=${APP_NAME}) ]; then
                    docker restart ${APP_NAME}
                else
                    docker run -d --name ${APP_NAME} --restart always -p 8080:8080 -v \$(pwd)/bin/app:/app/app ${APP_NAME}:${GIT_COMMIT_SHORT}
                fi
                
                cp ./bin/app ./bin/app_running
            """

            // Health check
            sh '''
                sleep 2
                curl -f http://localhost:8080 || exit 1
            '''
        }
    } catch (exc) {
        echo "Pipeline Gagal! Menjalankan rollback otomatis..."
        sh '''
            if [ -f ./bin/app.bak ]; then
                echo "Mengembalikan binary ke versi sebelumnya..."
                cp ./bin/app.bak ./bin/app
                docker restart devops-go-app || true
                echo "Rollback sukses dilakukan."
            fi
        '''
        throw exc
    } finally {
        deleteDir()
    }
}
