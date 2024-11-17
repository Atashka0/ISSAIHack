import SwiftUI
import SDWebImageSwiftUI
import PhotosUI

struct AddCharacterCardView: View {
    @Binding var characters: [Character]
    @State private var isFormPresented = false
    @State private var selectedImage: UIImage? = nil

    var body: some View {
        VStack {
            Button(action: {
                isFormPresented = true
            }) {
                VStack {
                    Image(systemName: "plus.circle")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.white)
                        .padding()

                    Text("Жаңа таңба қосыңыз")
                        .foregroundColor(.white)
                        .font(.title2)
                        .padding(.top, 10)
                }
            }
            .frame(width: 300, height: 300)
            .background(Color.black.opacity(0.5))
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white, lineWidth: 4))
            .shadow(radius: 10)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .sheet(isPresented: $isFormPresented) {
            AddCharacterForm(
                characters: $characters,
                selectedImage: $selectedImage
            )
        }
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

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Жаңа кейіпкер")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)

                VStack {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 200, height: 200)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.black, lineWidth: 3))
                            .shadow(radius: 5)
                            .padding(.bottom, 10)
                    } else {
                        Button(action: {
                            isImagePickerPresented = true
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 200, height: 200)
                                Image(systemName: "photo")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }

                VStack(spacing: 15) {
                    TextField("Атын енгізіңіз", text: $name)
                        .padding()
                        .frame(height: 60)
                        .background(Color.white)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black, lineWidth: 2)
                        )
                        .padding(.horizontal)

                    TextField("Қысқаша сипаттама қосыңыз", text: $description)
                        .padding()
                        .frame(height: 60)
                        .background(Color.white)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black, lineWidth: 2)
                        )
                        .padding(.horizontal)
                    
                    Picker("Жынысы", selection: $gender) {
                        Text("Еркек").tag("male")
                        Text("Әйел").tag("female")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                }
                .padding(.vertical, 10)


                Spacer()

                // Buttons
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Болдырмау")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }

                    Button(action: {
                        addCharacter()
                        dismiss()
                    }) {
                        Text("Қосу")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                    .disabled(name.isEmpty || description.isEmpty || selectedImage == nil)
                    .opacity(name.isEmpty || description.isEmpty || selectedImage == nil ? 0.6 : 1.0)
                }
            }
            .padding()
        }
        .sheet(isPresented: $isImagePickerPresented) {
            PhotoPicker(selectedImage: $selectedImage)
        }
        .background {
            Image("soyleWallpaper")
                .resizable()
                .scaledToFill()
                .frame(height: UIScreen.main.bounds.height + 50)
                .ignoresSafeArea()
        }
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
    
    var body: some View {
        ZStack {
            if isLoading {
                ProgressView("Таңбалар жүктелуде...")
                    .font(.title)
                    .foregroundColor(.white)
                    .background {
                        Image("soyleWallpaper")
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
                NavigationView {
                    VStack {
                        Text("Кейіпкеріңізді таңдаңыз")
                            .font(.largeTitle)
                            .bold()
                            .padding()
                        
                        TabView(selection: $selectedCharacterIndex) {
                            ForEach(characters.indices, id: \.self) { index in
                                CharacterCardView(character: characters[index])
                                    .tag(index)
                            }
                            
                            AddCharacterCardView(characters: $characters)
                                .tag(characters.count)
                        }
                        .tabViewStyle(.page(indexDisplayMode: .always))
                        .frame(height: 500)
                        
                        Spacer()
                        
                        if selectedCharacterIndex < characters.count {
                            let selectedCharacter = characters[selectedCharacterIndex]
                            
                            if selectedCharacter.status == "COMPLETED" {
                                NavigationLink(
                                    destination: VoiceInteractionView(character: selectedCharacter),
                                    isActive: $navigateToVoiceInteraction
                                ) {
                                    Button(action: {
                                        navigateToVoiceInteraction = true
                                    }) {
                                        Text("Растау")
                                            .font(.title2)
                                            .foregroundColor(.white)
                                            .padding()
                                            .frame(maxWidth: .infinity)
                                            .background(
                                                Image("woodBackground")
                                                    .resizable()
                                                    .scaledToFill()
                                            )
                                            .cornerRadius(10)
                                            .padding(.horizontal)
                                    }
                                }
                            } else {
                                Text("Character generation is still in progress.")
                                    .font(.body)
                                    .foregroundColor(.black)
                                    .padding()
                            }
                        } else {
                            
                        }
                    }
                    .background {
                        Image("soyleWallpaper")
                            .resizable()
                            .scaledToFill()
                            .frame(height: UIScreen.main.bounds.height + 50)
                            .ignoresSafeArea()
                    }
                }
            }
        }
        .onAppear {
            fetchCharacters(firstTime: true)
            startAutoRefresh()
        }
        .onDisappear {
            stopAutoRefresh()
        }
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
                    .foregroundColor(.white)
                    .font(.title)
                    .padding(.top, 10)
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
