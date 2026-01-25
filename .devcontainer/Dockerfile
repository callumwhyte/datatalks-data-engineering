
# You can parameterize the universal variant via build args if you want
ARG VARIANT=2
FROM mcr.microsoft.com/devcontainers/universal:${VARIANT}

# --- Workaround: remove the broken Yarn APT source so apt-get update works ---
# If Yarn isn't required, just remove its list file and update APT.
RUN rm -f /etc/apt/sources.list.d/yarn.list \
    && apt-get update
