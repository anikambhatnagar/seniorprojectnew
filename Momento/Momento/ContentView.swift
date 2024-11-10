//
//  ContentView.swift
//  Momento app
//
//  Created by Dev Raiyani on 24/10/24.
//
import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseCore

struct ContentView: View {
    @State private var moodRating: Double = 0.0  // Start slider at 0
    @State private var showHomePage = false      // Flag to control navigation
    @State private var showCamera = false        // Flag to control camera view

    var body: some View {
        if showCamera {
            CameraView(isPresented: $showCamera)
        } else if showHomePage {
            HomePageView(showCamera: $showCamera)
        } else {
            MoodCheckInView(moodRating: $moodRating, onComplete: {
                saveMoodRating()
                withAnimation {
                    showHomePage = true  // Automatically show home page after slider interaction
                }
            })
        }
    }

    // Function to save the mood rating
    func saveMoodRating() {
        let defaults = UserDefaults.standard
        defaults.set(Date(), forKey: "lastMoodRatingDate")
        defaults.set(moodRating, forKey: "moodRating")  // Save the rating
    }
}

// Home page after mood check-in
struct HomePageView: View {
    @Binding var showCamera: Bool

    var body: some View {
        VStack {
            Spacer(minLength: 60)

            // Title Text
            Text("Welcome to Momento")
                .font(.custom("Times New Roman", size: 28))
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.bottom, 10)
            
            Text("Capture your moments, moods, and memories with ease.")
                .font(.custom("Times New Roman", size: 16))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 30)

            Spacer()

            VStack(spacing: 20) {
                Button(action: {
                    showCamera = true  // Show camera view
                }) {
                    Text("Capture a new Journal Entry!")
                        .font(.custom("Times New Roman", size: 18))
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 250)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(20)
                }

                Button(action: {
                    // Add action for viewing journal archive
                }) {
                    Text("Your Journal Archive")
                        .font(.custom("Times New Roman", size: 18))
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 250)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(20)
                }

                Button(action: {
                    // Add action for viewing monthly recap
                }) {
                    Text("Your Monthly Recap")
                        .font(.custom("Times New Roman", size: 18))
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 250)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(20)
                }
            }
            .padding(.bottom, 50)  // Space below buttons
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
}

// Camera view to capture the photo
struct CameraView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.allowsEditing = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraView

        init(parent: CameraView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.editedImage] as? UIImage {
                uploadImageToFirebase(image: image)
            }
            parent.isPresented = false
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }

        func uploadImageToFirebase(image: UIImage) {
            guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
            let storageRef = Storage.storage().reference().child("journalEntries/\(UUID().uuidString).jpg")
            
            storageRef.putData(imageData, metadata: nil) { metadata, error in
                if let error = error {
                    print("Failed to upload image: \(error.localizedDescription)")
                    return
                }
                print("Image uploaded successfully.")
            }
        }
    }
}

struct MoodCheckInView: View {
    @Binding var moodRating: Double
    var onComplete: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            
            Text("How are you feeling today?")
                .font(.title)
                .foregroundColor(.white)
                .padding(.bottom, 20)

            VStack {
                Text("Rate your mood:")
                    .foregroundColor(.gray)
                Slider(value: $moodRating, in: 0...10, step: 1, onEditingChanged: { editing in
                    if !editing {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            onComplete()
                        }
                    }
                })
                .padding(.horizontal, 40)
            }
            .padding(.bottom, 30)
            
            Spacer()
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
}

#Preview {
    ContentView()
}
