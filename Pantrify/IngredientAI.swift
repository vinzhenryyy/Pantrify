//
//  IngredientAI.swift
//  Pantrify
//
//  Created by STUDENT on 9/29/25.
//

import Foundation
let OPENAI_API_KEY = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""

func detectUnitWithOpenAI(for ingredient: String, completion: @escaping (String) -> Void) {
    let url = URL(string: "https://api.openai.com/v1/chat/completions")!
    
    let body: [String: Any] = [
        "model": "gpt-4o-mini",
        "messages": [[
            "role": "system",
            "content": "You are a food unit classifier. Respond only with 'grams', 'liters', or 'pieces'."
        ], [
            "role": "user",
            "content": "Ingredient: \(ingredient)"
        ]]
    ]
    
    let jsonData = try! JSONSerialization.data(withJSONObject: body)
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue("Bearer \(OPENAI_API_KEY)", forHTTPHeaderField: "Authorization")
    request.httpBody = jsonData
    
    URLSession.shared.dataTask(with: request) { data, _, error in
        if let error = error {
            print("❌ OpenAI request error:", error)
            completion("pieces")
            return
        }
        guard let data = data else {
            completion("pieces")
            return
        }
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let message = choices.first?["message"] as? [String: Any],
               let content = message["content"] as? String {
                
                let answer = content.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                switch answer {
                case "grams": completion("grams")
                case "liters": completion("liters")
                case "pieces": completion("pieces")
                default:
                    print("⚠️ Unexpected OpenAI response:", answer)
                    completion("pieces")
                }
            } else {
                print("⚠️ No valid response:", String(data: data, encoding: .utf8) ?? "")
                completion("pieces")
            }
        } catch {
            print("❌ JSON parse error:", error)
            completion("pieces")
        }
    }.resume()
}
