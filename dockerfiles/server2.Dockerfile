dockerfile
FROM nginx:alpine
COPY html/server2 /usr/share/nginx/html
EXPOSE 80
