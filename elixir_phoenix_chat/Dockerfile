FROM elixir:1.15-alpine

# Install build dependencies
RUN apk add --no-cache build-base npm git

# Prepare working directory
WORKDIR /app

# Copy mix files first to install dependencies
COPY mix.exs mix.lock ./

# Install hex + rebar
RUN mix local.hex --force && \
  mix local.rebar --force

# Force production environment for all mix commands
ENV MIX_ENV=prod

# First copy the entire app to modify dependencies if needed
COPY . .

# Explicit handling for heroicons - remove it from mix.lock
RUN sed -i '/heroicons/d' mix.lock && \
  mix deps.get && \
  mix deps.unlock --all && \
  mix deps.get

# Build the application
RUN mix compile

# Install and compile npm dependencies
RUN mix assets.deploy
RUN mix phx.swagger.generate
# Ensure data directory exists
RUN mkdir -p /app/data

# Expose the port
ENV PORT=4000
EXPOSE ${PORT}

# Run the Phoenix server
CMD ["mix", "phx.server"]
