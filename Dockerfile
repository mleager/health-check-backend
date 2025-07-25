FROM golang:1.24-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN go build -o backend

FROM alpine:latest
WORKDIR /app
COPY --from=builder /app/backend .
EXPOSE 4000
CMD ["./backend"]

