# syntax=docker/dockerfile:1

# build
FROM alpine:3.19 AS builder

ARG VERSION=1.0
ENV APP_VERSION=$VERSION

RUN apk add --no-cache git openssh-client
RUN mkdir -p -m 0700 ~/.ssh && ssh-keyscan github.com >> ~/.ssh/known_hosts

WORKDIR /app

RUN --mount=type=ssh git clone git@github.com:Kupi403/pawcho6.git .

COPY index.sh .
RUN chmod +x index.sh  # nadajemy prawa już tutaj

# scratch
FROM scratch AS stage1
# tylko kopiujemy plik, nie robimy RUN
COPY --from=builder /app/index.sh /index.sh

# nginx
FROM nginx:alpine

ARG VERSION
ENV APP_VERSION=$VERSION

LABEL org.opencontainers.image.source="https://github.com/Kupi403/pawcho6"
LABEL org.opencontainers.image.description="Lab6 - SSH mount i ghcr.io"
LABEL org.opencontainers.image.authors="Michał Kupidura"

RUN apk add --no-cache curl bash

WORKDIR /usr/share/nginx/html

# kopiujemy skrypt z scratch
COPY --from=stage1 /index.sh ./index.sh

EXPOSE 80

# uruchamiamy skrypt dynamicznie przy starcie kontenera
CMD ["sh", "-c", "./index.sh && nginx -g 'daemon off;'"]

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s \
  CMD curl -f http://localhost || exit 1