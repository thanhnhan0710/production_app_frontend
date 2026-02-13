# ==============================================================================
# GIAI ĐOẠN 1: BUILD ENVIRONMENT & GENERATE SSL
# ==============================================================================
FROM debian:bullseye-slim AS build

# 1. Cài đặt công cụ
RUN apt-get update && apt-get install -y \
    curl git unzip ca-certificates openssl \
    && rm -rf /var/lib/apt/lists/*

# 2. Tạo chứng chỉ SSL tự ký
WORKDIR /certs
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout server.key -out server.crt \
    -subj "/C=VN/ST=HCM/L=HCM/O=Oppermann/OU=IT/CN=localhost"

# 3. Tải và cài đặt Flutter (Sử dụng nhánh 'stable' cho an toàn)
# [ĐÃ SỬA] Đổi từ '3.38.1' sang 'stable' để tránh lỗi phiên bản ảo
RUN git clone -b stable --depth 1 https://github.com/flutter/flutter.git /usr/local/flutter

ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Cấu hình quyền Git (Fix lỗi dubios ownership trong Docker)
RUN git config --global --add safe.directory /usr/local/flutter
RUN flutter config --enable-web

# Kiểm tra version để chắc chắn cài thành công
RUN flutter doctor -v

# 4. Build App
WORKDIR /app
COPY pubspec.* ./
RUN flutter pub get

COPY . .

# [ĐÃ SỬA] Xóa bỏ "--web-renderer auto" gây lỗi. 
# Mặc định Flutter Web đã tự động chọn renderer tối ưu (HTML/CanvasKit).
RUN flutter build web --release

# ==============================================================================
# GIAI ĐOẠN 2: NGINX SERVER
# ==============================================================================
FROM nginx:alpine

# Xóa config mặc định
RUN rm /etc/nginx/conf.d/default.conf

# Copy config Nginx mới
COPY nginx.conf /etc/nginx/nginx.conf

# Copy chứng chỉ SSL
RUN mkdir -p /etc/nginx/certs
COPY --from=build /certs/server.crt /etc/nginx/certs/
COPY --from=build /certs/server.key /etc/nginx/certs/

# Copy Web App đã build
COPY --from=build /app/build/web /usr/share/nginx/html

# Mở cổng
EXPOSE 80
EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]