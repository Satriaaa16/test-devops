# DevOps Technical Assessment: Go Microservice CI/CD

This repository contains a lightweight Go HTTP server, a multi-stage Docker setup, and a Jenkins Scripted Pipeline designed to demonstrate isolated testing, dynamic binary compilation, and a zero-rebuild hotfix deployment strategy.

---

## Technical Overview

### 1. Application & Build (Part I)
* **Application:** Go HTTP server exposing standard endpoints and injecting build metadata at compile time.
* **Injectable Version:** The application version is dynamically bound using `-ldflags`:
  ```bash
  go build -ldflags="-X 'main.version=${GIT_COMMIT_SHORT}'" -o ./bin/app main.go
Multi-Stage Docker Architecture:

Builder Stage: Uses golang:1.23-alpine to compile a pure static binary (CGO_ENABLED=0).

Runtime Stage: Uses a minimal alpine:latest base to reduce attack surface while retaining basic debugging tools (sh, curl).

Final Image Optimization: By separating build-time dependencies from the runtime image, the resulting image size remains under ~15 MB.

Deployment & Hotfix Strategy (Part II)
Volume-Mounted Binary Swap
To achieve rapid deployment and hotfix capabilities without triggering a full docker build cycle or image layer churn, the container mounts the compiled binary directly from the host filesystem:

Bash
docker run -d \
  --name devops-go-app \
  --restart always \
  -p 8080:8080 \
  -v $(pwd)/bin/app:/app/app \
  devops-go-app:latest
Why This Approach Fits Production Hotfixes
Downtime Minimization: Traditional image rebuilds and registry pushes take minutes. Swapping the binary and issuing a docker restart reduces service interruption to less than 2 seconds (process restart time).

Resource Efficiency: Avoids saturating network bandwidth and CPU on CI/CD agents caused by unnecessary container image builds during emergency hotfixes.

Trade-off Consideration: While immutable infrastructure (full image replacement) is preferred for standard release cycles, binary swapping is an acceptable and effective trade-off for zero-rebuild hotfix scenarios.

CI/CD Pipeline Architecture (Part III)
The deployment is orchestrated via a self-contained Jenkins Scripted Pipeline (Jenkinsfile) designed to run seamlessly even in constrained agent environments without pre-installed Go toolchains.

Key Pipeline Stages
Checkout: Pulls latest source code from the Git repository.

Setup Go Environment: Dynamically downloads and extracts Go 1.23 within the workspace directory, ensuring pipeline portability across different Jenkins agents.

Test: Executes isolated unit tests (go test -v .). Pipeline immediately halts if tests fail.

Build Binary: Compiles static Linux binary with the short Git commit hash embedded.

Push (Simulated): Demonstrates secure credential binding using Jenkins Secret Manager (withCredentials) without hardcoding registry tokens or SSH keys in the source code.

Deploy & Health Check: Swaps the active binary payload, triggers container restart, and performs endpoint verification.

Automatic Rollback Mechanism
The pipeline handles deployment failures gracefully using a standard try-catch workflow:

Before replacing the active binary, the existing working binary is backed up (./bin/app.bak).

If any step in the compilation, test, or deployment stage fails, the catch block automatically restores ./bin/app.bak back to ./bin/app and restarts the container service.

This guarantees that the service rolls back to the last known healthy state before marking the job as FAILED.

Verification & Execution
To test the entire workflow locally:

Bash
# 1. Run unit tests
go test -v .

# 2. Compile static binary with custom version tag
CGO_ENABLED=0 GOOS=linux go build -ldflags="-X 'main.version=1.0.0'" -o ./bin/app main.go

# 3. Build & Run container
docker build --build-arg VERSION=1.0.0 -t devops-go-app:latest .
docker run -d --name devops-go-app --restart always -p 8080:8080 -v $(pwd)/bin/app:/app/app devops-go-app:latest

# 4. Verify endpoint response
curl http://localhost:8080
