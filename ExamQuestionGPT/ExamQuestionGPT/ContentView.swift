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
    @State private var showAlert = false


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
                Text("質問文:")
                Text(confirmedText)
                    .padding()
            }
            
            CameraButton()
        }
    }
    
    func CameraButton() -> some View {
        return Button(action: {
            isShowingCamera.toggle()
            if( isShowingCamera == false) {
                showAlert = true
            }
        }) {
            Text(isShowingCamera ? "Capture Text" : "Start Camera")
        }.alert(isPresented: $showAlert) {
            Alert(
                title:    Text("質問作成"),
                message:  Text("文字認識した内容をもとにChatGPTで質問文を作成しますか？"),
                primaryButton: .default(Text("OK")) {
                    confirmedText = ""
                    Task.init {
                        do {
                            let templateCnt = createPromptRecovery(text:"").count
                            let recognizeTextLimited = String(recognizedText.prefix(4096 - templateCnt))
                            print("original:" + recognizeTextLimited)
                            let recoveryPrompt = createPromptRecovery(text:recognizeTextLimited)
                            
                            let response = try await chatGPTRequest(prompt: recoveryPrompt)
                            guard let recoveryMessage = response.last?.message["content"] else {
                                print("Error:FormatError")
                                return
                            }
                            print("recoveryMessage:" + recoveryMessage)
                            
                            let templateCntQuestion = createPromptQuestion(text:"").count
                            let recoveryMessageLimited = String(recoveryMessage.prefix(4096 - templateCntQuestion))
                            let questionPrompt = createPromptQuestion(text:recoveryMessageLimited)
                                
                            let responseQuestion = try await chatGPTRequest(prompt: questionPrompt)
                            guard let recoveryMessage = responseQuestion.last?.message["content"] else {
                                print("Error:FormatError")
                                return
                            }
                            
                            confirmedText = recoveryMessage
                            
                        } catch {
                            print("Error: \(error.localizedDescription)")
                        }
                    }
                    showAlert = false
                },
                secondaryButton: .cancel(Text("キャンセル")) {
                    confirmedText = recognizedText
                    showAlert = false
                }
            )
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
