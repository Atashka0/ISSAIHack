import Foundation

struct SoyleAPI {
    private let baseAudioURL = "https://soyle.nu.edu.kz/api/translate/audio/?output_format=text"
    private let apiKey = "C4O6EJmnOuO2kbWmDLW3vg"
    
    func translateAudio(
        targetLanguage: String,
        audioBase64: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let url = URL(string: baseAudioURL) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let requestBody: [String: Any] = [
            "target_language": targetLanguage,
            "audio": audioBase64
        ]
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: requestBody, options: []) else {
            completion(.failure(NSError(domain: "Failed to encode JSON", code: 0, userInfo: nil)))
            return
        }
        request.httpBody = httpBody
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                completion(.failure(NSError(domain: "HTTP Error", code: statusCode, userInfo: nil)))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No Data", code: 0, userInfo: nil)))
                return
            }
            
            do {
                if let responseJSON = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let translatedAudioBase64 = responseJSON["text"] as? String {
                    completion(.success(translatedAudioBase64))
                } else {
                    completion(.failure(NSError(domain: "Invalid JSON Response", code: 0, userInfo: nil)))
                }
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    func translateText(
        sourceLanguage: String,
        targetLanguage: String,
        text: String,
        gender: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let baseTextURL = "https://soyle.nu.edu.kz/api/translate/text/?output_format=audio&output_voice=\(gender)"
        guard let url = URL(string: baseTextURL) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let requestBody: [String: Any] = [
            "source_language": sourceLanguage,
            "target_language": targetLanguage,
            "text": text
        ]
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: requestBody, options: []) else {
            completion(.failure(NSError(domain: "Failed to encode JSON", code: 0, userInfo: nil)))
            return
        }
        request.httpBody = httpBody
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                completion(.failure(NSError(domain: "HTTP Error", code: statusCode, userInfo: nil)))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No Data", code: 0, userInfo: nil)))
                return
            }
            
            do {
                if let responseJSON = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let translatedText = responseJSON["audio"] as? String {
                    completion(.success(translatedText))
                } else {
                    completion(.failure(NSError(domain: "Invalid JSON Response", code: 0, userInfo: nil)))
                }
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
//    func checkAPI() {
//        self.translateText(sourceLanguage: "rus", targetLanguage: "rus", text: "Я тебя так сильно люблю") { res in
//            switch res {
//            case .success(let translatedText):
//                print("Translated Text: \(translatedText)")
//            case .failure(let error):
//                print("Error: \(error.localizedDescription)")
//            }
//        }
//    }
}
