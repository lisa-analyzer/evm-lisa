# Usa un'immagine base con JDK 11
FROM openjdk:11-jdk-slim

# Specifica la versione di Gradle da installare
ARG GRADLE_VERSION=6.6

# Installa Gradle
RUN apt-get update && apt-get install -y wget unzip git && \
    wget https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip && \
    mkdir /opt/gradle && \
    unzip -d /opt/gradle gradle-${GRADLE_VERSION}-bin.zip && \
    rm gradle-${GRADLE_VERSION}-bin.zip && \
    ln -s /opt/gradle/gradle-${GRADLE_VERSION}/bin/gradle /usr/bin/gradle && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Imposta la directory di lavoro
WORKDIR /app

# Clone the EVMLiSA repository
RUN git clone https://github.com/lisa-analyzer/evm-lisa.git .

# Compila il progetto con Gradle
RUN gradle build

# Estrai il file ZIP del progetto per la distribuzione
RUN gradle distZip && \
    unzip -o build/distributions/evm-lisa.zip -d /app/execution

# Imposta la directory di lavoro per il runtime
# WORKDIR /app/execution/evm-lisa

# Imposta il comando di default per avviare EVMLiSA
# CMD ["bin/evm-lisa", "-h"]

# Set the entry point of the container
ENTRYPOINT ["/app/execution/evm-lisa/bin/evm-lisa"]
