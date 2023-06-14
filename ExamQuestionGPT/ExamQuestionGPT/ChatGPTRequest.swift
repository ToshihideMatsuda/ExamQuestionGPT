//
//  ChatGPTRequest.swift
//  ExamQuestionGPT
//
//  Created by tmatsuda on 2023/04/24.
//

import Foundation
let fileExtension = "txt"
let fileName = "api-key"

let apiKey = readFile(named: fileName, withExtension: fileExtension).replacingOccurrences(of: "\n", with: "")

func readFile(named fileName: String, withExtension fileExtension: String) -> String {
    if let filePath = Bundle.main.path(forResource: fileName, ofType: fileExtension) {
        do {
            let contents = try String(contentsOfFile: filePath, encoding: .utf8)
            return contents
        } catch {
            return ""
        }
    } else {
        return ""
    }
}



func DALLEimageRequest() async throws -> URL?{
    let url = URL(string: "https://api.openai.com/v1/images/generations")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    
    let promptData: [String: Any] = [
        "prompt": "dark moss-green forest, narrow trail",
        // japanese Anime Girl's back view a litle far, girl is zombi ",
        //"white background, deformed two lions, dynamic, religious painting-like",
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
    text,
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

let functions:[[String:Any]] = [
    [
        "name": "get_iroleplay_quiz",
        "description": "iRolePlayに関する問題とその答えをランダムで出題します。",
        "parameters": [
            "type": "object",
            "properties": [
                "seed": [
                    "type": "string",
                    "description": "ランダムのためのseed",
                ],
            ]
        ]
        /*,
        "parameters": [
            "type": "object",
            "properties" : "null"
        ],
        "parameters": [
            "type": "object",
            "properties": [
                "location": [
                    "type": "string",
                    "description": "The city and state, e.g. San Francisco, CA",
                ],
                "unit": ["type": "string", "enum": ["celsius", "fahrenheit"]],
                 
            ],
            "required": ["location"],
        ]
         */
    ],
    [
        "name": "get_iroleplay_answer",
        "description": "iRolePlayに関する問題の答えを返します。",
        "parameters": [
            "type": "object",
            "properties": [
                "quiz": [
                    "type": "string",
                    "description": "get_iroleplay_quiz関数にて取得したquiz項目のみ受け付ける"
                ],
            ],
            "required": ["quiz"],
        ]
    ]
]
func testChatGPTFunc() async throws{
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    
    let promptData: [String: Any] = [
        "model": "gpt-3.5-turbo-0613",
        "temperature" : 0.2,
        "messages": [
            ["role": "user", "content": "こんにちは。iRolePlayに関する問題を出題してください"]
        ],
        "functions" : functions,
        "function_call" : "auto"
    ]
    
    request.httpBody = try JSONSerialization.data(withJSONObject: promptData, options: [])
    
    let (data, response) = try await URLSession.shared.data(for: request)
    if let responseObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
       let choices = (responseObject["choices"] as? [[String:Any]]),
       let message = choices[0]["message"] as? [String:Any],
       let function_call = message["function_call"] as? [String:Any],
       let function_name = function_call["name"] as? String,
       let arguments = function_call["arguments"] as? String {
        do {
            try await next(arguments:arguments, message:message, function_name:function_name)
        } catch {
            throw NSError(domain: "com.example.chatgpt", code: -1, userInfo: [NSLocalizedDescriptionKey: "APIから適切なデータが取得できませんでした"])
        }
    } else {
        throw NSError(domain: "com.example.chatgpt", code: -1, userInfo: [NSLocalizedDescriptionKey: "APIから適切なデータが取得できませんでした"])
    }
    
}

func next (arguments:String, message:[String:Any], function_name:String) async throws{
    
    guard let data = arguments.data(using: .utf8) else {
        return
    }
    
    if  let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]{
        
        let function_response:String = get_iroleplay_quiz()
        var messages = [
            ["role": "user", "content": "こんにちは。iRolePlayに関する問題を出題してください。答えは私が回答してから教えてください。"],
            message,
            [
                "role": "function",
                "name": function_name,
                "content": function_response,
            ]
        ]
        let replyData: [String: Any] = [
           "model": "gpt-3.5-turbo-0613",
           "temperature" : 0.2,
           "messages": messages
        ]
        
        do {
            print(String(data: try JSONSerialization.data(withJSONObject: replyData, options: []), encoding: .utf8)!)
        }
        
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        request.httpBody = try JSONSerialization.data(withJSONObject: replyData, options: [])
        
        let (data, response) = try await URLSession.shared.data(for: request)
        if let responseObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
           let choices = (responseObject["choices"] as? [[String:Any]]),
           let message2 = choices[0]["message"] as? [String:Any] {
            
             do {
                 try await next2(_messages:messages, message:message2)
             } catch {
                 throw NSError(domain: "com.example.chatgpt", code: -1, userInfo: [NSLocalizedDescriptionKey: "APIから適切なデータが取得できませんでした"])
             }
            
            return
        }
    }
    
    throw NSError(domain: "com.example.chatgpt", code: -1, userInfo: [NSLocalizedDescriptionKey: "APIから適切なデータが取得できませんでした"])
   
}

func next2(_messages:[[String:Any]], message:[String:Any]) async throws{
    var messages = _messages
    messages.append(message)
    //messages.append(["role": "user", "content": "うーん、例えば営業担当者の労力が小さくなるとかですかね。答えを教えてください。"])
    messages.append(["role": "user", "content": "うーん、例えばお腹いっぱいご飯が食べられることですかね。答えを教えてください。"])

    let replyData: [String: Any] = [
       "model": "gpt-3.5-turbo-0613",
       "temperature" : 0.2,
       "messages": messages,
       "functions" : functions,
       "function_call" : "auto"
    ]
    
    do {
        print(String(data: try JSONSerialization.data(withJSONObject: replyData, options: []), encoding: .utf8)!)
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    
    request.httpBody = try JSONSerialization.data(withJSONObject: replyData, options: [])
    let (data, response) = try await URLSession.shared.data(for: request)
    if let responseObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
       let choices = (responseObject["choices"] as? [[String:Any]]),
       let message3 = choices[0]["message"] as? [String:Any] {
        
        do {
            print(String(data: try JSONSerialization.data(withJSONObject: message3, options: []), encoding: .utf8)!)
        }
        if let function_call = message3["function_call"] as? [String:Any],
            let function_name = function_call["name"] as? String,
            let arguments = function_call["arguments"] as? String {
            do {
                try await next3(arguments:arguments, function_name:function_name, _messages:messages)
            } catch {
                throw NSError(domain: "com.example.chatgpt", code: -1, userInfo: [NSLocalizedDescriptionKey: "APIから適切なデータが取得できませんでした"])
            }
        } else {
            throw NSError(domain: "com.example.chatgpt", code: -1, userInfo: [NSLocalizedDescriptionKey: "APIから適切なデータが取得できませんでした"])
        }
    } else {
        throw NSError(domain: "com.example.chatgpt", code: -1, userInfo: [NSLocalizedDescriptionKey: "APIから適切なデータが取得できませんでした"])
    }
    
}


func next3 (arguments:String, function_name:String, _messages:[[String:Any]]) async throws{
    
    guard let data = arguments.data(using: .utf8) else {
        return
    }
    
    if  let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]{
        let quiz = jsonObject["quiz"]
        
        let function_response:String = get_iroleplay_answer()
        var messages = _messages
        messages.append(
            [
                "role": "function",
                "name": function_name,
                "content": function_response,
            ]
        )
        let replyData: [String: Any] = [
           "model": "gpt-3.5-turbo-0613",
           "temperature" : 0.2,
           "messages": messages
        ]
        
        do {
            print(String(data: try JSONSerialization.data(withJSONObject: replyData, options: []), encoding: .utf8)!)
        }
        
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        request.httpBody = try JSONSerialization.data(withJSONObject: replyData, options: [])
        
        let (data, response) = try await URLSession.shared.data(for: request)
        if let responseObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
           let choices = (responseObject["choices"] as? [[String:Any]]),
           let message2 = choices[0]["message"] as? [String:Any] {
            
            messages.append(message2)
            print(messages)
            
            return
        }
    }
    
    throw NSError(domain: "com.example.chatgpt", code: -1, userInfo: [NSLocalizedDescriptionKey: "APIから適切なデータが取得できませんでした"])
   
}



func get_current_weather(location:String, unit:String = "fahrenheit") -> String {
    let data = [
        "location": location,
        "temperature": "72",
        "unit": unit,
        "forecast": ["sunny", "windy"],
    ] as [String:Any]
    
    do {
        return String(data: try JSONSerialization.data(withJSONObject: data, options: []), encoding: .utf8) ?? "unknown"
    } catch {
        return "unknown"
    }
}

func get_iroleplay_quiz() -> String {
    let data = [
        "quiz": "iRolePlayに関して営業担当者の価値"
    ] as [String:String]
    
    do {
        return String(data: try JSONSerialization.data(withJSONObject: data, options: []), encoding: .utf8) ?? "unknown"
    } catch {
        return "unknown"
    }
}

func get_iroleplay_answer() -> String {
    
    let data = [
        "answer": "営業担当者の労力が小さくなります。",
    ] as [String:String]
    
    do {
        return String(data: try JSONSerialization.data(withJSONObject: data, options: []), encoding: .utf8) ?? "unknown"
    } catch {
        return "unknown"
    }
}
