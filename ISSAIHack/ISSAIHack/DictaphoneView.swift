import SwiftUI

struct DictaphoneView: View {
    @StateObject private var service = SpeechToBase64Service()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Dictaphone")
                .font(.largeTitle)
                .bold()
            
            if service.isRecording {
                Text("Recording...")
                    .foregroundColor(.red)
            } else {
                Text("Not Recording")
                    .foregroundColor(.gray)
            }
            
            if !service.base64Result.isEmpty {
                ScrollView {
                    Text("Base64 Result:")
                        .font(.headline)
                    Text(service.base64Result)
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding()
                }
                .frame(height: 200)
                .border(Color.gray, width: 1)
            }
            
            if let error = service.error {
                Text("Error: \(error.localizedDescription)")
                    .foregroundColor(.red)
            }
            
            HStack {
                Button(action: {
                    service.startRecording()
                }) {
                    Text("Start Recording")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(10)
                }
                .disabled(service.isRecording)
                
                Button(action: {
                    service.stopRecording()
                }) {
                    Text("Stop Recording")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(10)
                }
                .disabled(!service.isRecording)
            }
        }
        .padding()
    }
}
