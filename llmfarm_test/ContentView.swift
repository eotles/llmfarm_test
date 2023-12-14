//
//  ContentView.swift
//  llmfarm_test
//
//  Created by Erkin Otles on 12/13/23.
//

import SwiftUI
import Foundation
import llmfarm_core

// ViewModel to handle AI interactions
class AIViewModel: ObservableObject {
    @Published var response: String = ""
    private var ai: AI?

    init() {
        // Check if in preview mode
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            print("In Preview Mode: Skipping model load.")
            ai = nil
            return
        }

        // Model loading code
        //let modelPath = Bundle.main.path(forResource: "llama-2-7b.Q4_K_M", ofType: "gguf")!
        let modelPath = Bundle.main.path(forResource: "mistral-7b-instruct-v0.1.Q4_K_M", ofType: "gguf")!
        
        ai = AI(_modelPath: modelPath, _chatName: "chat")
        //var params: ModelContextParams = .default
        var params: ModelAndContextParams = .default
        params.use_metal = false
        //params.use_metal = true
        
        print(params)
        
        try? ai?.loadModel(ModelInference.LLama_gguf, contextParams: params)
        //ai.model.promptFormat = .LLaMa
    }

    func askAI(_ input: String) {
        let maxOutputLength = 65536
        var totalOutput = 0

        let mainCallback: (String, Double) -> Bool = { str, _ in
            DispatchQueue.main.async {
                self.response += str
            }
            totalOutput += str.count
            return totalOutput > maxOutputLength
        }
        
        print(input)

        DispatchQueue.global().async {
            if let ai = self.ai {
                try? ai.model.predict(input, mainCallback)
            } else {
                print("AI model is not initialized")
            }
        }
    }
}

struct ContentView: View {
    @State private var inputText: String = ""
    @ObservedObject private var viewModel = AIViewModel()

    var body: some View {
        VStack {
            //TextField("Ask something", text: $inputText)
            //    .padding()
            
            ZStack(alignment: .topLeading) {
                if inputText.isEmpty {
                    Text("Type your question here...")
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                        .padding(.leading, 5)
                }
                TextEditor(text: $inputText)
                    .padding(4)
            }
            .frame(minHeight: 100, maxHeight: 300)
            .padding()
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray, lineWidth: 1)
            )
            
            Button("Send") {
                viewModel.askAI(inputText)
            }
            Text(viewModel.response)
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
