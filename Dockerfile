FROM rust:bookworm AS rust-builder
RUN apt-get update && apt-get install -y libasound2-dev
RUN mkdir /build
ADD . /build/
WORKDIR /build
RUN --mount=type=cache,target=/build/.cargo/registry \
    --mount=type=cache,target=/build/target/release/incremental\
    --mount=type=cache,target=/build/target/release/build\
    cargo build --release --no-default-features --features "vad_webrtc" --bin rustpbx

FROM debian:bookworm
LABEL maintainer="shenjindi@fourz.cn"
RUN --mount=type=cache,target=/var/apt apt-get update && apt-get install -y ca-certificates tzdata
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8

WORKDIR /app
COPY --from=rust-builder /build/target/release/rustpbx /app/rustpbx
COPY config.docker.toml /app/config.toml

# Create necessary directories
RUN mkdir -p /tmp/recorders /tmp/mediacache /tmp/cdr

EXPOSE 8080/TCP
EXPOSE 15060/UDP
EXPOSE 13050/UDP
EXPOSE 20000-30000/UDP

ENTRYPOINT ["/app/rustpbx"]
CMD ["--conf", "/app/config.toml"]