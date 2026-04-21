# syntax=docker/dockerfile:1.6
FROM rust:1-bookworm AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        clang \
        pkg-config \
        libssl-dev \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

ENV RUSTFLAGS="--cfg tokio_unstable"

WORKDIR /usr/src/app
COPY . .

RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/usr/local/cargo/git \
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
