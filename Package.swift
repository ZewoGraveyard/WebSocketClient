import PackageDescription

let package = Package(
    name: "WebSocketClient",
    dependencies: [
        .Package(url: "https://github.com/Zewo/WebSocket.git", majorVersion: 0, minor: 8),
        .Package(url: "https://github.com/Zewo/HTTP.git", majorVersion: 0, minor: 8),
        .Package(url: "https://github.com/Zewo/Base64.git", majorVersion: 0, minor: 8),
        .Package(url: "https://github.com/VeniceX/HTTPClient.git", majorVersion: 0, minor: 8),
        .Package(url: "https://github.com/VeniceX/HTTPSClient.git", majorVersion: 0, minor: 8),
    ]
)
