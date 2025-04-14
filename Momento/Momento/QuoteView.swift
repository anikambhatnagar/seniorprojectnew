//
//  QuoteView.swift
//  Momento
//
//  Created by Anika Bhatnagar on 4/14/25.
//

import Foundation
import SwiftUI

struct QuoteView: View {
    @ObservedObject var viewModel: QuoteViewModel
    @State private var showShareSheet = false

    var body: some View {
        VStack(spacing: 12) {
            Text("✨ Daily Quote")
                .font(.headline)
                .foregroundColor(.white)

            Text(viewModel.currentQuote)
                .font(.body)
                .foregroundColor(.white)
                .italic()
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            HStack(spacing: 20) {
                Button(action: {
                    viewModel.fetchNewQuote()
                }) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                        .foregroundColor(.blue)
                }

                Button(action: {
                    showShareSheet = true
                }) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
        .sheet(isPresented: $showShareSheet) {
            ActivityView(activityItems: [viewModel.currentQuote])
        }
    }
}

// UIKit wrapper for Share Sheet
struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

