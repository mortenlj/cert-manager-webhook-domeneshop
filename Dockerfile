FROM --platform=$BUILDPLATFORM golang:1.25-alpine@sha256:6104e2bbe9f6a07a009159692fe0df1a97b77f5b7409ad804b17d6916c635ae5 AS build_deps

RUN apk add --no-cache git

WORKDIR /workspace
ENV GO111MODULE=on

COPY go.mod .
COPY go.sum .

RUN go mod download

FROM build_deps AS build

COPY . .
ARG TARGETOS
ARG TARGETARCH
RUN GOOS=$TARGETOS GOARCH=$TARGETARCH CGO_ENABLED=0 go build -o webhook -ldflags '-w -extldflags "-static"' .

FROM alpine:3@sha256:4bcff63911fcb4448bd4fdacec207030997caf25e9bea4045fa6c8c44de311d1

RUN apk add --no-cache ca-certificates

COPY --from=build /workspace/webhook /usr/local/bin/webhook

ARG GIT_COMMIT
ARG GIT_BRANCH
ARG BUILD_DATE
ENV GIT_COMMIT=${GIT_COMMIT} GIT_BRANCH=${GIT_BRANCH:-""} BUILD_DATE=${BUILD_DATE:-"1970-01-01T00:00:00Z"}

ENTRYPOINT ["webhook"]
