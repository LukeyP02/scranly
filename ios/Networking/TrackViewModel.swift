//// TrackViewModel.swift
//import Foundation
//
//@MainActor
//final class TrackViewModel: ObservableObject {
//    @Published var entries: [IntakeEntry] = []
//    @Published var isLoading = false
//    @Published var error: String?
//
//    private let api = APIClient.shared
//    private let userId: String
//
//    init(userId: String) { self.userId = userId }
//
//    func load(days: Int = 7) async {
//        guard !isLoading else { return }
//        isLoading = true; error = nil
//        defer { isLoading = false }
//
//        do {
//            let dtos = try await api.fetchTrack(userId: userId, days: days)
//
//            let df = DateFormatter()
//            df.calendar = .iso8601
//            df.locale = Locale(identifier: "en_US_POSIX")
//            df.timeZone = .utc
//            df.dateFormat = "yyyy-MM-dd"
//
//            entries = dtos.compactMap { dto in
//                guard let d = df.date(from: dto.date) else { return nil }
//                return IntakeEntry(
//                    date: d,
//                    name: "Logged",                 // server has no 'name'
//                    proteinG: dto.protein,
//                    carbsG: dto.carbs,
//                    fatG: dto.fats
//                )
//            }.sorted { $0.date < $1.date }
//
//            #if DEBUG
//            print("📈 fetched \(entries.count) days")
//            #endif
//        } catch {
//            self.error = error.localizedDescription
//            #if DEBUG
//            print("❌ TrackViewModel.load error:", error)
//            #endif
//        }
//    }
//
//    /// Add/Upsert a day (defaults to today)
//    func add(name: String, protein: Double, carbs: Double, fat: Double, dateISO: String? = nil) async {
//        let df = DateFormatter()
//        df.calendar = .iso8601
//        df.locale = Locale(identifier: "en_US_POSIX")
//        df.timeZone = .utc
//        df.dateFormat = "yyyy-MM-dd"
//
//        let iso = dateISO ?? df.string(from: Date())
//        let calories = protein*4 + carbs*4 + fat*9
//
//        let body = AddTrackRequest(
//            user_id: userId,
//            date: iso,
//            calories: calories,
//            protein: protein,
//            carbs: carbs,
//            fats: fat
//        )
//
//        do {
//            let saved = try await api.addTrack(body)
//            let d = df.date(from: saved.date) ?? Date()
//            let newEntry = IntakeEntry(
//                date: d,
//                name: name.isEmpty ? "Logged" : name,
//                proteinG: saved.protein,
//                carbsG: saved.carbs,
//                fatG: saved.fats
//            )
//
//            // de-dupe by day (API is one row per user/date)
//            let cal = Calendar.iso8601
//            if let idx = entries.firstIndex(where: { cal.isDate($0.date, inSameDayAs: d) }) {
//                entries[idx] = newEntry
//            } else {
//                entries.append(newEntry)
//                entries.sort { $0.date < $1.date }
//            }
//
//            #if DEBUG
//            print("➕ upserted \(iso): \(Int(calories)) kcal")
//            #endif
//        } catch {
//            self.error = error.localizedDescription
//            #if DEBUG
//            print("❌ addTrack error:", error)
//            #endif
//        }
//    }
//}
//
//private extension Calendar { static let iso8601 = Calendar(identifier: .iso8601) }
