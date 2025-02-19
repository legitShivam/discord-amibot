# Stage 1: Build the bot and the server to later shift to a minimal image
FROM rust:1.71 AS builder
RUN apt-get update && apt-get install -y protobuf-compiler

WORKDIR /app

# Copy the important files to the container
COPY bot bot
COPY amizone amizone
COPY Cargo.toml Cargo.toml
COPY Cargo.lock Cargo.lock

# Clone the protobuf dependencies
RUN <<EOF
 [ "$(ls -A ./amizone/proto/googleapis)" ] && echo "Found protobuf deps" || git clone https://www.github.com/googleapis/googleapis.git ./amizone/proto/googleapis
EOF

# Build the Bot
RUN cargo build --release

# Stage 2: Create minimal ubuntu image, for running the bot
FROM ubuntu:latest

# Expose the port for Discord communication
EXPOSE 443

WORKDIR /app

# Copy the .env file from the build context into the Docker image
COPY .env /app/.env

# Copy the built Bot from the builder stage
COPY --from=builder /app/target/release/bot /app/bot
RUN chmod 755 /app/bot

# Create entrypoint script
COPY <<EOF /app/entrypoint.sh
/app/bot
EOF
RUN chmod +x /app/entrypoint.sh


CMD ["/bin/sh", "/app/entrypoint.sh"]
