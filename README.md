# CSE Status App

A macOS menu bar application that displays the real-time status of the Colombo Stock Exchange (CSE).

## Features

- **Real-time Market Status**: Shows if the Colombo Stock Exchange is open or closed
- **Visual Status Indicator**: Color-coded circle shows market status at a glance:
  - 🟢 Green: Market Open / Regular Trading
  - 🔴 Red: Market Closed
  - 🟠 Orange: Connection Error
  - 🟡 Yellow: Checking Status
- **Dual Time Display**: Shows both local time and Colombo (Sri Lanka) time
- **Automatic Updates**: Refreshes every 5 minutes to ensure current information
- **Manual Refresh**: Force an update with the Refresh Now option (⌘R)
- **Launch at Login**: Option to start automatically when you log in to your Mac
- **Minimal Resource Usage**: Designed to be lightweight and efficient

## Requirements

- macOS 13.0 or later
- Xcode 15.0 or later for building
- Internet connection to fetch CSE status
                                            
## Building the App

To build and run the app:
1. Clone this repository
2. Open the project in Xcode
3. Build the project (Product > Build)
4. Run the app (Product > Run)

## Usage

Once built and running, the app appears as a small icon in your menu bar showing the current CSE market status:
- Click the icon to view the details menu
- Use "Refresh Now" to manually update the status
- Enable "Launch at Login" to have the app start automatically
- The status is automatically refreshed every 5 minutes

## Running Without an Apple Developer ID

This project can be built and run without requiring an Apple Developer ID by using Xcode's "Run" functionality or by exporting using the "Copy App" option in the Archive process. When launching the exported app for the first time, you'll need to right-click the app and select "Open".

*CSE Status App is not officially affiliated with the Colombo Stock Exchange.*
