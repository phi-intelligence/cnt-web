FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

ARG API_BASE_URL=http://localhost:8002/api/v1
ARG MEDIA_BASE_URL=http://localhost:8002
ARG WEBSOCKET_URL=ws://localhost:8002
ARG LIVEKIT_WS_URL=ws://localhost:7880
ARG LIVEKIT_HTTP_URL=http://localhost:7881
ARG ENVIRONMENT=development
ARG GOOGLE_CLIENT_ID=

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

RUN flutter build web --release --no-source-maps \
  --dart-define=API_BASE_URL=${API_BASE_URL} \
  --dart-define=MEDIA_BASE_URL=${MEDIA_BASE_URL} \
  --dart-define=WEBSOCKET_URL=${WEBSOCKET_URL} \
  --dart-define=LIVEKIT_WS_URL=${LIVEKIT_WS_URL} \
  --dart-define=LIVEKIT_HTTP_URL=${LIVEKIT_HTTP_URL} \
  --dart-define=ENVIRONMENT=${ENVIRONMENT} \
  --dart-define=GOOGLE_CLIENT_ID=${GOOGLE_CLIENT_ID}

FROM nginx:alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80
