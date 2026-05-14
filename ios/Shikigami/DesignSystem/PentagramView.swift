import SwiftUI

// 五芒星（ペンタグラム）描画ビュー
// 外側5頂点と内側5頂点を交互に結ぶ
struct PentagramView: View {
    var size: CGFloat = 120
    var isSpinning: Bool = false

    var body: some View {
        pentagramShape
            .stroke(Color.oracleGold, lineWidth: 1.5)
            .frame(width: size, height: size)
            .shadow(color: Color.oracleGold.opacity(0.6), radius: 12)
            .if(isSpinning) { $0.spinSlow() }
    }

    private var pentagramShape: Path {
        let center = CGPoint(x: size / 2, y: size / 2)
        let outerRadius = size / 2
        let innerRadius = outerRadius * 0.382

        var path = Path()
        var points: [CGPoint] = []

        for i in 0..<10 {
            let angle = Double(i) * .pi / 5 - .pi / 2
            let radius = i.isMultiple(of: 2) ? outerRadius : innerRadius
            points.append(CGPoint(
                x: center.x + CGFloat(cos(angle)) * radius,
                y: center.y + CGFloat(sin(angle)) * radius
            ))
        }

        path.move(to: points[0])
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        path.closeSubpath()
        return path
    }
}

extension View {
    @ViewBuilder
    fileprivate func `if`(_ condition: Bool, transform: (Self) -> some View) -> some View {
        if condition { transform(self) } else { self }
    }
}
