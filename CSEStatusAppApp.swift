//
//  CSEStatusAppApp.swift
//  CSEStatusApp
//
//  Created by Methsara Perera on 5/7/25.
//

import SwiftUI
import AppKit
import ServiceManagement

@main
struct CSEStatusApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var timer: Timer?
    private var timeItems: [NSMenuItem] = []
    
    // Color palette
    private let colorOpen = NSColor(calibratedRed: 52/255, green: 199/255, blue: 89/255, alpha: 1.0)
    private let colorClosed = NSColor(calibratedRed: 255/255, green: 69/255, blue: 58/255, alpha: 1.0)
    private let colorError = NSColor(calibratedRed: 255/255, green: 149/255, blue: 0/255, alpha: 1.0)
    private let colorChecking = NSColor(calibratedRed: 255/255, green: 204/255, blue: 0/255, alpha: 1.0)
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon
        NSApp.setActivationPolicy(.accessory)
        
        // Create status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            // Initialize with checking status
            let image = circleImage(color: colorChecking, size: NSSize(width: 10, height: 10))
            button.image = image
            button.title = " CSE"
        }
        
        // Set up menu
        setupMenu()
        
        // Start polling for market status
        startTimer()
    }
    
    func setupMenu() {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "Market Status: Checking...", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Refresh Now", action: #selector(refreshStatus), keyEquivalent: "r"))
        menu.addItem(NSMenuItem.separator())
        
        // Add placeholder items for times
        let localTimeItem = NSMenuItem(title: "Local: --:--:--", action: nil, keyEquivalent: "")
        let colomboTimeItem = NSMenuItem(title: "Colombo: --:--:--", action: nil, keyEquivalent: "")
        
        menu.addItem(localTimeItem)
        menu.addItem(colomboTimeItem)
        
        // Keep track of these items for updating
        timeItems = [localTimeItem, colomboTimeItem]
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Launch at Login", action: #selector(toggleLoginItem), keyEquivalent: "l"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    func startTimer() {
        timer = Timer.scheduledTimer(timeInterval: 300, target: self, selector: #selector(refreshStatus), userInfo: nil, repeats: true)
        refreshStatus()
    }
    
    @objc func refreshStatus() {
        guard let url = URL(string: "https://www.cse.lk/api/marketStatus") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let postData = ["param1": "value1"]
        request.httpBody = try? JSONSerialization.data(withJSONObject: postData)
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            var marketStatus = "Unknown"
            var statusColor: NSColor
            
            if let error = error {
                print("Network error: \(error.localizedDescription)")
                
                if (error as NSError).domain == NSURLErrorDomain {
                    switch (error as NSError).code {
                    case NSURLErrorNotConnectedToInternet:
                        marketStatus = "No internet connection"
                    case NSURLErrorCannotFindHost, NSURLErrorCannotConnectToHost:
                        marketStatus = "Cannot connect to CSE"
                    case NSURLErrorTimedOut:
                        marketStatus = "Connection timed out"
                    default:
                        marketStatus = "Network error: \((error as NSError).code)"
                    }
                } else {
                    marketStatus = "Error connecting to server"
                }
                statusColor = self.colorError
            } else if let data = data, let httpResponse = response as? HTTPURLResponse {
                // Check for HTTP errors
                if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                    do {
                        // Parse the JSON response
                        if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                           let status = json["status"] as? String {
                            marketStatus = status
                            
                            if marketStatus.lowercased().contains("open") {
                                statusColor = self.colorOpen
                            } else if marketStatus.lowercased().contains("closed") {
                                statusColor = self.colorClosed
                            } else {
                                statusColor = self.colorChecking
                            }
                        } else {
                            marketStatus = "Invalid response format"
                            statusColor = self.colorError
                        }
                    } catch {
                        marketStatus = "Data parsing error"
                        statusColor = self.colorError
                    }
                } else {
                    marketStatus = "Server error: \(httpResponse.statusCode)"
                    statusColor = self.colorError
                }
            } else {
                statusColor = self.colorChecking
            }
            
            // Update UI on main thread
            DispatchQueue.main.async {
                if let button = self.statusItem?.button {
                    // Create colored status indicator
                    let image = self.circleImage(color: statusColor, size: NSSize(width: 10, height: 10))
                    button.image = image
                    button.title = " CSE"
                }
                
                // Update the menu
                if let menu = self.statusItem?.menu {
                    // Update market status item
                    if menu.items.count > 0 {
                        menu.items[0].title = "Market Status: \(marketStatus)"
                    }
                    
                    // Update time items
                    let formatter = DateFormatter()
                    formatter.timeZone = TimeZone.current
                    formatter.dateFormat = "HH:mm:ss"
                    let localTime = formatter.string(from: Date())
                    
                    formatter.timeZone = TimeZone(identifier: "Asia/Colombo")
                    let colomboTime = formatter.string(from: Date())
                    
                    if self.timeItems.count >= 2 {
                        self.timeItems[0].title = "Local: \(localTime)"
                        self.timeItems[1].title = "Colombo: \(colomboTime)"
                    }
                }
            }
        }
        
        task.resume()
    }
    
    func circleImage(color: NSColor, size: NSSize) -> NSImage {
        let image = NSImage(size: size)
        image.lockFocus()
        
        // Fill with color
        color.set()
        
        // Create a smoother circle with antialiasing
        let path = NSBezierPath(ovalIn: NSRect(origin: .zero, size: size))
        path.fill()
        
        image.unlockFocus()
        return image
    }
    
    @objc func toggleLoginItem() {
        addLoginItem()
        
        // Update menu item state with a checkmark
        if let menu = statusItem?.menu, let item = menu.item(withTitle: "Launch at Login") {
            item.state = .on
        }
    }
    
    func addLoginItem() {
        // For macOS 13+, no need of URL for the modern API
        if #available(macOS 13.0, *) {
            do {
                try SMAppService.mainApp.register()
                print("Successfully registered app as login item")
            } catch {
                print("Failed to register app as login item: \(error)")
            }
        } else {
            // For older macOS versions
            let appURL = Bundle.main.bundleURL
            print("Legacy login item support needed with URL: \(appURL.path)")
        }
    }
}
