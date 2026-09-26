# Stage 1: Builder
FROM golang:1.23-alpine AS builder

ARG VERSION=dev
WORKDIR /app

COPY go.mod ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-X 'main.version=${VERSION}'" -o /app/app main.go

# Stage 2: Minimal Runtime
FROM alpine:latest

WORKDIR /app
RUN apk add --no-cache curl ca-certificates

COPY --from=builder /app/app /app/app

EXPOSE 8080
CMD ["/app/app"]
