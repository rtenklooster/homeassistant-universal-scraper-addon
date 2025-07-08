FROM node:18-alpine

# Build time cache buster
ARG BUILD_DATE
RUN echo "Build date: $BUILD_DATE v1.0.8"

# Install system dependencies including git for cloning the project
RUN apk add --no-cache jq curl bash git python3 make g++ chromium

# Set Node.js memory options for better performance in Docker
ENV NODE_OPTIONS="--max-old-space-size=2048"
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser

# Set working directory
WORKDIR /usr/src/app

# Copy run script (this will download and setup the real project)
COPY run.sh ./run.sh
RUN chmod +x ./run.sh

# Create necessary directories
RUN mkdir -p /data /config

# Expose the port for Home Assistant ingress
EXPOSE 3000

CMD ["/usr/src/app/run.sh"]
