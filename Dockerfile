# Use a base image with JDK 11
FROM openjdk:11-jdk-slim

# Specify the version of Gradle to install
ARG GRADLE_VERSION=6.6

# Install Gradle
RUN apt-get update && apt-get install -y wget unzip git && \
    wget https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip && \
    mkdir /opt/gradle && \
    unzip -d /opt/gradle gradle-${GRADLE_VERSION}-bin.zip && \
    rm gradle-${GRADLE_VERSION}-bin.zip && \
    ln -s /opt/gradle/gradle-${GRADLE_VERSION}/bin/gradle /usr/bin/gradle && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Clone the EVMLiSA repository (latest stable version)
# RUN git clone https://github.com/lisa-analyzer/evm-lisa.git .

# Copy the entire EVMLiSA project into the container (latest version)
COPY . .

# Build the project with Gradle
RUN gradle build

# Extract the project ZIP file for distribution
RUN gradle distZip && \
    unzip -o build/distributions/evm-lisa.zip -d /app/execution

# Create results directory
RUN mkdir -p /app/execution/results

# Set the entry point of the container
ENTRYPOINT ["/app/execution/evm-lisa/bin/evm-lisa"]
