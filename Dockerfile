FROM node:21.6.2 AS frontend

COPY . /app
WORKDIR /app
RUN corepack install; \
  corepack pnpm install; \
  corepack pnpm run build

FROM alpine AS backend

COPY . /app
WORKDIR /app
RUN mkdir -p /app/crpaste; \
  apk add crystal shards openssl-dev; \
  shards build --release

FROM alpine
RUN apk add libevent openssl gc libgcc pcre2
COPY --from=frontend /app/public /app/public
COPY --from=backend /app/bin /app/bin
ENV PORT=8000
USER nobody
WORKDIR "/app"
CMD [ "/app/bin/crpaste" ]