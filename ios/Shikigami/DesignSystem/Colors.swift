import SwiftUI

extension Color {
    static let voidBlack  = Color(hex: "#0A0A0F")
    static let oracleGold = Color(hex: "#D4A843")
    static let jadeGreen  = Color(hex: "#2D7D5E")
    static let fujiPurple = Color(hex: "#6B4E8C")
    static let crimsonRed = Color(hex: "#C42B3A")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .init(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8)  & 0xFF) / 255
        let b = Double(rgb         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
