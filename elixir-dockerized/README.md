# Dockerized Elixir Phoenix Chat Application

This directory contains all necessary files to deploy the Elixir Phoenix Chat application across multiple servers using Docker. The setup is designed to create a distributed Erlang cluster spanning across multiple VPS instances.

## Overview

The deployment architecture consists of:

- **Master Node**: Runs MongoDB, Phoenix application, and Caddy for SSL termination and load balancing
- **Worker Nodes**: Run Phoenix application instances that connect to the master node's MongoDB

All nodes form a distributed Erlang cluster, allowing seamless communication between application instances.

## Prerequisites

- Docker and Docker Compose installed on all servers
- Domain name pointing to the master server (for SSL via Caddy)
- Network connectivity between all servers

## Server Setup

### IP Configuration

In this setup, we use three servers with the following roles:

- Master Node: `MASTER_IP` (e.g., 194.163.160.2)
- Worker Node 1: `WORKER_IP` (e.g., 185.187.169.230)
- Worker Node 2: `WORKER2_IP` (e.g., 194.5.152.243)

## Deployment Instructions

### 1. Master Node Setup

1. Copy this entire directory to the master server
2. Create `.env.master` file from the example:
   ```bash
   cp .env.master.example .env.master
   ```
3. Edit `.env.master` file with your specific configuration:
   - Replace `MASTER_IP` with the actual IP of your master server
   - Replace `WORKER_IP` and `WORKER2_IP` with your worker server IPs
   - Generate and set strong values for `JWT_SECRET`, `SECRET_KEY_BASE`, `ENCRYPTION_KEY`, and `ERLANG_COOKIE`
   - Set `YOUR_DOMAIN` to your actual domain name

4. Edit `Caddyfile` to replace the domain and worker IPs with your own

5. Start the services:
   ```bash
   docker-compose -f master-compose.yml up -d
   ```

### 2. Worker Node Setup

1. Copy this entire directory to each worker server
2. Create `.env.worker` file from the example:
   ```bash
   cp .env.worker.example .env.worker
   ```
3. Edit `.env.worker` file with your specific configuration:
   - Replace `MASTER_IP` with the actual IP of your master server
   - Replace `WORKER_IP` with **this** worker server's IP
   - Use the **same** values for `JWT_SECRET`, `SECRET_KEY_BASE`, `ENCRYPTION_KEY`, and `ERLANG_COOKIE` as the master node
   - Set `YOUR_DOMAIN` to your actual domain name

4. Start the services:
   ```bash
   docker-compose -f worker-compose.yml up -d
   ```

## Environment Files

### Master Node (.env.master)

```
# MongoDB
MONGODB_URL=mongodb://root:rootpassword@mongodb:27017/elixir_chat?authSource=admin

# Application
NODE_TYPE=master
NODE_NAME=elixir_chat@MASTER_IP
POOL_SIZE=2
JWT_SECRET=YOUR_JWT_SECRET_HERE
SECRET_KEY_BASE=YOUR_SECRET_KEY_BASE_HERE
ENCRYPTION_KEY=YOUR_ENCRYPTION_KEY_HERE
ERLANG_COOKIE=YOUR_ERLANG_COOKIE
PHX_HOST=YOUR_DOMAIN
PORT=4000
OTHER_NODES=elixir_chat@WORKER_IP,elixir_chat@WORKER2_IP
```

### Worker Node (.env.worker)

```
# MongoDB - point to master node
MONGODB_URL=mongodb://root:rootpassword@MASTER_IP:27017/elixir_chat?authSource=admin

# Application
NODE_TYPE=worker
NODE_NAME=elixir_chat@WORKER_IP
POOL_SIZE=2
JWT_SECRET=YOUR_JWT_SECRET_HERE
SECRET_KEY_BASE=YOUR_SECRET_KEY_BASE_HERE
ENCRYPTION_KEY=YOUR_ENCRYPTION_KEY_HERE
ERLANG_COOKIE=YOUR_ERLANG_COOKIE
PHX_HOST=YOUR_DOMAIN
PORT=4000
MASTER_NODE=elixir_chat@MASTER_IP
```

## Security Notes

- The `.env.*` files contain sensitive information and should never be committed to version control
- Use strong, unique values for all secrets
- The MongoDB password in the example files should be changed in production
- Consider adding firewall rules to restrict access to ports between servers

## Monitoring and Management

You can check the status of your services with:

```bash
# Check container status
docker ps

# View logs
docker-compose -f master-compose.yml logs -f  # On master node
docker-compose -f worker-compose.yml logs -f  # On worker nodes

# Check if Erlang clustering is working (on any node)
docker exec -it elixir-dockerized_phoenix_1 bash -c "elixir --name debug@localhost --cookie \$ERLANG_COOKIE -e 'IO.puts(\"Connected nodes: \#{inspect(Node.list())}\")"
```

## Backup Strategy

To back up the MongoDB database:

```bash
# On the master node
docker exec -it elixir-dockerized_mongodb_1 mongodump --username root --password rootpassword --authenticationDatabase admin --db elixir_chat --out /dump

# Copy backups from container to host
docker cp elixir-dockerized_mongodb_1:/dump ./backups/$(date +%Y-%m-%d)
```

## Troubleshooting

If nodes are not connecting:
1. Ensure all servers have network connectivity to each other
2. Verify that `.env` files have the correct IPs and the same ERLANG_COOKIE
3. Check firewall rules to allow EPMD (port 4369) and Erlang distribution ports
