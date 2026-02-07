```dockerfile
FROM nginx:alpine
COPY html/server1 /usr/share/nginx/html
EXPOSE 80
