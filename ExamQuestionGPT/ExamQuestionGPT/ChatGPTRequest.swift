//
//  ChatGPTRequest.swift
//  ExamQuestionGPT
//
//  Created by tmatsuda on 2023/04/24.
//

import Foundation

let apiKey = "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"

func DALLEimageRequest() async throws -> URL?{
    let url = URL(string: "https://api.openai.com/v1/images/generations")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    
    let promptData: [String: Any] = [
        "prompt": "温泉に入る日本猿",
        "n": 1,
        "size": "512x512"
    ]
    
    request.httpBody = try JSONSerialization.data(withJSONObject: promptData, options: [])
    
    let (responseData, _) = try await URLSession.shared.data(for: request)
    if let responseObject = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String: Any],
       let datas = (responseObject["data"] as? [[String:Any]]){
        
        guard let data = datas.first, let resultURL = data["url"] as? String else {
            throw NSError(domain: "com.example.chatgpt", code: -1, userInfo: [NSLocalizedDescriptionKey: "APIから適切なデータが取得できませんでした"])
        }
        
        return URL(string: resultURL)
    } else {
        throw NSError(domain: "com.example.chatgpt", code: -1, userInfo: [NSLocalizedDescriptionKey: "APIから適切なデータが取得できませんでした"])
    }
    
    
}



func chatGPTRequest(prompt: String) async throws -> [Choice]{
    let url = URL(string: "https://api.openai.com/v1/chat/completions")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    
    let promptData: [String: Any] = [
        "model": "gpt-3.5-turbo",
        "temperature" : 0.2,
        "messages": [
            ["role": "system", "content":prompt]
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

func createPromptQuestion(text:String) -> String {
    let prompt = [
    "[本文開始VRE$DFR#%ASQ]~[本文終了GM%&$%#EDF#E@]で囲まれる範囲の文に対して質問文と回答例を１つ作成してください。",
    "質問文は１文、回答例は１００文字以内でお願いします。",
    "あなたの回答は[フォーマット開始D&32H3aw]~[フォーマット終了%u363!@#]に囲まれるテンプレートの$質問文$と$回答例$を置換する形式で作成してください。",
    "[本文開始VRE$DFR#%ASQ]",
    "",
    "[本文終了GM%&$%#EDF#E@]",
    "[フォーマット開始D&32H3aw]",
    "Q:$質問文$",
    "A:$回答例$",
    "[フォーマット開始%u363!@#]"
    ].joined(separator: "\n")
    return prompt
}


func createPromptRecovery(text:String) -> String {
    let prompt = [
    "[本文開始VRE$DFR#%ASQ]~[本文終了GM%&$%#EDF#E@]で囲まれる範囲の文章をOCRで認識しました。",
    "この文章はOCRで認識したもののため、多数の誤字脱字を含むことが想定されます。",
    "あなたはこの文章の誤字脱字を正しく補正することです。回答は[フォーマット開始D&32H3aw]~[フォーマット終了%u363!@#]に囲まれるテンプレートの$補正結果$を置換する形式で作成してください。",
    "[本文開始VRE$DFR#%ASQ]",
    text,
    "[本文終了GM%&$%#EDF#E@]",
    "[フォーマット開始D&32H3aw]",
    "Recover:$補正結果$",
    "[フォーマット開始%u363!@#]"
    ].joined(separator: "\n")
    return prompt
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
