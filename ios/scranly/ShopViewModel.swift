import Foundation
import SwiftUI

struct SREstimatePriceDTO: Decodable {
    let pricePerPack: Double
    let packAmount: Double
    let packUnit: String       // "count" | "grams" | "milliliters"
    let sizeLabel: String

    private enum CodingKeys: String, CodingKey {
        case pricePerPack = "price_per_pack"
        case packAmount   = "pack_amount"
        case packUnit     = "pack_unit"
        case sizeLabel    = "size_label"
    }
}

struct BasketItemDTO: Decodable {
    let name: String
    let aisle: String
    let emoji: String
    let needAmount: Double
    let needUnit: String
    let estimate: SREstimatePriceDTO

    private enum CodingKeys: String, CodingKey {
        case name, aisle, emoji
        case needAmount = "need_amount"
        case needUnit   = "need_unit"
        case estimate
    }
}


@MainActor
final class ShopViewModel: ObservableObject {
    @Published var items: [SRItem] = []
    @Published var estimatedTotal: Double = 0
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let api = APIClient()

    private func unitFrom(_ s: String) -> SRUnit {
        switch s.lowercased() {
        case "grams":        return .grams
        case "milliliters":  return .milliliters
        default:             return .count
        }
    }

    func load(userId: String, weekStart: String? = nil) async {
        guard !isLoading else { return }
        isLoading = true; errorMessage = nil
        defer { isLoading = false }

        do {
            let basket = try await api.fetchBasket(userId: userId, weekStart: weekStart)
            #if DEBUG
            print("🧺 basket.items=\(basket.items.count)  est_total=£\(basket.estimatedTotal)")
            #endif
            self.estimatedTotal = basket.estimatedTotal
            self.items = basket.items.map { it in
                SRItem(
                    name: it.name,
                    aisle: it.aisle,
                    needAmount: it.needAmount,
                    needUnit: unitFrom(it.needUnit),
                    estimate: SREstimatePrice(
                        pricePerPack: it.estimate.pricePerPack,
                        packAmount: it.estimate.packAmount,
                        packUnit: unitFrom(it.estimate.packUnit),
                        sizeLabel: it.estimate.sizeLabel
                    ),
                    emoji: it.emoji,
                    isChecked: false
                )
            }
        } catch {
            #if DEBUG
            print("❌ ShopViewModel.load error:", error)
            #endif
            errorMessage = (error as NSError).localizedDescription
        }
    }
}
