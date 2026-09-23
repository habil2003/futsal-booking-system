# Use a lightweight Nginx image to serve static web files
FROM nginx:alpine

# Copy the compiled Flutter web files into Nginx's public folder
COPY build/web /usr/share/nginx/html

# Expose port 80 for web traffic
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
