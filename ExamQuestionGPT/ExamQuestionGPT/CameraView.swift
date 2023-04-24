//
//  CameraView.swift
//  ExamQuestionGPT
//
//  Created by tmatsuda on 2023/04/24.
//

import SwiftUI
import Vision
import AVFoundation

struct CameraView: UIViewControllerRepresentable {
    @Binding var recognizedText: String

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> AVCaptureViewController {
        let controller = AVCaptureViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: AVCaptureViewController, context: Context) {
    }

    class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        let parent: CameraView
        let textRecognizer = TextRecognizer()

        init(_ parent: CameraView) {
            self.parent = parent
        }

        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

            let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])

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
                    self.parent.recognizedText = recognizedText
                }
            }
            request.recognitionLanguages = ["ja"]
            request.recognitionLevel = .accurate

            do {
                try imageRequestHandler.perform([request])
            } catch {
                print("Error performing text recognition: \(error)")
            }
        }
    }
}

class AVCaptureViewController: UIViewController {
    var delegate: AVCaptureVideoDataOutputSampleBufferDelegate?

    private let captureSession = AVCaptureSession()
    private let previewLayer = AVCaptureVideoPreviewLayer()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureCaptureSession()
    }

    private func configureCaptureSession() {
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("Unable to access back camera")
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            } else {
                print("Unable to add input to capture session")
                return
            }

            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.setSampleBufferDelegate(delegate, queue: DispatchQueue(label: "videoQueue"))

             if captureSession.canAddOutput(videoOutput) {
                 captureSession.addOutput(videoOutput)
             } else {
                 print("Unable to add output to capture session")
                 return
             }

             previewLayer.session = captureSession
             previewLayer.videoGravity = .resizeAspectFill
             view.layer.addSublayer(previewLayer)

             captureSession.startRunning()
         } catch {
             print("Error configuring capture session: \(error)")
         }
     }

     override func viewDidLayoutSubviews() {
         super.viewDidLayoutSubviews()
         previewLayer.frame = view.bounds
     }

     override func viewWillDisappear(_ animated: Bool) {
         super.viewWillDisappear(animated)
         captureSession.stopRunning()
     }
 }
