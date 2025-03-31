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

# Expose the port
ENV PORT=4000
EXPOSE ${PORT}

# Set environment to production
ENV MIX_ENV=prod

# Run migrations and start the Phoenix server
CMD ["sh", "-c", "mix phx.server"] 