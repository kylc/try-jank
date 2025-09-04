######################################################
# Base image shared between build and runtime stages #
######################################################
FROM ubuntu:24.04 AS base

RUN apt update && \
    apt install -y curl gnupg && \
    rm -rf /var/cache/apt/archives /var/lib/apt/lists/*

# Enable UTF-8
ENV LANG=C.UTF-8

# Add jank source
RUN curl -s "https://jank-lang.github.io/ppa/KEY.gpg" | gpg --dearmor | tee /etc/apt/trusted.gpg.d/jank.gpg >/dev/null && \
    curl -s -o /etc/apt/sources.list.d/jank.list "https://jank-lang.github.io/ppa/jank.list"

# Install dependencies and jank
RUN apt update && \
    apt install -y netcat-traditional libboost-system-dev default-jre-headless jank && \
    rm -rf /var/cache/apt/archives /var/lib/apt/lists/*

# Install clojure
RUN curl -L -O https://github.com/clojure/brew-install/releases/latest/download/linux-install.sh && \
    chmod +x linux-install.sh && \
    ./linux-install.sh

#########################################
# Build image with C++ compilation step #
#########################################
FROM base AS build

# Install build dependencies
RUN apt update && \
    apt install -y cmake clang && \
    rm -rf /var/cache/apt/archives /var/lib/apt/lists/*

# Build jank-nrepl-server
COPY jank-nrepl-server /app
RUN cd /app && cmake --workflow --preset release

############################################
# Runtime image with only jank and clojure #
############################################
FROM base

# Install jank-nrepl-server
COPY --from=build /app /app
RUN /app/build/jank-wrapper repl # precompile headers

# Prefetch rebel-readline deps
RUN clojure -Sdeps "{:deps {com.bhauman/rebel-readline-nrepl {:mvn/version \"0.1.6\"}}}"

COPY launch.sh /launch.sh
ENTRYPOINT ["/launch.sh"]
