import SwiftUI
import SDWebImageSwiftUI
import PhotosUI

let lottieNames: [String] = [
    "abay.mp4.lottie"
]

let names: [String] = [
    "Абай Құнанбаев"
]

struct AddCharacterCardView: View {
    @Binding var characters: [Character]
    @State private var selectedImage: UIImage? = nil

    var body: some View {
        VStack {
            NavigationLink(destination: AddCharacterForm(characters: $characters, selectedImage: $selectedImage)) {
                VStack {
                    Image(systemName: "plus.circle")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.white)
                        .padding()
                }
                .frame(width: 300, height: 300)
                .background(Color.black.opacity(0.5))
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 4))
                .shadow(radius: 10)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
    }
}


struct AddCharacterForm: View {
    @Binding var characters: [Character]
    @Binding var selectedImage: UIImage?
    @State private var gender: String = "male"
    
    @State private var name: String = ""
    @State private var description: String = ""
    @State private var isImagePickerPresented = false
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedLanguage: String = "Қазақша"
    
    var body: some View {
        ZStack {
            
            VStack(spacing: 20) {
                
                
                VStack {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 150, height: 150)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            .shadow(radius: 15)
                    } else {
                        Button(action: {
                            isImagePickerPresented = true
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.black.opacity(0.4))
                                    .frame(width: 150, height: 150)
                                Image(systemName: "photo")
                                    .font(.system(size: 40))
                                    .foregroundColor(.black.opacity(0.7))
                            }
                            .shadow(radius: 15)
                        }
                    }
                }
                .padding(.top, 100)
                .padding(.bottom, 20)
                
                
                VStack(spacing: 15) {
                    TextField("Атын енгізіңіз", text: $name)
                        .placeholder(when: name.isEmpty) {
                            Text("Атын енгізіңіз").foregroundColor(.gray)
                        }
                        .textFieldStyle(PlainTextFieldStyle())
                        .foregroundColor(.black)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.black, lineWidth: 2)
                                )
                        )
                        .padding(.horizontal)
                    
                    TextField("Қысқаша сипаттама қосыңыз", text: $description)
                        .placeholder(when: description.isEmpty) {
                            Text("Қысқаша сипаттама қосыңыз").foregroundColor(.gray)
                        }
                        .textFieldStyle(PlainTextFieldStyle())
                        .foregroundColor(.black)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.black, lineWidth: 2)
                                )
                        )
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Жынысы")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.leading, 20)
                        
                        HStack {
                            Button(action: {
                                gender = "male"
                            }) {
                                Text("Еркек")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(gender == "male" ? .white : .gray)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(gender == "male" ? Color.black : Color.white.opacity(0.7))
                                    .cornerRadius(12)
                            }
                            
                            Button(action: {
                                gender = "female"
                            }) {
                                Text("Әйел")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(gender == "female" ? .white : .gray)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(gender == "female" ? Color.black : Color.white.opacity(0.7))
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                
                Spacer()

                Picker("Language", selection: $selectedLanguage) {
                    ForEach(["English", "Русский", "Қазақша", "Turkish"], id: \.self) { language in
                        Text(language)
                            .tag(language) // Tag each language for selection
                    }
                }
                .background(.black)
                .pickerStyle(SegmentedPickerStyle()) // Segment style for buttons
                .padding()
                
                Spacer()
                
                // Buttons
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Болдырмау")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.black.opacity(0.8))
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }
                    
                    Button(action: {
                        addCharacter()
                        dismiss()
                    }) {
                        Text("Қосу")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.black)
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }
                    .disabled(name.isEmpty || description.isEmpty || selectedImage == nil)
                    .opacity(name.isEmpty || description.isEmpty || selectedImage == nil ? 0.6 : 1.0)
                }
                .padding(.bottom, 80)
                
            }
        }
        .background(
            Image("wall")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea(.all)
        )
        .sheet(isPresented: $isImagePickerPresented) {
            PhotoPicker(selectedImage: $selectedImage)
        }
        .navigationBarBackButtonHidden(true)
    }
    
    private func addCharacter() {
        guard let image = selectedImage, let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("Invalid image data")
            return
        }
        
        CharacterAPI().createAssistant(
            name: name,
            description: description,
            gender: gender,
            fileData: imageData
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let character):
                    print("ADDED")
                    characters.append(character)
                    
                case .failure(let error):
                    print("Failed to add character: \(error.localizedDescription)")
                }
            }
        }
    }
}


struct CharacterSelectionView: View {
    @State private var selectedCharacterIndex: Int = 0
    @State private var navigateToVoiceInteraction = false
    @State private var characters: [Character] = []
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    @State private var timer: Timer?
    @State private var hasLoaded = false
    
    var body: some View {
            NavigationView {
                ZStack {
                    if isLoading {
                        ProgressView("Таңбалар жүктелуде...")
                            .font(.title)
                            .foregroundColor(.white)
                            .background {
                                Image("wall")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: UIScreen.main.bounds.height + 50)
                                    .ignoresSafeArea()
                            }
                    } else if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding()
                    } else {
                        VStack {

                            TabView(selection: $selectedCharacterIndex) {
                                ForEach(characters.indices, id: \.self) { index in
                                    if index < 1 {
                                        CharacterCardViewLottie(lottieAnimationName: lottieNames[index], name: names[index])
                                            .tag(index)
                                    } else {
                                        CharacterCardView(character: characters[index])
                                                                            .tag(index)
                                    }
                                }

                                AddCharacterCardView(characters: $characters)
                                    .tag(characters.count)
                            }
                            .tabViewStyle(.page(indexDisplayMode: .always))
                            .frame(height: 500)

                            Spacer()

                            if selectedCharacterIndex < 1 {
                                NavigationLink(
                                    destination:
                                        VoiceInteractionViewLottie(lottieAnimationName: lottieNames[selectedCharacterIndex])
                                    ,
                                    isActive: $navigateToVoiceInteraction
                                ) {
                                    Button(action: {
                                        navigateToVoiceInteraction = true
                                    }) {
                                        ZStack {
                                            // Rectangle background
                                            Rectangle()
                                                .fill(Color.black.opacity(0.9))
                                                .frame(maxWidth: .infinity)
                                                .frame(height: 60)
                                                .cornerRadius(16)

                                            Text("Таңдау")
                                                .font(.system(size: 25, weight: .semibold, design: .rounded))
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .padding()
                                }
                            } else if selectedCharacterIndex < characters.count {
                                let selectedCharacter = characters[selectedCharacterIndex]

                                if selectedCharacter.status == "COMPLETED" {
                                    NavigationLink(
                                        destination: VoiceInteractionView(character: selectedCharacter),
                                        isActive: $navigateToVoiceInteraction
                                    ) {
                                        Button(action: {
                                            navigateToVoiceInteraction = true
                                        }) {
                                            ZStack {
                                                Rectangle()
                                                    .fill(Color.black.opacity(0.9))
                                                    .frame(maxWidth: .infinity)
                                                    .frame(height: 60)
                                                    .cornerRadius(16)

                                                Text("Таңдау")
                                                    .font(.system(size: 25, weight: .semibold, design: .rounded))
                                                    .foregroundColor(.white)
                                            }
                                        }
                                        .padding()
                                    }
                                } else {
                                    Text("Кейіпкерлерді қалыптастыру әлі де жалғасуда.")
                                        .font(.body)
                                        .foregroundColor(.black)
                                        .padding()
                                }
                            }
                        }
                        .background {
                            Image("wall")
                                .resizable()
                                .scaledToFill()
                                .frame(height: UIScreen.main.bounds.height + 50)
                                .ignoresSafeArea()
                        }
                    }
                }
                .onAppear {
                    if !hasLoaded {
                        hasLoaded = true
                        fetchCharacters(firstTime: true)
                        startAutoRefresh()
                    }
                }
                .onDisappear {
                    stopAutoRefresh()
                }
                .navigationBarBackButtonHidden(true)
            }
            .navigationBarBackButtonHidden(true)
        }
    private func startAutoRefresh() {
        timer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { _ in
            fetchCharacters(firstTime: false)
        }
    }
    
    private func stopAutoRefresh() {
        timer?.invalidate()
        timer = nil
    }
    
    
    private func fetchCharacters(firstTime: Bool) {
        if firstTime {
            isLoading = true
        }
        errorMessage = nil
        
        CharacterAPI().fetchCharacters { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let fetchedCharacters):
                    characters = fetchedCharacters
                case .failure(let error):
                    errorMessage = "Failed to load characters: \(error.localizedDescription)"
                }
            }
        }
    }
}

struct CharacterCardView: View {
    let character: Character
    @State var isPlaying: Bool = true
    
    var body: some View {
        VStack {
            if character.status == "COMPLETED" {
                AnimatedImage(url: URL(string: character.gifUrl ?? ""))
                    .resizable()
                    .scaledToFill()
                    .frame(width: 300, height: 300)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.black, lineWidth: 4))
                    .shadow(radius: 10)
                    .padding()
                
                Text(character.name)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.white)
            } else {
                VStack {
                    Spacer()
                    Text(character.name)
                        .foregroundColor(.white)
                        .font(.title)
                        .padding(.top, 10)
                    LottieView(animationName: "creation.lottie", isPlaying: $isPlaying)
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
    }
}

struct CharacterCardViewLottie: View {
    let lottieAnimationName: String
    let name: String
    @State var isPlaying: Bool = true
    
    var body: some View {
        VStack {
            LottieView(animationName: lottieAnimationName, isPlaying: $isPlaying)
                .frame(width: 300, height: 300)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.black, lineWidth: 4))
            .shadow(radius: 10)
            .padding()
            
            
//            Spacer()
            
            Text(name)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity, alignment: .center)
                .foregroundColor(.white)
//                .padding(.bottom, 40)
                
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
    }
}


struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: PhotoPicker
        
        init(_ parent: PhotoPicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            picker.dismiss(animated: true)
            
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

extension UIImage {
    func toBase64String() -> String {
        guard let imageData = self.pngData() else { return "" }
        return imageData.base64EncodedString()
    }
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            if shouldShow {
                placeholder()
            }
            self
        }
    }
}
