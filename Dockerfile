# syntax=docker/dockerfile:1.6
FROM --platform=$BUILDPLATFORM rust:1-bookworm AS builder

ARG TARGETARCH

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        clang \
        llvm \
        pkg-config \
        libssl-dev \
        ca-certificates \
        curl \
    && rm -rf /var/lib/apt/lists/*

ENV MOLD_VERSION=2.4.0
RUN case "${TARGETARCH}" in \
      amd64) MOLD_ARCH="x86_64" ;; \
      arm64) MOLD_ARCH="aarch64" ;; \
      *) echo "Unsupported architecture: ${TARGETARCH}" && exit 1 ;; \
    esac; \
    set -eux; \
    curl --fail --location "https://github.com/rui314/mold/releases/download/v${MOLD_VERSION}/mold-${MOLD_VERSION}-${MOLD_ARCH}-linux.tar.gz" --output /tmp/mold.tar.gz; \
    tar --directory "/usr/local" -xzf "/tmp/mold.tar.gz" --strip-components 1; \
    rm /tmp/mold.tar.gz; \
    mold --version

ENV RUSTFLAGS="--cfg tokio_unstable -C link-arg=-fuse-ld=mold"

WORKDIR /usr/src/app
COPY . .

RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/usr/local/cargo/git \
    --mount=type=cache,target=target \
    cargo build --release -p corrosion && \
    cp target/release/corrosion /usr/local/bin/corrosion

FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        sqlite3 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local/bin/corrosion /usr/local/bin/corrosion

RUN useradd -ms /bin/bash corrosion
USER corrosion

ENTRYPOINT ["corrosion"]
CMD ["agent"]
