# Stage 1: Build Flutter Web App
FROM debian:latest AS build-env

# Cài đặt các công cụ cần thiết
RUN apt-get update
RUN apt-get install -y curl git wget unzip libgconf-2-4 gdb libstdc++6 libglu1-mesa fonts-droid-fallback lib32stdc++6 python3
RUN apt-get clean

# Clone Flutter SDK (Chọn stable channel)
RUN git clone https://github.com/flutter/flutter.git /usr/local/flutter
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Di chuyển code vào container
RUN mkdir /app/
COPY . /app/
WORKDIR /app/

# Build Web (Release mode)
RUN flutter config --enable-web
RUN flutter pub get
RUN flutter build web --release

# Stage 2: Serve bằng Nginx (Nhẹ, chuẩn production)
FROM nginx:1.21.1-alpine
COPY --from=build-env /app/build/web /usr/share/nginx/html

# Copy file cấu hình nginx (xem bên dưới)
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]