// Views/SectionInfoModalView.swift

import SwiftUI

struct SectionInfoModalView: View {
    @ObservedObject var section: Section
    @Binding var isPresented: Bool

    @State private var isShareSheetPresented = false

    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation {
                        isPresented = false
                    }
                }

            // Modal content
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 4) {
                    // Ward and Section Title
                    Text("Ward \(section.ward), Section \(section.sectionNumber)")
                        .font(.custom("Quicksand-Bold", size: 18))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                }
                
                // Display Hood
                Text(section.hood)
                    .font(.custom("Quicksand-Regular", size: 14))
                    .lineSpacing(5)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
                    .padding(.bottom, 16)

                Divider()
                    .padding(.horizontal)
                    .padding(.bottom, 24) // Added spacing after the divider

                let nextDates = section.nextCleaningDates()

                if nextDates.isEmpty {
                    Text("No more cleaning dates! Make sure your app is up to date if we are in the cleaning season (April-November). Schedules are updated every March!")
                        .font(.custom("Quicksand-Medium", size: 13))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .lineSpacing(8)
                } else {

                    VStack(alignment: .center, spacing: 8) {
                        ForEach(nextDates, id: \.self) { date in
                            Text(dateString(from: date))
                                .font(.custom("Quicksand-Medium", size: 18))
                                .foregroundColor(color(for: date))
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                    .frame(height: 30) // Added more space before the buttons

                // Buttons
                VStack(spacing: 10) {
                    // OK Button
                    Button(action: {
                        withAnimation {
                            isPresented = false
                        }
                    }) {
                        Text("OK")
                            .font(.custom("Quicksand-Medium", size: 14))
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.customBackground)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)

                    // Share Button
                    Button(action: {
                        isShareSheetPresented = true
                    }) {
                        Text("Share")
                            .font(.custom("Quicksand-Medium", size: 14))
                            .foregroundColor(.customBackground)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 24) // Added spacing at the bottom
            }
            .padding(.top, 20) // Added top padding to the modal content
            .background(Color.white)
            .cornerRadius(20)
            .shadow(radius: 10)
            .padding(.horizontal, 30) // Adjusted horizontal padding for the modal
            .onAppear {
                print("Modal presented for Ward \(section.ward), Section \(section.sectionNumber), Cleaning Dates Count: \(section.cleaningDates.count)")
            }
            // Share Sheet Presentation
            .sheet(isPresented: $isShareSheetPresented) {
                ShareSheet(items: [shareContent()])
            }
        }
    }

    // Helper function to format the date
    private func dateString(from date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full // E.g., "Tuesday, October 3, 2024"
        return dateFormatter.string(from: date)
    }

    // Function to prepare content for sharing
    private func shareContent() -> String {
        var content = ""
        content += "Ward \(section.ward), Section \(section.sectionNumber)\n"
        content += "\(section.hood)\n\n"
        content += "Upcoming Cleaning Dates:\n"
        let nextDates = section.nextCleaningDates()
        if nextDates.isEmpty {
            content += "Unable to get upcoming cleaning dates."
        } else {
            for date in nextDates {
                content += "- \(dateString(from: date))\n"
            }
        }
        return content
    }

    private func color(for date: Date) -> Color {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfDate = calendar.startOfDay(for: date)
        let days = calendar.dateComponents([.day], from: startOfToday, to: startOfDate).day ?? 0

        if days >= 0 && days <= 3 {
            return .red
        } else if days >= 4 && days <= 7 {
            return .orange
        } else if days == -1 {
            return .red
        } else if days == -2 {
            return .orange
        }
        return .black
    }
}
