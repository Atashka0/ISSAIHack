import SwiftUI
import SDWebImageSwiftUI
import PhotosUI

struct Character: Identifiable {
    let id: Int
    let name: String
    let videoURL: String
    let voice: String
}

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

    @State private var name: String = ""
    @State private var description: String = ""
    @State private var isImagePickerPresented = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            // Background color or image
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Title
                Text("Add New Character")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)

                // Character Image Section
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

                // Input Fields
                VStack(spacing: 15) {
                    // Name Input
                    TextField("Атын енгізіңіз", text: $name)
                        .padding()
                        .frame(height: 60) // Adjust height for a bigger input
                        .background(Color.white) // Add a background color for clarity
                        .cornerRadius(10) // Rounded corners
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black, lineWidth: 2) // Black border
                        )
                        .padding(.horizontal)

                    // Description Input
                    TextField("Қысқаша сипаттама қосыңыз", text: $description)
                        .padding()
                        .frame(height: 60) // Adjust height for a bigger input
                        .background(Color.white) // Add a background color for clarity
                        .cornerRadius(10) // Rounded corners
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black, lineWidth: 2) // Black border
                        )
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
        guard let image = selectedImage else { return }
        let newCharacter = Character(
            id: characters.count + 1,
            name: name,
            videoURL: "data:image/png;base64,\(image.toBase64String())",
            voice: description
        )
        characters.append(newCharacter)
    }
}

struct CharacterSelectionView: View {
    @State private var selectedCharacterIndex: Int = 0
    @State private var navigateToVoiceInteraction = false

    @State private var characters: [Character] = [
        Character(id: 141, name: "Томирис", videoURL: "https://resource2.heygen.ai/video/gifs/82c311f7b05d467a9df1c2bd66531b40.gif", voice: "Female"),
        Character(id: 142, name: "Ер Төстік", videoURL: "https://resource2.heygen.ai/video/gifs/82c311f7b05d467a9df1c2bd66531b40.gif", voice: "Male"),
        Character(id: 143, name: "Бәйтерек", videoURL: "https://resource2.heygen.ai/video/gifs/82c311f7b05d467a9df1c2bd66531b40.gif", voice: "Female")
    ]

    var body: some View {
        ZStack {
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
                    
                    // Confirm Button
                    if selectedCharacterIndex < characters.count {
                        NavigationLink(
                            destination: VoiceInteractionView(character: characters[selectedCharacterIndex]),
                            isActive: $navigateToVoiceInteraction
                        ) {
                            Button(action: {
                                navigateToVoiceInteraction = true
                            }) {
                                Text("Confirm")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.black)
                                    .cornerRadius(10)
                                    .padding(.horizontal)
                            }
                        }
                    } else {
                        Text("Please select a valid character.")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
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
}

struct CharacterCardView: View {
    let character: Character

    var body: some View {
        VStack {
            AnimatedImage(url: URL(string: character.videoURL))
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
