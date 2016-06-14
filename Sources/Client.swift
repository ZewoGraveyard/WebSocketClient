// Client.swift
//
// The MIT License (MIT)
//
// Copyright (c) 2015 Zewo
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

@_exported import WebSocket

import HTTP
import HTTPClient
import HTTPSClient
import Base64

public enum ClientError: ErrorProtocol {
    case unsupportedScheme
    case hostRequired
    case responseNotWebsocket
}

public struct Client {
    private let client: Responder
    private let didConnect: (WebSocket) throws -> Void

    public init(uri: URI, didConnect: (WebSocket) throws -> Void) throws {
        guard let scheme = uri.scheme where scheme == "ws" || scheme == "wss" else {
            throw ClientError.unsupportedScheme
        }

        guard let host = uri.host else {
            throw ClientError.hostRequired
        }

        let secure = scheme == "wss"
        let port = uri.port ?? (secure ? 443 : 80)
        let uri = URI(host: host, port: port, scheme: secure ? "https" : "http")

        if secure {
            self.client = try HTTPSClient.Client(uri: uri)
        } else {
            self.client = try HTTPClient.Client(uri: uri)
        }

        self.didConnect = didConnect
    }

    public func connect(_ path: String) throws {
        let key = try Base64.encode(Random.getBytes(16))

        let headers: Headers = [
            "Connection": "Upgrade",
            "Upgrade": "websocket",
            "Sec-WebSocket-Version": "13",
            "Sec-WebSocket-Key": key,
        ]

        let request = try Request(method: .get, uri: path, headers: headers) { response, stream in
            guard response.status == .switchingProtocols && response.isWebSocket else {
                throw ClientError.responseNotWebsocket
            }

            guard let accept = response.webSocketAccept where accept == WebSocket.accept(key) else {
                throw ClientError.responseNotWebsocket
            }

            let webSocket = WebSocket(stream: stream, mode: .client)
            try self.didConnect(webSocket)
            try webSocket.start()
        }

        _ = try client.respond(to: request)
    }

    public func connectInBackground(_ path: String, failure: (ErrorProtocol) -> Void = Client.logError) {
        co {
            do {
                try self.connect(path)
            } catch {
                failure(error)
            }
        }
    }

    static func logError(error: ErrorProtocol) {
        print(error)
    }
}

public extension Response {
    public var webSocketVersion: String? {
        return headers["Sec-Websocket-Version"]
    }

    public var webSocketKey: String? {
        return headers["Sec-Websocket-Key"]
    }

    public var webSocketAccept: String? {
        return headers["Sec-WebSocket-Accept"]
    }

    public var isWebSocket: Bool {
        return connection?.lowercased() == "upgrade" && upgrade?.lowercased() == "websocket"
    }
}
