//
//  ChatGPTRequest.swift
//  ExamQuestionGPT
//
//  Created by tmatsuda on 2023/04/24.
//

import Foundation
let fileExtension = "txt"
let fileName = "api-key"
let url = URL(string: "https://api.openai.com/v1/chat/completions")!
let apiKey = readFile(named: fileName, withExtension: fileExtension).replacingOccurrences(of: "\n", with: "")

func readFile(named fileName: String, withExtension fileExtension: String) -> String {
    if let filePath = Bundle.main.path(forResource: fileName, ofType: fileExtension) {
        do {
            let contents = try String(contentsOfFile: filePath, encoding: .utf8)
            return contents
        } catch {
            return "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"
        }
    } else {
        return "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"
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
        "name": "get_jujutsukaisen_charactor_info",
        "description": "呪術廻戦のキャラクターの詳細についての情報を返却する関数",
        "parameters": [
            "type": "object",
            "properties": [
                "name": [
                    "type": "string",
                    "description": "呪術廻戦のキャラクターのフルネーム。例えば、虎杖悠仁、禪院真希、秤金次などの入力がある",
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
    
    var messages = [["role": "user", "content": "こんにちは。呪術廻戦の「伏黒甚爾」というキャラクターについての解説をお願いします。"]] as [[String:Any]]
    let promptData: [String: Any] = [
        "model": "gpt-3.5-turbo-0613",
        "temperature" : 0.2,
        "messages": messages,
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
            messages.append(message)
            try await next(arguments:arguments, _messages:messages, function_name:function_name)
        } catch {
            throw NSError(domain: "com.example.chatgpt", code: -1, userInfo: [NSLocalizedDescriptionKey: "APIから適切なデータが取得できませんでした"])
        }
    } else {
        throw NSError(domain: "com.example.chatgpt", code: -1, userInfo: [NSLocalizedDescriptionKey: "APIから適切なデータが取得できませんでした"])
    }
    
}

func next (arguments:String, _messages:[[String:Any]], function_name:String) async throws{
    var messages = _messages
    guard let data = arguments.data(using: .utf8) else {
        return
    }
    
    if  let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]{
        let function_response:String = getInfo(function_name:function_name, argumentsJson:jsonObject)
        messages.append([
            "role": "function",
            "name": function_name,
            "content": function_response,
        ])
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

func getInfo(function_name:String, argumentsJson:[String:Any]) -> String{
    let unknown = "unknonw"
    if(function_name == "get_jujutsukaisen_charactor_info") {
        guard let name = argumentsJson["name"] as? String else { return "unknonw" }
        if name == "伏黒甚爾" {
            return "「術師殺し」の異名を持つ殺し屋で、恵の実父である。自分が付けた実の息子の名前を忘れ、更に息子を担保に博打の資金を調達するほどに冷淡な人物である。自尊心は捨てたと自称するほど、基本的に面倒事を避ける性格で、危険を察知すると違和感を覚えてその場から逃げる。極めて特殊な「天与呪縛」の持ち主であり、呪力を完全に持たないにも関わらず、呪縛の強化によって視覚や嗅覚などの五感が呪霊を認識できるまでに鋭くなっており、呪霊を腹に入れる等、呪いへの耐性も獲得しており、戦闘に用いる呪具は、飼いならしている3級呪霊に携帯させている。さらに、跳躍だけで五条の「蒼」の効果範囲から脱出し、「赫」により弾き飛ばされても軽傷で済むなど、常人離れした身体能力を持つ。その反面、素手で呪霊を祓うことは出来ないため、生家である禪院家では酷い扱いを受けていた。やがて家を出て行き、恵の実母となる女性に婿入りして伏黒に改姓し、息子（恵）を授かったことで一時期は丸くなった。しかし、その妻が亡くなり、恵が小学1年生の時に津美紀の母親と付き合うも共に蒸発し、以降は女を転々とするヒモとなった。懐玉編では、盤星教「時の器の会」から3000万円の報酬で星漿体・天内理子の暗殺の依頼を受ける。最初に、天内の護衛をする五条の神経を削らせるために、同化の2日前から当日まで、闇の匿名掲示板で天内に3000万円の懸賞金をかけ、五条と夏油を賞金目当ての呪詛師達と闘わせた。同化当日の懸賞金失効後、呪力を持たない自分が高専の結界を突破できることを利用して自ら単身で高専に奇襲し、五条や夏油を退けて天内を殺害する。盤星教に彼女の遺体を引き渡した直後、反転術式で生還した五条に敗れ、2・3年後に自分の息子が禪院家に売られること告げて死亡する。それから10年以上後、五条が封印された際に、オガミ婆の降霊術によって彼女の孫に「禪院甚爾」の肉体の情報が降ろされるが、降ろされた肉体（禪院甚爾）が霊媒（孫）の魂を上書きしてしまい、結果的に伏黒甚爾が完全に復活してしまう。甚爾は復活直後にオガミ婆を撲殺したが、オガミ婆の死後も降霊術は継続していた。さらに禪院甚爾の特殊性故に終了する契機を失ったため、術式は暴走し、強者ただ狙う殺戮人形と化した。陀艮の領域から脱出しようとした恵達の前に現れ、彼らを圧倒していた陀艮を逆に圧倒する。その後恵と交戦する中で、彼がわが子であると理解し、彼が禅院ではなく伏黒と名乗ったことに笑みを浮かべると、自ら命を絶った。"
        } else {
            return "そんなやつの名前は知らんなぁ"
        }
    }
    return unknown
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
