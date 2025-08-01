//
//  APIService.swift
//  CicareSdkCall
//
//  Created by cicare.team on 29/07/25.
//

import Foundation

enum APIError: Error {
    case badURL
    case requestFailed(Error)
    case invalidResponse
    case decodingFailed(Error)
}

final class APIService: NSObject {
    
    static let shared = APIService()
    
    var baseURL: String!
    var apiKey: String!
    private let session: URLSession!

    private init(session: URLSession = .shared) {
        self.session = session
    }

    func request<T: Decodable>(
        path: String,
        method: String = "GET",
        query: [String: String]? = nil,
        body: Data? = nil,
        headers: [String: String]? = nil,
        completion: @escaping (Result<T, APIError>) -> Void
    ) {
        guard let base = baseURL,
                let baseUrl = URL(string: base) else {
            completion(.failure(APIError.decodingFailed(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : "Base URL hasn't been set"]))))
            return
          }
        var components = URLComponents(url: baseUrl.appendingPathComponent(path), resolvingAgainstBaseURL: false)
        if let query = query {
            components?.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let url = components?.url else {
            completion(.failure(.badURL)); return
        }
        
        // Siapkan URLRequest
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        if let authToken = apiKey {
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }
        headers?.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        
        // Jalankan
        session.dataTask(with: request) { data, response, error in
            guard error == nil else {
              completion(.failure(.requestFailed(error!)))
              return
            }
            guard let http = response as? HTTPURLResponse,
                  200...299 ~= http.statusCode,
                  let data = data
            else {
                print(String(data: data ?? Data(), encoding: .utf8) ?? "No data")
                completion(.failure(.invalidResponse)); return
            }
            do {
                let decoded = try JSONDecoder().decode(T.self, from: data)
                completion(.success(decoded))
            } catch {
                completion(.failure(.decodingFailed(error)))
            }
        }.resume()
    }
}
