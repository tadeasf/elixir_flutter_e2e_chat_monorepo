# Single-Node Elixir Phoenix Chat Deployment

This guide explains how to deploy the Elixir Phoenix Chat application on a single server using Docker.

## Prerequisites

- Docker and Docker Compose installed on your server
- Basic familiarity with Docker commands
- Git to clone the repository

## Deployment Steps

### 1. Clone the Repository

```bash
git clone your_repo_url
cd elixir_test
```

### 2. Update Environment Variables

In the `docker-compose.yml` file, modify the environment variables under the `phoenix` service:

```yaml
environment:
  - MONGODB_URL=mongodb://root:rootpassword@mongodb:27017/elixir_chat?authSource=admin
  - POOL_SIZE=2
  - JWT_SECRET=your_jwt_secret_here             # Change this to a secure value
  - SECRET_KEY_BASE=your_secret_key_base_here   # Change this to a secure value
  - ENCRYPTION_KEY=your_encryption_key_here     # Change this to a secure value
  - PORT=4000
  - PHX_HOST=localhost                          # Change to your domain if needed
  - MIX_ENV=prod
```

### 3. Build and Start the Services

```bash
docker-compose up -d
```

This will:
- Start a MongoDB instance
- Build the Elixir Phoenix Chat application
- Start the application with the specified environment

### 4. Verify the Deployment

Check if the containers are running:

```bash
docker-compose ps
```

Access the application at:
- http://your_server_ip:4000

View application logs:

```bash
docker-compose logs -f phoenix
```

### 5. Adding SSL with Caddy (Optional)

If you want to add SSL, you can use Caddy:

1. Add Caddy to docker-compose.yml:

```yaml
caddy:
  image: caddy:2
  ports:
    - "80:80"
    - "443:443"
  volumes:
    - ./Caddyfile:/etc/caddy/Caddyfile
    - caddy_data:/data
    - caddy_config:/config
  networks:
    - phoenix_network
```

2. Create a `Caddyfile` in the project root:

```
your-domain.com {
    reverse_proxy phoenix:4000
}
```

3. Add the volumes to the `volumes` section:

```yaml
volumes:
  caddy_data:
  caddy_config:
```

4. Restart the services:

```bash
docker-compose up -d
```

## Troubleshooting

- **MongoDB Connection Issues**: Check if MongoDB is running and if the connection URL is correct
- **Port Conflicts**: If port 4000 is already in use, modify the port mapping in the docker-compose.yml file
- **Application Errors**: Check the application logs with `docker-compose logs -f phoenix`

## Backing Up MongoDB

To back up the MongoDB database:

```bash
# Create a backup
docker exec -it elixir_test_mongodb_1 mongodump --username root --password rootpassword --authenticationDatabase admin --db elixir_chat --out /dump

# Copy the backup to the host
docker cp elixir_test_mongodb_1:/dump ./backups/$(date +%Y-%m-%d)
``` 