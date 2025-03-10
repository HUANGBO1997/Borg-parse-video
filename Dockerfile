FROM golang:alpine AS builder

LABEL stage=gobuilder

ENV CGO_ENABLED 0
# 通过环境变量设置 Go 模块代理（推荐显式声明）
ENV GOPROXY https://goproxy.cn,direct

RUN apk update --no-cache && apk add --no-cache tzdata

WORKDIR /build

ADD go.mod .
ADD go.sum .
# 显式设置 Go 代理（双重保障，避免多阶段构建的潜在问题）
RUN go env -w GOPROXY=https://goproxy.cn,direct && go mod download
COPY . .
RUN go build -ldflags="-s -w" -o /app/main ./main.go

FROM scratch

COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=builder /usr/share/zoneinfo/Asia/Shanghai /usr/share/zoneinfo/Asia/Shanghai
ENV TZ Asia/Shanghai

WORKDIR /app
COPY --from=builder /app/main /app/main
COPY templates /app/templates

EXPOSE 8080

CMD ["./main"]
