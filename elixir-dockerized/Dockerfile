FROM elixir:1.15-alpine

# Install build dependencies
RUN apk add --no-cache build-base npm git

# Prepare working directory
WORKDIR /app

# Copy mix files
COPY mix.exs mix.lock ./

# Install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Install dependencies
RUN mix deps.get

# Copy all application files
COPY . .

# Build the application
RUN mix compile

# Install and compile npm dependencies
RUN cd assets && npm install
RUN mix assets.deploy

# Ensure data directory exists
RUN mkdir -p /app/data

# Set environment to production
ENV MIX_ENV=prod
ENV ERL_AFLAGS="-proto_dist inet_tcp"

# Add health check for Docker
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget -q --spider http://localhost:${PORT:-4000}/health || exit 1

# Add entrypoint script
COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["mix", "phx.server"]