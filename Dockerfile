FROM node:18-alpine

# Install dependencies and build tools
RUN apk add --no-cache git jq python3 make g++ azure-cli

# Set working directory
WORKDIR /usr/src/app

# Copy application files
COPY package*.json ./
COPY tsconfig.json ./
COPY src/ ./src/
COPY front-end/ ./front-end/

# Copy run script
COPY ha-addon/run.sh ./run.sh
RUN chmod +x ./run.sh

# Create data directory
RUN mkdir -p /data

CMD ["/usr/src/app/run.sh"]
