# ElixirTest - Messaging API

A simple messaging API built with Elixir, featuring user management, authentication, and message handling.

## Features

- User Management (create user with email, change password)
- Email-based Authentication (login with JWT tokens)
- Message Handling (send and receive messages)
- MongoDB for data persistence
- High concurrency support via Erlang VM
- Configurable worker pool size
- Comprehensive logging

## Prerequisites

- Elixir 1.18 or later
- Docker and Docker Compose
- MongoDB (via Docker)

## Development Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd elixir_test
```

2. Start MongoDB using Docker Compose:
```bash
docker-compose up -d
```

3. Install dependencies:
```bash
mix deps.get
```

4. Start the application in development mode:
```bash
mix run --no-halt
```

The server will be available at `http://localhost:4000`

## Production Setup

For production, we leverage the Erlang VM's concurrency capabilities:

1. Build a release:
```bash
MIX_ENV=prod mix release
```

2. Start the release with desired configuration:
```bash
POOL_SIZE=10 PORT=4000 _build/prod/rel/elixir_test/bin/elixir_test start
```

Environment variables for production:
- `PORT`: HTTP port (default: 4000)
- `POOL_SIZE`: Number of workers in the connection pool (default: 10)
- `MONGODB_URL`: MongoDB connection URL

## API Endpoints

### Create User
```http
POST /users
Content-Type: application/json

Request Body:
{
  "email": "user@example.com"
}

Response: 
{
  "user_id": "uuid",
  "email": "user@example.com",
  "generated_password": "password",
  "message": "Please store your password securely"
}

Status Codes:
- 201: User created successfully
- 400: Email already exists or is missing
- 500: Server error
```

### Login
```http
POST /users/login
Content-Type: application/json

Request Body:
{
  "email": "user@example.com",
  "password": "password"
}

Response: 
{
  "token": "jwt_token"
}

Status Codes:
- 200: Login successful
- 401: Invalid credentials
```

### Change Password
```http
PUT /users/change-password
Content-Type: application/json

Request Body:
{
  "email": "user@example.com",
  "current_password": "current",
  "new_password": "new"
}

Status Codes:
- 200: Password updated successfully
- 401: Invalid credentials
```

### Send Message
```http
POST /messages
Content-Type: application/json
Authorization: Bearer <token>

Request Body:
{
  "content": "message"
}

Status Codes:
- 201: Message sent
- 401: Invalid or missing token
- 500: Server error
```

### Get Messages
```http
GET /messages
Authorization: Bearer <token>

Response:
[
  {
    "content": "message",
    "created_at": "timestamp"
  }
]

Status Codes:
- 200: Messages retrieved successfully
- 401: Invalid or missing token
```

## Running Tests

Run the test suite:
```bash
mix test
```

Run tests with coverage:
```bash
mix test --cover
```

## Architecture

The application uses:
- Plug.Cowboy for HTTP server
- MongoDB for data storage
- Joken for JWT authentication
- BCrypt for password hashing

Key features:
- Email-based user authentication
- Unique email constraint for users
- JWT-based session management
- Configurable connection pool size
- Comprehensive logging for all operations
- Error handling with detailed feedback

The system is designed to be horizontally scalable, leveraging Erlang VM's concurrency model. Each connection is handled in a separate process, allowing for excellent performance under high load.

## Logging

The application includes comprehensive logging for:
- Application startup and configuration
- User operations (creation, login, password changes)
- Message operations
- Authentication attempts
- Errors and warnings

Logs are output to the console and include:
- Timestamp
- Log level (info, warn, error)
- Operation details
- User identifiers (when applicable)
- Error details (when applicable)

