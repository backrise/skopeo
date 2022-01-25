FROM golang:1.17.6-bullseye AS builder

RUN sed -i "s/deb.debian.org/ftp.cn.debian.org/g" /etc/apt/sources.list
RUN apt-get update && apt-get install -y -qq libgpgme11-dev
COPY . /app
WORKDIR /app
RUN GOPROXY="https://goproxy.cn" CGO_CFLAGS="" \
    CGO_LDFLAGS="-L/usr/lib/x86_64-linux-gnu -lgpgme -lassuan -lgpg-error" GO111MODULE=on \
    go build -mod=vendor "-buildmode=pie" \
    -ldflags '-X main.gitCommit='$(git rev-parse HEAD)' -s -w -linkmode "external" -extldflags "-static"' \
    -gcflags "" -tags "btrfs_noversion exclude_graphdriver_btrfs libdm_no_deferred_remove exclude_graphdriver_devicemapper containers_image_openpgp" \
    -o bin/skopeo ./cmd/skopeo

FROM alpine
COPY --from=builder /app/bin/skopeo /usr/local/bin/skopeo
ENTRYPOINT [ "skopeo" ]

