//
//  ChatGPTRequest.swift
//  ExamQuestionGPT
//
//  Created by tmatsuda on 2023/04/24.
//

import Foundation

let apiKey = "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"

func chatGPTRequest(prompt: String) async throws -> [Choice]{
    let url = URL(string: "https://api.openai.com/v1/chat/completions")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    
    let promptData: [String: Any] = [
        "model": "gpt-3.5-turbo",
        "messages": [
            ["role": "user", "content":prompt]
        ]
    ]
    
    request.httpBody = try JSONSerialization.data(withJSONObject: promptData, options: [])
    
    let (data, response) = try await URLSession.shared.data(for: request)
    if let responseObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
       let choices = (responseObject["choices"] as? [[String:Any]]){
        return choices.map{ Choice(val: $0) }
    } else {
        throw NSError(domain: "com.example.chatgpt", code: -1, userInfo: [NSLocalizedDescriptionKey: "APIから適切なデータが取得できませんでした"])
    }
}


struct Choice {
    let message:[String:String]
    let finishi_reason:String
    let index:Int
    init(val:[String:Any]){
        index = (val["index"] as? Int) ?? -1
        finishi_reason = (val["finishi_reason"] as? String) ?? ""
        message = (val["message"] as? [String:String]) ?? [:]
    }
}
