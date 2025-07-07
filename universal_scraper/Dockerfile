FROM node:18-alpine

# Install system dependencies and build tools
RUN apk add --no-cache git jq python3 make g++ curl bash

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
