//
//  TextRecognizer.swift
//  ExamQuestionGPT
//
//  Created by tmatsuda on 2023/04/24.
//

import SwiftUI
import Vision
import AVFoundation

class TextRecognizer {
    func recognizeText(from image: UIImage, completion: @escaping (String) -> Void) {
        guard let cgImage = image.cgImage else { return }

        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        let request = VNRecognizeTextRequest { (request, error) in
            if let error = error {
                print("Error recognizing text: \(error)")
                return
            }
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }

            let recognizedText = observations
                .compactMap { $0.topCandidates(1).first }
                .map { $0.string }
                .joined(separator: "\n")

            DispatchQueue.main.async {
                completion(recognizedText)
            }
        }
        
        do {
            try requestHandler.perform([request])
        } catch {
            print("Error performing text recognition: \(error)")
        }
    }
}
