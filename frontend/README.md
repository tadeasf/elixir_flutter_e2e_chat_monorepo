# Elixir Test Frontend

A Flutter application that serves as a frontend for the Elixir Test API.

## Features

- User authentication (login/signup)
- View and send messages
- Change password
- Messages grouped by sender
- Responsive UI with Material Design

## Setup Instructions

### Prerequisites

- Flutter SDK (version 3.0.0 or higher)
- Dart SDK
- An active Elixir backend running on http://localhost:4000

### Installation

1. Clone the repository
2. Navigate to the project directory
3. Install dependencies:

```bash
flutter pub get
```

4. Run the application:

```bash
flutter run
```

## Backend Configuration

The app is configured to connect to the Elixir backend at `http://localhost:4000`. If your backend is running on a different URL, you'll need to update the `baseUrl` in:

- `lib/services/auth_service.dart`
- `lib/services/message_service.dart`

## Project Structure

- `lib/models/` - Data models
- `lib/screens/` - UI screens
- `lib/services/` - API and business logic
- `lib/widgets/` - Reusable UI components

## Authentication Flow

1. User signs up with email
2. Backend generates a password
3. User saves password and logs in
4. JWT token is stored in secure storage

## Architecture

This application follows a Provider-based architecture for state management:

- `AuthService` manages user authentication state
- `MessageService` handles message operations and state
- UI components react to state changes through `Consumer` widgets
