//
//  QuoteViewModel.swift
//  Momento
//
//  Created by Anika Bhatnagar on 4/14/25.
//
import Foundation

class QuoteViewModel: ObservableObject {
    @Published var currentQuote: String = "Loading quote..."
    @Published var currentAuthor: String = ""

    func fetchNewQuote() {
        guard let url = URL(string: "https://quotes-inspirational-quotes-motivational-quotes.p.rapidapi.com/quote?token=ipworld") else {
            print("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("01a558aaf4msh316a9331a3f64e1p1f255bjsn3a9f102ca513", forHTTPHeaderField: "X-RapidAPI-Key")
        request.setValue("quotes-inspirational-quotes-motivational-quotes.p.rapidapi.com", forHTTPHeaderField: "X-RapidAPI-Host")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("API error: \(error.localizedDescription)")
                return
            }

            guard let data = data else {
                print("No data received")
                return
            }

            do {
                let decoded = try JSONDecoder().decode(RapidQuote.self, from: data)
                DispatchQueue.main.async {
                    self.currentQuote = decoded.text
                    self.currentAuthor = decoded.author
                    print("✅ Quote loaded: \(decoded.text) — \(decoded.author)")
                }
            } catch {
                print("Failed to decode quote: \(error)")
                if let raw = String(data: data, encoding: .utf8) {
                    print("Raw response: \(raw)")
                }
            }

        }.resume()
    }
}

struct RapidQuote: Codable {
    let text: String
    let author: String
}
