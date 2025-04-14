//
//  QuoteViewModel.swift
//  Momento
//
//  Created by Anika Bhatnagar on 4/14/25.
//
import Foundation

class QuoteViewModel: ObservableObject {
    @Published var currentQuote: String = "Be yourself; everyone else is already taken."

    private let quotes = [
        "Be yourself; everyone else is already taken.",
        "You are enough just as you are.",
        "Do something today your future self will thank you for.",
        "Breathe. You’re doing better than you think.",
        "It’s a good day to have a good day.",
        "Feel the feelings, then let them go.",
        "Inhale confidence. Exhale doubt."
    ]

    func fetchNewQuote() {
        if let newQuote = quotes.randomElement() {
            currentQuote = newQuote
        }
    }
}

