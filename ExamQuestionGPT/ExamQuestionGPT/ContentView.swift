//
//  ContentView.swift
//  ExamQuestionGPT
//
//  Created by tmatsuda on 2023/04/24.
//

import SwiftUI

struct ContentView: View {
    @State private var recognizedText: String = ""
    @State private var confirmedText: String = ""
    @State private var isShowingCamera = false

    var body: some View {

        if isShowingCamera {
            ZStack {
                CameraView(recognizedText: $recognizedText)
                    .edgesIgnoringSafeArea(.all)
                

                VStack {

                    Spacer()

                    CameraButton()
                    
                    VStack {
                        Text(recognizedText)
                            .frame(width: 300, height:200)
                            .padding()
                    }
                    .foregroundColor(.black)
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(8)
                    .padding(.bottom, 16)
                    
                }
            }

        } else  {
            VStack {
                Text("Confirmed Text:")
                Text(confirmedText)
                    .padding()
            }
            
            Button (action:{
                
                Task.init {
                    
                    do {
                        let prompt = "ChatGPTに関連するSwiftコードの例を教えてください。"
                        let response = try await chatGPTRequest(prompt: prompt)
                        print("Response: \(response)")
                        
                        confirmedText = response.last?.message["content"] ?? "no_message"
                    } catch {
                        print("Error: \(error.localizedDescription)")
                    }
                }
            }) {
                Text("ChatGPT")
            }
            
            CameraButton()
        }
    }
    
    func CameraButton() -> some View {
        return Button(action: {
                confirmedText = recognizedText
                isShowingCamera.toggle()
        }) {
            Text(isShowingCamera ? "Capture Text" : "Start Camera")
        }
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
