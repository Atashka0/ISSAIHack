import Foundation

struct KazLLMAPI {
    private let baseURL = "https://apikazllm.nu.edu.kz/"
    private let apiKey: String = "AHAFgQ0l.kubPtZaQSFJy6rmw6dr2B8WJx3DE57eR"
    
    init() {}
    
    private func createRequest(
        endpoint: String,
        method: String,
        body: Data? = nil,
        contentType: String = "application/json"
    ) -> URLRequest {
        guard let url = URL(string: baseURL + endpoint) else {
            fatalError("Invalid URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.setValue("Api-Key \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = body
        return request
    }
    
    func listAssistants(completion: @escaping (Result<[SimpleAssistant], Error>) -> Void) {
        let request = createRequest(endpoint: "assistant/", method: "GET")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No Data", code: 0, userInfo: nil)))
                return
            }
            
            do {
                
                let assistants = try JSONDecoder().decode([SimpleAssistant].self, from: data)
                completion(.success(assistants))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func createAssistant(
        name: String,
        description: String?,
        temperature: Double,
        maxTokens: Int,
        model: String = "KazLLM",
        systemInstructions: String?,
        context: String?,
        completion: @escaping (Result<Assistant, Error>) -> Void
    ) {
        let payload: [String: Any] = [
            "name": name,
            "description": description ?? "",
            "temperature": temperature,
            "max_tokens": maxTokens,
            "model": model,
            "system_instructions": systemInstructions ?? "",
            "context": context ?? ""
        ]
        
        guard let body = try? JSONSerialization.data(withJSONObject: payload) else {
            fatalError("Failed to serialize JSON")
        }
        
        let request = createRequest(endpoint: "assistant/", method: "POST", body: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No Data", code: 0, userInfo: nil)))
                return
            }
            
            do {
                let assistant = try JSONDecoder().decode(Assistant.self, from: data)
                completion(.success(assistant))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func createInteraction(
        assistantID: Int,
        textPrompt: String,
        completion: @escaping (Result<InteractionResponse, Error>) -> Void
    ) {
        let payload: [String: Any] = [
            "text_prompt": textPrompt
        ]
        print(textPrompt)
        
        guard let body = try? JSONSerialization.data(withJSONObject: payload) else {
            fatalError("Failed to serialize JSON")
        }
        
        let request = createRequest(
            endpoint: "assistant/\(assistantID)/interactions/",
            method: "POST",
            body: body
        )
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No Data", code: 0, userInfo: nil)))
                return
            }
            
            do {
                    if let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        print("Response JSON: \(jsonObject)")
                    }
                } catch {
                    print("Failed to parse JSON for debugging: \(error.localizedDescription)")
                }
            print("DATA CAME")
            
            do {
                let response = try JSONDecoder().decode(InteractionResponse.self, from: data)
                completion(.success(response))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

// Models for Decoding
struct Assistant: Codable {
    let id: Int
    let name: String
    let description: String?
    let temperature: Double
    let maxTokens: Int
    let model: String
    let systemInstructions: String?
    let context: String?
}

struct InteractionResponse: Codable {
    let id: Int
    let filePrompt: Int?
    let vllmResponse: VLLMResponse
    
    enum CodingKeys: String, CodingKey {
        case id
        case filePrompt = "file_prompt"
        case vllmResponse = "vllm_response"
    }
}

struct VLLMResponse: Codable {
    let id: Int
    let content: String
    let promptTokenCount: Int
    let outputTokenCount: Int
    let totalTokensCount: Int
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case content
        case promptTokenCount = "prompt_token_count"
        case outputTokenCount = "output_token_count"
        case totalTokensCount = "total_tokens_count"
        case createdAt = "created_at"
    }
}


struct SimpleAssistant: Codable {
    let id: Int
    let name: String
}
