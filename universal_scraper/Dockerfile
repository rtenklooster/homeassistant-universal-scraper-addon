FROM node:18-alpine

# Build time cache buster
ARG BUILD_DATE
RUN echo "Build date: $BUILD_DATE v1.0.6"

# Install system dependencies  
RUN apk add --no-cache jq curl bash

# Set working directory
WORKDIR /usr/src/app

# Copy application files
COPY package*.json ./

# Install npm dependencies
RUN npm install

# Copy run script
COPY run.sh ./run.sh
RUN chmod +x ./run.sh

# Create data directory
RUN mkdir -p /data

CMD ["/usr/src/app/run.sh"]
