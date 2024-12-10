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
import Charts
import Foundation

struct JournalEntry: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    let photo: UIImage
}

struct Weather: Codable {
    let current_weather: CurrentWeather
}

struct CurrentWeather: Codable {
    let temperature: Double
    let weathercode: Int
}

class WeatherFetcher: ObservableObject {
    @Published var temperature: String = ""
    @Published var condition: String = ""
    
    let latitude: Double = 33.9960
    let longitude: Double = -118.39306
    
    func fetchWeather() {
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(latitude)&longitude=\(longitude)&current_weather=true"
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        
        // Debugging: Print the URL
        print("Requesting weather data from: \(urlString)")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching weather data: \(error)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                print("HTTP error: \(httpResponse.statusCode)")
                return
            }
            
            guard let data = data else {
                print("No data received")
                return
            }
            
            if let rawResponse = String(data: data, encoding: .utf8) {
                print("Raw Response: \(rawResponse)")
            }
            
            do {
                let weatherResponse = try JSONDecoder().decode(Weather.self, from: data)
                DispatchQueue.main.async {
                    self.temperature = String(format: "%.0f", weatherResponse.current_weather.temperature)
                    self.condition = self.getWeatherCondition(fromCode: weatherResponse.current_weather.weathercode)
                    print("Fetched weather: \(self.temperature)°C, \(self.condition)")
                }
            } catch {
                print("Error decoding weather data: \(error)")
            }
        }.resume()
    }
    
    func getWeatherCondition(fromCode code: Int) -> String {
        switch code {
        case 0: return "Clear"
        case 1, 2, 3: return "Partly Cloudy"
        case 45, 48: return "Fog"
        case 51...53: return "Light Rain"
        case 61...63: return "Moderate Rain"
        case 71...73: return "Heavy Rain"
        case 80, 81: return "Showers"
        case 95, 96: return "Thunderstorm"
        case 99: return "Severe Thunderstorm"
        default: return "Unknown"
        }
    }
    
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
    @State private var moodRating: Double = 0.0
    @State private var showHomePage = false
    @State private var showCamera = false
    @State private var journalEntries: [JournalEntry] = [] // Shared state for journal entries

    var body: some View {
        if showCamera {
            CameraView(isPresented: $showCamera)
        } else if showHomePage {
            HomePageView(showCamera: $showCamera, journalEntries: $journalEntries)
        } else {
            MoodCheckInView(moodRating: $moodRating, onComplete: {
                saveMoodRating()
                withAnimation {
                    showHomePage = true
                }
            })
        }
    }

    func saveMoodRating() {
        let defaults = UserDefaults.standard
        let today = Calendar.current.startOfDay(for: Date())

        // Retrieve existing mood data
        var moodData = defaults.object(forKey: "moodData") as? [[String: Any]] ?? []

        // Check if there's already an entry for today
        if let index = moodData.firstIndex(where: { ($0["date"] as? Date) == today }) {
            moodData[index]["rating"] = moodRating // Update today's mood rating
        } else {
            // Add a new entry for today
            moodData.append(["date": today, "rating": moodRating])
        }

        // Save the updated mood data
        defaults.set(moodData, forKey: "moodData")
    }

}



struct MoodGraphView: View {
    var data: [(date: Date, rating: Double)]

    var averageMood: Double {
        let totalMood = data.reduce(0) { $0 + $1.rating }
        return totalMood / Double(data.count)
    }

    var body: some View {
        VStack {
            // Display average mood rating
            Text("Average Mood Rating: \(String(format: "%.1f", averageMood))")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.top, 10)

            // Chart for mood data
            Chart {
                ForEach(data, id: \.date) { entry in
                    LineMark(
                        x: .value("Date", entry.date, unit: .day),
                        y: .value("Mood", entry.rating)
                    )
                    .interpolationMethod(.monotone)
                }

                ForEach(data, id: \.date) { entry in
                    PointMark(
                        x: .value("Date", entry.date, unit: .day),
                        y: .value("Mood", entry.rating)
                    )
                    .foregroundStyle(Color.red)
                    .symbolSize(30)
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 5)) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                }
            }
            .chartYAxis {
                AxisMarks(values: [1, 2, 3, 4, 5]) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        Text("\(Int(value.as(Double.self) ?? 0))") // Convert to Int for display
                    }
                }
            }
            .chartYAxisLabel {
                Text("Mood Rating")
                    .foregroundColor(.white)
            }
            .chartLegend(.automatic)
            .foregroundColor(.white)
            .background(Color.gray.opacity(0.3).cornerRadius(10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.blue, lineWidth: 2)
            )
            .padding()
        }
    }
}




struct HomePageView: View {
    @Binding var showCamera: Bool
    @Binding var journalEntries: [JournalEntry]
    @State private var showPhotoLibrary = false
    
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
    
    var pastMonthMoodData: [(date: Date, rating: Double)] {
            let defaults = UserDefaults.standard
            let moodData = defaults.object(forKey: "moodData") as? [[String: Any]] ?? []

            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: today)!

            return moodData.compactMap { entry in
                guard let date = entry["date"] as? Date,
                      let rating = entry["rating"] as? Double,
                      date >= thirtyDaysAgo else { return nil }
                return (date: date, rating: rating)
            }
            .sorted { $0.date < $1.date }
        }

    var body: some View {
        
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                VStack {
                    
                    Spacer(minLength: 60)
                    
                    Image("LOGO")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .padding(.top, 20)
                    
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
                    
                    MoodGraphView(data: pastMonthMoodData)
                                        .frame(height: 200)
                                        .padding()

                    Spacer()
                    
                    VStack(spacing: 20) {
                        Button(action: {
                            showCamera = true
                        }) {
                            Text("Capture new Journal Entry!")
                                .font(.custom("Times New Roman", size: 17))
                                .fontWeight(.medium)
                                .foregroundColor(.black)
                                .padding()
                                .frame(width: 250)
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(20)
                        }
                        
                        Button(action: {
                            showPhotoLibrary = true
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
                        
                        NavigationLink(destination: JournalArchiveView(entries: journalEntries)) {
                            Text("Your Journal Archive")
                                .font(.custom("Times New Roman", size: 18))
                                .fontWeight(.medium)
                                .foregroundColor(.black)
                                .padding()
                                .frame(width: 250)
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(20)
                        }
                        
                        NavigationLink(destination: MonthlyRecapView(entries: currentMonthEntries)) {
                            Text("Your Monthly Recap")
                                .font(.custom("Times New Roman", size: 18))
                                .fontWeight(.medium)
                                .foregroundColor(.black)
                                .padding()
                                .frame(width: 250)
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(20)
                        }
                    }
                    .padding(.bottom, 50)
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

struct JournalSlideshowView: View {
    var journals: [String] // Array of journal entries (could be titles, content, or full objects)

    @State private var selectedIndex = 0

    var body: some View {
        VStack {
            TabView(selection: $selectedIndex) {
                ForEach(0..<journals.count, id: \.self) { index in
                    Text(journals[index])
                        .font(.body)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
            .padding()

            Text("Journal \(selectedIndex + 1) of \(journals.count)")
                .font(.headline)
                .padding()
        }
        .navigationTitle("Journal Slideshow")
        .background(Color.white)
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

struct JournalArchiveView: View {
    var entries: [JournalEntry]

    var body: some View {
        ZStack {
                    Color.black.edgesIgnoringSafeArea(.all)
            ScrollView {
                VStack {
                    Text("Journal Archive")
                        .font(.title)
                        .foregroundColor(.white)
                        .padding()
                    
                    if entries.isEmpty {
                        EmptyJournalArchiveView()
                    } else {
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
                }
            }
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
                    .background(Color.gray.opacity(0.4))
                    .cornerRadius(20)
            }
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
}




struct MonthlyRecapView: View {
    var entries: [JournalEntry] // Pass all journal entries

    // Group journal entries by month and year
    var groupedEntries: [String: [JournalEntry]] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy" // Example: "December 2024"
        
        let grouped = Dictionary(grouping: entries) { entry -> String in
            let dateComponents = calendar.dateComponents([.year, .month], from: entry.date)
            let date = calendar.date(from: dateComponents) ?? Date()
            return formatter.string(from: date)
        }
        
        return grouped
    }

    // Sorted keys for the sections
    var sortedMonths: [String] {
        groupedEntries.keys.sorted { lhs, rhs in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            guard let lhsDate = formatter.date(from: lhs), let rhsDate = formatter.date(from: rhs) else {
                return false
            }
            return lhsDate > rhsDate // Sort in descending order
        }
    }

    var body: some View {
        ZStack {
                    Color.black.edgesIgnoringSafeArea(.all)
            ScrollView {
                VStack(alignment: .leading) {
                    Text("Monthly Recap")
                        .font(.title)
                        .foregroundColor(.white)
                        .padding()
                    
                    ForEach(sortedMonths, id: \.self) { month in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(month) // Month and year as section title
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                                .padding(.top, 10)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 16) {
                                ForEach(groupedEntries[month] ?? [], id: \.id) { entry in
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
                            .padding(.horizontal)
                        }
                    }
                }
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
    
    @ObservedObject var weatherFetcher = WeatherFetcher()  // Add the WeatherFetcher to get weather data
    
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
                
                // Mood slider
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
            
            // Weather Information Display
            if !weatherFetcher.temperature.isEmpty {
                VStack {
                    Text("Current Temperature: \(weatherFetcher.temperature)°C")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    Text("Weather Condition: \(weatherFetcher.condition)")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.top, 5)
                }
            } else {
                Text("Loading weather...")
                    .foregroundColor(.white)
                    .padding(.top, 20)
            }
            
            Spacer()
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .onAppear {
            weatherFetcher.fetchWeather()  // Fetch the weather when the view appears
        }
    }
}

#Preview {
    ContentView()
}
