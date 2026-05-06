FROM docker.io/debian:bookworm-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    ca-certificates \
    fonts-noto-cjk \
    racket \
    zip \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . .

RUN useradd -r -s /sbin/nologin rime \
 && chown -R rime /app

USER rime

EXPOSE 8080

CMD ["racket", "web.rkt"]
