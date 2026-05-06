FROM ubuntu:24.04 AS runtime
RUN apt-get update && apt-get install -y --no-install-recommends \
    libstdc++6 \
    && rm -rf /var/lib/apt/lists/*

COPY build/calculator-app /usr/local/bin/calculator-app
ENTRYPOINT ["calculator-app"]
