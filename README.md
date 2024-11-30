# iOS Podcast Application: Built with The Composable Architecture (TCA)

This project explores the development of an iOS application using **The Composable Architecture (TCA)**. Built with **SwiftUI**, the app enables users to search for podcasts, discover episodes, and stream playback through a seamless and user-friendly interface. The application emphasizes centralized state management, modularity, and scalability, demonstrating how TCA facilitates building robust, maintainable apps.

<p align="center">
   <img src="https://github.com/user-attachments/assets/0b948bdd-bdb3-4671-b760-4ea5660a4aad" alt="Screenshot 1" style="width: 20%; max-width: 150px; height: auto;" />
  <img src="https://github.com/user-attachments/assets/8b799021-7464-493c-a286-6d774916c1c7" alt="Screenshot 1" style="width: 20%; max-width: 150px; height: auto;" />
  <img src="https://github.com/user-attachments/assets/e093d38a-a5ca-4f91-a6be-ba7a58f42926" alt="Screenshot 2" style="width: 20%; max-width: 150px; height: auto;" />
  <img src="https://github.com/user-attachments/assets/f23b7c89-0140-4d90-a4c5-125c417a6230" alt="Screenshot 3" style="width: 20%; max-width: 150px; height: auto;" />
  <img src="https://github.com/user-attachments/assets/759c0bef-2135-4f54-824f-32e86fd3d952" alt="Screenshot 4" style="width: 20%; max-width: 150px; height: auto;" />
  <img src="https://github.com/user-attachments/assets/76f44363-2684-40c3-ad63-eeffe6eb62e4" alt="Screenshot 5" style="width: 20%; max-width: 150px; height: auto;" />
  <img src="https://github.com/user-attachments/assets/e0d506ac-cc1e-46a7-8a8c-38655f289a50" alt="Screenshot 6" style="width: 20%; max-width: 150px; height: auto;" />
  <img src="https://github.com/user-attachments/assets/e20f2b0d-d502-4ebc-8ec9-ee852d1c27fd" alt="Screenshot 7" style="width: 20%; max-width: 150px; height: auto;" />
</p>



## High-Level Overview

The application provides an engaging experience for discovering and exploring podcasts. It consists of the following screens:

- **Home Screen**: Displays trending podcasts and allows detailed browsing.
- **Explore Screen**: Enables discovery through categories or search.
- **Search View**: Offers a focused search interface with responsive results.
- **Podcast Details View**: Displays episode lists with smooth navigation to playback.
- **Category Details View**: Organizes podcasts by themes.
- **Player View**: Delivers a rich playback experience with intuitive controls.

This modular design ensures a cohesive user experience while adhering to modern architectural principles.

## App Architecture

The application is structured around three main tabs: **Home**, **Explore**, and **Settings**, with a centralized state managed by TCA. The **Podcast Details View** serves as a hub for exploring episodes, connecting users to the **Player View** for playback. The architecture promotes a clean and modular navigation flow.

## Screens Overview

### Home Screen

The Home Screen offers:
- A horizontal carousel for trending podcasts.
- A vertical list displaying detailed podcast information.
- Smooth transitions to the Podcast Details View.

### Explore Screen

The Explore Screen enables:
- Expandable navigation for browsing categories.
- A search bar for tailored results.
- Dynamic filters for podcasts and episodes.

### Search View

Features of the Search View:
- Focused search interface with real-time results.
- Tabs for filtering by podcasts or episodes.
- Intuitive layout with smooth animations.

### Podcast Details View

The Podcast Details View provides:
- A hero section with the podcast cover and title.
- Episode list with detailed information.
- Direct navigation to the Player View for playback.

### Category Details View

The Category Details View organizes content by:
- Vertical list with podcasts grouped by category.
- Seamless navigation to the Podcast Details View.

### Settings View

The Settings View allows:
- Clearing app cache with a confirmation dialog.
- Responsive feedback through progress indicators.

### Player View

The Player View delivers:
- A hero section displaying the episode details.
- Intuitive playback controls (play, pause, rewind, fast-forward).
- Real-time updates for playback progress.

## Key Features of TCA Implementation

- **Centralized State Management**: All app state is managed in a single, predictable store.
- **Modularity**: Each feature is encapsulated in its own domain, allowing for scalability and maintainability.
- **Testability**: TCA's design ensures that every part of the app can be easily tested.
- **Composable Design**: Screens and features are built as independent components, promoting reusability.

