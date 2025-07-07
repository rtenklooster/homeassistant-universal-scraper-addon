FROM node:18-alpine

# Build time cache buster
ARG BUILD_DATE
RUN echo "Build date: $BUILD_DATE v1.0.7"

# Install system dependencies including git for cloning the project
RUN apk add --no-cache jq curl bash git python3 make g++

# Set working directory
WORKDIR /usr/src/app

# Copy run script (this will download and setup the real project)
COPY run.sh ./run.sh
RUN chmod +x ./run.sh

# Create necessary directories
RUN mkdir -p /data /config

CMD ["/usr/src/app/run.sh"]
