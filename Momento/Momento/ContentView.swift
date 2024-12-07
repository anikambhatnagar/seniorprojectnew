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
    @Binding var journalEntries: [JournalEntry] // Bind to the journal entries

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
                // Add the selected photo to the journal entries
                let newEntry = JournalEntry(date: Date(), photo: image)
                DispatchQueue.main.async {
                    self.parent.journalEntries.append(newEntry) // Update the state
                }

                // Upload the image to Firebase
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
    @State private var journalEntries: [JournalEntry] = [] // Stores journal entries
    @State private var monthlyRecapEntries: [JournalEntry] = []

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var currentMonthEntries: [JournalEntry] {
            let calendar = Calendar.current
            let currentMonth = calendar.component(.month, from: Date())
            let currentYear = calendar.component(.year, from: Date())

            return journalEntries.filter { entry in
                let entryMonth = calendar.component(.month, from: entry.date)
                let entryYear = calendar.component(.year, from: entry.date)
                return entryMonth == currentMonth && entryYear == currentYear
            }
        }


    var body: some View {
        VStack {
            Spacer(minLength: 60)

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
                // Capture new photo button
                Button(action: {
                    showCamera = true
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

                // Upload photo from library button
                Button(action: {
                    showPhotoLibrary = true
                }) {
                    Text("Upload from Photo Library")
                        .font(.custom("Times New Roman", size: 18))
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 250)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(20)
                }

                // Journal archive button
                Button(action: {
                    showJournalArchive.toggle()
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

                // Monthly recap button
                Button(action: {
                    showMonthlyRecap.toggle()
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
            .padding(.bottom, 50)

            // Show Journal Archive
            if showJournalArchive {
                if journalEntries.isEmpty {
                    EmptyJournalArchiveView()
                } else {
                    JournalEntriesView(entries: journalEntries)
                }
            }

            // Show Monthly Recap
            if showMonthlyRecap {
                if currentMonthEntries.isEmpty {
                    EmptyMonthlyRecapView()
                } else {
                    MonthlyRecapView(entries: currentMonthEntries)
                }
            }

        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .sheet(isPresented: $showPhotoLibrary) {
            PhotoPickerView(
                isPresented: $showPhotoLibrary,
                sourceType: .photoLibrary,
                journalEntries: $journalEntries
            )
        }
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

struct JournalArchiveView: View {
    var entries: [JournalEntry]

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ScrollView {
            VStack {
                Text("Journal Archive")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding()

                if entries.isEmpty {
                    EmptyJournalArchiveView()
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
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
            }
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
}



struct MonthlyRecapView: View {
    var entries: [JournalEntry] // Pass the filtered journal entries for the month

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text("Your Monthly Recap")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding()

                LazyVGrid(columns: columns, spacing: 16) {
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
