Community Board
A cross-platform community application built with Flutter and Dart, designed to provide users with a platform to interact, share posts, and engage with other members.
The project follows Monorepo Architecture and Clean Architecture principles to maintain a modular, scalable, and maintainable codebase.

Features
- Authentication: User authentication and account management using Supabase.
- Posts: Create, view, and interact with community posts.
- Comments: Engage in discussions through comments.
- Likes: Interact with posts using likes.
- User Profiles: View and manage user profile information.
- Search: Search for community content and users.
- Realtime Updates: Receive updates using Supabase Realtime.
- Image Handling: Select and display images within the application.
Architecture
The project is structured as a Monorepo and follows Clean Architecture principles to separate concerns and improve code organization.

Project Structure
community-board/
│
├── app/
│   ├── lib/
│   └── ...
│
├── auth/
│   ├── lib/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   └── ...
│
├── post/
│   ├── lib/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   └── ...
│
├── search/
│   ├── lib/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   └── ...
│
├── profile/
│   ├── lib/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   └── ...
│
├── core/
│   ├── lib/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   └── ...
│
└── README.md

Technologies & Tools
Flutter & Dart: Cross-platform application development
Bloc: State management
Supa base: Authentication, database, and Realtime services
GoRouter: Application navigation
GetIt & Injectable: Dependency injection
Global Event Bus: Communication between application components
Equatable: Value equality
FPdart: Functional programming
JSON Serializable: JSON serialization and deserialization
Image Picker: Selecting images
Cached Network Image: Efficient image loading and caching

Getting Started
Prerequisites
- Flutter SDK
- Dart SDK
- Android Studio or Visual Studio Code
- A Supabase project
  
Project Goals
- Apply Monorepo Architecture in Flutter development.
- Implement Clean Architecture principles.
- Build a modular and maintainable application.
- Manage application state using BLoC.
- Integrate Supabase services and realtime functionality.
- Improve communication and coordination between application components.
