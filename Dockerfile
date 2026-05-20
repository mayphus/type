FROM docker.io/debian:bookworm-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    ca-certificates \
    fonts-noto-cjk \
    git \
    libgdk-pixbuf-2.0-0 \
    libgdk-pixbuf-xlib-2.0-0 \
    libglib2.0-0 \
    libgtk2.0-0 \
    libjpeg62-turbo \
    libpangocairo-1.0-0 \
    libpng16-16 \
    librsvg2-bin \
    racket \
    zip \
 && rm -rf /var/lib/apt/lists/*

RUN raco pkg install --auto --batch --scope installation https://github.com/mayphus/style.git

WORKDIR /app
COPY . .

RUN useradd -r -s /sbin/nologin rime \
 && chown -R rime /app

USER rime

EXPOSE 8080

CMD ["racket", "main.rkt", "serve"]
