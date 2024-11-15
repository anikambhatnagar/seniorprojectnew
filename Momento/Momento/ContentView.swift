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

struct JournalEntry: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    let photo: UIImage
}

enum ImageSource {
    case camera
    case photoLibrary
}

struct PhotoPickerView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    var sourceType: ImageSource

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = (sourceType == .camera) ? .camera : .photoLibrary
        picker.allowsEditing = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: PhotoPickerView

        init(parent: PhotoPickerView) {
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
    @State private var showPhotoLibrary = false
    @State private var showJournalArchive = false
    @State private var showMonthlyRecap = false
    @State private var journalEntries: [JournalEntry] = []
    @State private var monthlyRecapEntries: [JournalEntry] = []
    
    // Define columns as a property of the view
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack {
            Spacer(minLength: 60)

            Image("LOGO")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .padding(.top, 20)
            // Title Text
            Text("Welcome to Momento")
                .font(.custom("Times New Roman", size: 28))
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.bottom, 10)
            
            Text("Capture your moments, moods, and memories with ease.")
                .font(.custom("Times New Roman", size: 16))
                .foregroundColor(.white)
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
                        .foregroundColor(.black)
                        .padding()
                        .frame(width: 250)
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(20)
                }
                
                Button(action: {
                                    showPhotoLibrary = true  // Toggle photo library picker
                                }) {
                                    Text("Upload from Photo Library")
                                        .font(.custom("Times New Roman", size: 18))
                                        .fontWeight(.medium)
                                        .foregroundColor(.black)
                                        .padding()
                                        .frame(width: 250)
                                        .background(Color.white.opacity(0.8))
                                        .cornerRadius(20)
                                }

                Button(action: {
                    // If journal entries are empty, hide monthly recap view
                    if journalEntries.isEmpty {
                        showMonthlyRecap = false
                    }
                    showJournalArchive.toggle()  // Toggle to show Journal Archive
                }) {
                    Text("Your Journal Archive")
                        .font(.custom("Times New Roman", size: 18))
                        .fontWeight(.medium)
                        .foregroundColor(.black)
                        .padding()
                        .frame(width: 250)
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(20)
                }

                Button(action: {
                    // If monthly recap entries are empty, hide journal archive view
                    if monthlyRecapEntries.isEmpty {
                        showJournalArchive = false
                    }
                    showMonthlyRecap.toggle()  // Toggle to show Monthly Recap
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
                
                if showJournalArchive {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(journalEntries) { entry in
                                VStack {
                                    Image(uiImage: entry.photo)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipped()
                                        .cornerRadius(10)
                                    
                                    // Format and show date
                                    Text(entry.date, style: .date)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .padding(.bottom, 50)  // Space below buttons
            
            
            // Show Journal Archive screen or placeholder
            if showJournalArchive {
                if journalEntries.isEmpty {
                    // Empty Placeholder for Journal Archive
                    EmptyJournalArchiveView()
                } else {
                    // Display actual journal entries here (you can use a list, for example)
                    // ACTUAL DISPLAY OF JOURNAL ENTRIES HERE
                    JournalEntriesView(entries: journalEntries)
                }
            }

            // Show Monthly Recap screen or placeholder
            if showMonthlyRecap {
                if monthlyRecapEntries.isEmpty {
                    // Empty Placeholder for Monthly Recap
                    EmptyMonthlyRecapView()
                } else {
                    // Display actual monthly recap entries here
//      ACTUAL FIREBASE STORAGE OF ENTRIES HERE              MonthlyRecapView(entries: monthlyRecapEntries)
                }
            }
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
}

struct EmptyMonthlyRecapView: View {
    var body: some View {
        VStack {
            Spacer()
            Text("No monthly recap entries found.")
                .font(.title)
                .foregroundColor(.white)
                .padding()
            
            Spacer()
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
}


struct EmptyJournalArchiveView: View {
    var body: some View {
        VStack {
            Spacer()
            Text("No journal entries found.")
                .font(.title)
                .foregroundColor(.white)
                .padding()
            
            Spacer()
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
}

struct JournalEntriesView: View {
    var entries: [JournalEntry]
    
    var body: some View {
        VStack {
            Text("Your Journal Entries")
                .font(.title)
                .foregroundColor(.white)
                .padding()
            
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(entries) { entry in
                        VStack {
                            Image(uiImage: entry.photo)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipped()
                                .cornerRadius(10)
                            
                            Text(entry.date, style: .date)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
            }

            Button(action: {
                // Go back to the home page
            }) {
                Text("Go Back")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(20)
            }
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
    
    let range: [Double] = Array(1...5).map { Double($0) }  // Array of values from 1 to 5
    
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
                
                // Slider with custom labels
                VStack {
                    
                    Slider(value: $moodRating, in: 1...5, step: 1, onEditingChanged: { editing in
                        if !editing {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                onComplete()
                            }
                        }
                    })
                    .padding(.horizontal, 25)
                    
                    // Custom tick marks
                    HStack {
                        ForEach(range, id: \.self) { value in
                            Text("\(Int(value))")
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.top, -10)  // Adjust positioning of the labels to be closer to the slider
                }
                .padding(.bottom, 30)
            }
            
            Spacer()
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
}

#Preview {
    ContentView()
}
