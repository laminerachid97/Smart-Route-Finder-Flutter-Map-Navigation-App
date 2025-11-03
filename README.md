# 🚗 Flutter Navigation & Live Route Tracking App

A Flutter application that integrates **Google Maps**, **Geolocator**, and **Flutter Polyline Points** to provide **real-time route navigation and tracking** with animated car movement, direction updates, and city search suggestions.

---

## 🧭 Features

- 🌍 **Real-time GPS tracking** using the `geolocator` package  
- 🧩 **Google Maps integration** (`google_maps_flutter`)  
- 🛣️ **Polyline route generation** via Google Directions API  
- 🚗 **Animated marker movement** along the route (car simulation)  
- 🧭 **Device compass integration** for dynamic rotation (`flutter_compass`)  
- 🧠 **Dynamic camera bearing** that follows the route direction  
- 🔍 **City search** with real-time filtering  
- 💬 **Smooth UI interaction** with draggable bottom sheet and text inputs  
- 🧰 Built with clean Flutter architecture and separation of widgets/services  

---

## 📦 Dependencies

| Package | Purpose |
|----------|----------|
| `google_maps_flutter` | Displays Google Maps |
| `geolocator` | Gets the current device location and stream updates |
| `flutter_polyline_points` | Fetches route polylines from Google Directions API |
| `flutter_compass` | Reads compass heading for marker rotation |
| `flutter_dotenv` | Loads API keys securely from `.env` file |
| `material.dart` | Core Flutter UI framework |

---

## ⚙️ Setup Instructions

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/navigation-app.git
   cd navigation-app


1- Install dependencies

flutter pub get

2- Create a .env file in the root directory and add your Google Maps API key

GOOGLE_MAPS_KEY=YOUR_API_KEY_HERE

3- Run the app

flutter run