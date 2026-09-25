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
            // Menjalankan semua unit test sesuai standar Go dan requirement soal
            sh 'go test -v ./...'
        }

        stage('Build Binary & Image') {
            echo "Building app version: ${GIT_COMMIT_SHORT}"
            // Build binary lokal dengan inject versi commit hash
            sh "CGO_ENABLED=0 GOOS=linux go build -ldflags=\"-X 'main.version=${GIT_COMMIT_SHORT}'\" -o ./bin/app main.go"
            // Build Docker image
            sh "docker build --build-arg VERSION=${GIT_COMMIT_SHORT} -t ${APP_NAME}:${GIT_COMMIT_SHORT} ."
        }

        stage('Push Image (Simulated)') {
            echo "Simulating push image ${APP_NAME}:${GIT_COMMIT_SHORT} using credentials ID: ${REGISTRY_CRED_ID}"
        }

        stage('Deploy (Hotfix / Swap Binary)') {
            echo 'Deploying via binary swap strategy...'
            
            // Simpan backup binary lama jika ada
            sh '''
                if [ -f ./bin/app.bak ]; then rm ./bin/app.bak; fi
                if [ -f ./bin/app_running ]; then cp ./bin/app_running ./bin/app.bak; fi
            '''

            // Jalankan / restart container dengan volume mount
            sh """
                if [ \$(docker ps -q -f name=${APP_NAME}) ]; then
                    docker restart ${APP_NAME}
                else
                    docker run -d --name ${APP_NAME} --restart always -p 8080:8080 -v \$(pwd)/bin/app:/app/app ${APP_NAME}:${GIT_COMMIT_SHORT}
                fi
                
                cp ./bin/app ./bin/app_running
            """

            // Health check untuk verifikasi
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
            else
                echo "Tidak ditemukan backup binary untuk melakukan rollback."
            fi
        '''
        throw exc
    } finally {
        cleanWs()
    }
}
