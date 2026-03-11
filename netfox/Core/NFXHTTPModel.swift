//
//  NFXHTTPModel.swift
//  netfox
//
//  Copyright © 2016 netfox. All rights reserved.
//

import Foundation
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

@objc public class NFXHTTPModel: NSObject {
    @objc public var requestURL: String?
    @objc public var requestHost: String?
    @objc public var requestURLComponents: URLComponents?
    @objc public var requestURLQueryItems: [URLQueryItem]?
    @objc public var requestMethod: String?
    @objc public var requestCachePolicy: String?
    @objc public var requestDate: Date?
    @objc public var requestTime: String?
    @objc public var requestTimeSecond: String?
    @objc public var requestTimeout: String?
    @objc public var requestHeaders: [String: String]?
    public var requestBodyLength: Int?
    @objc public var requestType: String?
    @objc public var requestCurl: String?

    public var responseStatus: Int?
    @objc public var responseType: String?
    @objc public var responseDate: Date?
    @objc public var responseTime: String?
    @objc public var responseTimeSecond: String?
    @objc public var responseHeaders: [String: String]?
    public var responseBodyLength: Int?
    
    public var timeInterval: Float?
    
    @objc public lazy var randomHash = UUID().uuidString
    public var shortType = HTTPModelShortType.OTHER
    @objc public var shortTypeString: String { return shortType.rawValue }
    
    @objc public var noResponse = true
    
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    private static let timeSecondFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()

    func saveRequest(_ request: URLRequest) {
        let now = Date()
        requestDate = now
        requestHost = request.url?.host()
        requestTime = NFXHTTPModel.timeFormatter.string(from: now)
        requestTimeSecond = NFXHTTPModel.timeSecondFormatter.string(from: now)
        requestURL = request.getNFXURL()
        requestURLComponents = request.getNFXURLComponents()
        requestURLQueryItems = request.getNFXURLComponents()?.queryItems
        requestMethod = request.getNFXMethod()
        requestCachePolicy = request.getNFXCachePolicy()
        requestTimeout = request.getNFXTimeout()
        requestHeaders = request.getNFXHeaders()
        requestType = requestHeaders?["Content-Type"]
        requestCurl = request.getCurl()
    }
    
    func saveRequestBody(_ request: URLRequest) {
        saveRequestBodyData(request.getNFXBody())
    }
    
    func saveErrorResponse() {
        responseDate = Date()
    }
    
    func saveResponse(_ response: URLResponse, data: Data) {
        noResponse = false
        let now = Date()
        responseDate = now
        responseTime = NFXHTTPModel.timeFormatter.string(from: now)
        responseTimeSecond = NFXHTTPModel.timeSecondFormatter.string(from: now)
        responseStatus = response.getNFXStatus()
        responseHeaders = response.getNFXHeaders()
        
        let headers = response.getNFXHeaders()
        
        if let contentType = headers["Content-Type"] {
            let responseType = contentType.components(separatedBy: ";")[0]
            shortType = HTTPModelShortType(contentType: responseType)
            self.responseType = responseType
        }
        
        if let requestDate = requestDate {
            timeInterval = Float(now.timeIntervalSince(requestDate))
        }
        
        saveResponseBodyData(data)

        // Optimization: Do not read from disk to log. 
        // We already have the response data in memory.
        // For the request body, it was already saved to disk if present, 
        // but we avoid formatting it until actually needed for UI/Log.
        // Actually, let's keep it simple: if we want a performance king, we shouldn't 
        // do expensive string concatenation and disk append on EVERY request if we can help it.
        // But for parity with existing features, we'll just make it faster.
        
        let logEntry = formattedLogEntry(responseData: data)
        logEntry.appendToFileURL(NFXPath.sessionLogURL)
    }
    
    private func formattedLogEntry(responseData: Data?) -> String {
        var log = String()
        
        if let requestURL = self.requestURL {
            log.append("-------START SESSION -  \(requestURL) -------\n")
        }

        if let requestMethod = self.requestMethod {
            log.append("[Request Method] \(requestMethod)\n")
        }
        
        if let requestDate = self.requestDate {
            log.append("[Request Date] \(requestDate)\n")
        }
        
        if let requestTime = self.requestTime {
            log.append("[Request Time] \(requestTime)\n")
        }
        
        if let requestType = self.requestType {
            log.append("[Request Type] \(requestType)\n")
        }
            
        if let requestTimeout = self.requestTimeout {
            log.append("[Request Timeout] \(requestTimeout)\n")
        }
            
        if let requestHeaders = self.requestHeaders {
            log.append("[Request Headers]\n\(requestHeaders)\n")
        }

        if let cURL = self.requestCurl {
            log.append("[Request cURL]\n \(cURL)\n")
        }

        // We avoid calling getRequestBody() as it reads from disk
        log.append("[Request Body] ... available in NFX ...\n")
        
        if let responseStatus = self.responseStatus {
            log.append("[Response Status] \(responseStatus)\n")
        }
        
        if let responseType = self.responseType {
            log.append("[Response Type] \(responseType)\n")
        }
        
        if let responseDate = self.responseDate {
            log.append("[Response Date] \(responseDate)\n")
        }
        
        if let responseHeaders = self.responseHeaders {
            log.append("[Response Headers]\n\(responseHeaders)\n\n")
        }

        if let data = responseData {
            log.append("[Response Body]\n \(prettyOutput(data, contentType: responseType))\n")
        }

        if let requestURL = self.requestURL {
            log.append("-------END SESSION - \(requestURL) -------\n\n")
        }
        
        return log
    }

    func saveRequestBodyData(_ data: Data) {
        guard !data.isEmpty else { return }
        self.requestBodyLength = data.count
        saveData(data, to: getRequestBodyFileURL())
    }
    
    func saveResponseBodyData(_ data: Data) {
        guard !data.isEmpty else { return }
        self.responseBodyLength = data.count
        saveData(data, to: getResponseBodyFileURL())
    }
    
    fileprivate func prettyOutput(_ rawData: Data, contentType: String? = nil) -> String {
        guard let contentType = contentType,
              let output = prettyPrint(rawData, type: .init(contentType: contentType))
        else {
            return String(data: rawData, encoding: String.Encoding.utf8) ?? ""
        }
        
        return output
    }

    @objc public func getRequestBody() -> String {
        guard let data = readRawData(from: getRequestBodyFileURL()) else {
            return ""
        }
        return prettyOutput(data, contentType: requestType)
    }
    
    @objc public func getResponseBody() -> String {
        guard let data = readRawData(from: getResponseBodyFileURL()) else {
            return ""
        }
        
        return prettyOutput(data, contentType: responseType)
    }
    
    @objc public func getRequestBodyFileURL() -> URL {
        return NFXPath.pathURLToFile(getRequestBodyFilename())
    }
    
    @objc public func getRequestBodyFilename() -> String {
        return "request_body_\(requestTime!)_\(randomHash)"
    }
    
    @objc public func getResponseBodyFileURL() -> URL {
        return NFXPath.pathURLToFile(getResponseBodyFilename())
    }
    
    @objc public func getResponseBodyFilename() -> String {
        return "response_body_\(requestTime!)_\(randomHash)"
    }
    
    @objc public func saveData(_ data: Data, to fileURL: URL) {
        do {
            try data.write(to: fileURL, options: .atomic)
        } catch let error {
            print("[NFX]: Failed to save data to [\(fileURL)] - \(error.localizedDescription)")
        }
    }
    
    @objc public func readRawData(from fileURL: URL) -> Data? {
        do {
            return try Data(contentsOf: fileURL)
        } catch let error {
            print("[NFX]: Failed to load data from [\(fileURL)] - \(error.localizedDescription)")
            return nil
        }
    }
    
    @objc public func getTimeFromDate(_ date: Date) -> String? {
        return NFXHTTPModel.timeFormatter.string(from: date)
    }

    @objc public func getTimeSecondFromDate(_ date: Date) -> String? {
        return NFXHTTPModel.timeSecondFormatter.string(from: date)
    }

    public func prettyPrint(_ rawData: Data, type: HTTPModelShortType) -> String? {
        switch type {
        case .JSON:
            do {
                let rawJsonData = try JSONSerialization.jsonObject(with: rawData, options: [])
                let prettyPrintedString = try JSONSerialization.data(withJSONObject: rawJsonData, options: [.prettyPrinted])
                return String(data: prettyPrintedString, encoding: .utf8)
            } catch {
                return nil
            }
        default:
            return nil
        }
    }
    
    @objc public func isSuccessful() -> Bool {
        if let responseStatus = self.responseStatus, responseStatus < 400 {
            return true
        } else {
            return false
        }
    }
    
    
    @objc public func formattedRequestLogEntry() -> String {
        var log = String()
        
        if let requestURL = self.requestURL {
            log.append("-------START REQUEST -  \(requestURL) -------\n")
        }

        if let requestMethod = self.requestMethod {
            log.append("[Request Method] \(requestMethod)\n")
        }
        
        if let requestDate = self.requestDate {
            log.append("[Request Date] \(requestDate)\n")
        }
        
        if let requestTime = self.requestTime {
            log.append("[Request Time] \(requestTime)\n")
        }
        
        if let requestType = self.requestType {
            log.append("[Request Type] \(requestType)\n")
        }
            
        if let requestTimeout = self.requestTimeout {
            log.append("[Request Timeout] \(requestTimeout)\n")
        }
            
        if let requestHeaders = self.requestHeaders {
            log.append("[Request Headers]\n\(requestHeaders)\n")
        }

        if let cURL = self.requestCurl {
            log.append("[Request cURL]\n \(cURL)\n")
        }

        log.append("[Request Body]\n \(getRequestBody())\n")
        
        if let requestURL = self.requestURL {
            log.append("-------END REQUEST - \(requestURL) -------\n\n")
        }
        
        return log;
    }
    
    @objc public func formattedResponseLogEntry() -> String {
        var log = String()
        
        if let requestURL = self.requestURL {
            log.append("-------START RESPONSE -  \(requestURL) -------\n")
        }
        
        if let responseStatus = self.responseStatus {
            log.append("[Response Status] \(responseStatus)\n")
        }
        
        if let responseType = self.responseType {
            log.append("[Response Type] \(responseType)\n")
        }
        
        if let responseDate = self.responseDate {
            log.append("[Response Date] \(responseDate)\n")
        }
        
        if let responseTime = self.responseTime {
            log.append("[Response Time] \(responseTime)\n")
        }
        
        if let responseHeaders = self.responseHeaders {
            log.append("[Response Headers]\n\(responseHeaders)\n\n")
        }
        
        log.append("[Response Body]\n \(getResponseBody())\n")

        if let requestURL = self.requestURL {
            log.append("-------END RESPONSE - \(requestURL) -------\n\n")
        }
        
        return log;
    }
}

extension NFXHTTPModel {
    static var mock: NFXHTTPModel {
        let mock = NFXHTTPModel()
        mock.requestURL = "https://api.example.com/v1/users?search=ali"
        mock.requestURLComponents = URLComponents(string: mock.requestURL!)
        mock.requestURLQueryItems = mock.requestURLComponents?.queryItems
        mock.requestMethod = "GET"
        mock.requestCachePolicy = "UseProtocolCachePolicy"
        mock.requestDate = Date().addingTimeInterval(-2)
        mock.requestTime = mock.getTimeFromDate(mock.requestDate!)
        mock.requestTimeout = "60.0"
        mock.requestHeaders = [
            "Content-Type": "application/json",
            "Authorization": "Bearer MOCK_TOKEN"
        ]
        mock.requestBodyLength = 27
        mock.requestType = "application/json"
        mock.requestCurl = "curl -X GET \"\(mock.requestURL!)\" -H \"Authorization: Bearer MOCK_TOKEN\""

        mock.responseStatus = 200
        mock.responseType = "application/json"
        mock.responseDate = Date()
        mock.responseTime = mock.getTimeFromDate(mock.responseDate!)
        mock.responseHeaders = [
            "Content-Type": "application/json",
            "Cache-Control": "no-cache"
        ]
        mock.responseBodyLength = 47
        mock.timeInterval = 1.23
        mock.noResponse = false
        mock.shortType = .JSON

        // Optional: Write temporary request/response body for getRequestBody/getResponseBody
        let requestBody = "{\"name\": \"Ali\", \"email\": \"ali@example.com\"}".data(using: .utf8)!
        let responseBody = "{\"id\": 1, \"name\": \"Ali\", \"status\": \"active\"}".data(using: .utf8)!

        mock.saveData(requestBody, to: mock.getRequestBodyFileURL())
        mock.saveData(responseBody, to: mock.getResponseBodyFileURL())

        return mock
    }
}
