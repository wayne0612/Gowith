import SwiftUI

struct Gowith3DIconOption: Identifiable {
    let id: String
    let title: String
    let symbol: String
    let top: Color
    let bottom: Color
    let side: Color

    static let all: [Gowith3DIconOption] = [
        .init(id: "gowith3d.backpack", title: "登山包", symbol: "backpack.fill", top: Color(red: 0.25, green: 0.77, blue: 0.65), bottom: Color(red: 0.07, green: 0.48, blue: 0.42), side: Color(red: 0.04, green: 0.31, blue: 0.29)),
        .init(id: "gowith3d.suitcase", title: "行李箱", symbol: "suitcase.rolling.fill", top: Color(red: 0.98, green: 0.68, blue: 0.32), bottom: Color(red: 0.92, green: 0.39, blue: 0.18), side: Color(red: 0.63, green: 0.22, blue: 0.12)),
        .init(id: "gowith3d.home", title: "房屋", symbol: "house.fill", top: Color(red: 0.48, green: 0.72, blue: 0.98), bottom: Color(red: 0.22, green: 0.46, blue: 0.83), side: Color(red: 0.13, green: 0.30, blue: 0.58)),
        .init(id: "gowith3d.keys", title: "钥匙", symbol: "key.fill", top: Color(red: 0.98, green: 0.83, blue: 0.35), bottom: Color(red: 0.88, green: 0.56, blue: 0.10), side: Color(red: 0.59, green: 0.34, blue: 0.04)),
        .init(id: "gowith3d.camera", title: "相机", symbol: "camera.fill", top: Color(red: 0.72, green: 0.63, blue: 0.98), bottom: Color(red: 0.43, green: 0.34, blue: 0.83), side: Color(red: 0.27, green: 0.20, blue: 0.55)),
        .init(id: "gowith3d.lens", title: "镜头", symbol: "camera.macro", top: Color(red: 0.42, green: 0.82, blue: 0.91), bottom: Color(red: 0.15, green: 0.52, blue: 0.71), side: Color(red: 0.08, green: 0.33, blue: 0.48)),
        .init(id: "gowith3d.laptop", title: "电脑", symbol: "laptopcomputer", top: Color(red: 0.75, green: 0.79, blue: 0.84), bottom: Color(red: 0.43, green: 0.49, blue: 0.57), side: Color(red: 0.25, green: 0.29, blue: 0.35)),
        .init(id: "gowith3d.headphones", title: "耳机", symbol: "headphones", top: Color(red: 0.98, green: 0.55, blue: 0.62), bottom: Color(red: 0.84, green: 0.27, blue: 0.42), side: Color(red: 0.55, green: 0.13, blue: 0.26))
    ]

    static func option(for id: String) -> Gowith3DIconOption? {
        all.first(where: { $0.id == id })
    }
}

struct Gowith3DIcon: View {
    let option: Gowith3DIconOption
    var size: CGFloat = 56

    var body: some View {
        ZStack {
            Ellipse()
                .fill(.black.opacity(0.10))
                .frame(width: size * 0.66, height: size * 0.13)
                .blur(radius: size * 0.035)
                .offset(y: size * 0.35)

            ForEach(0..<5, id: \.self) { layer in
                Image(systemName: option.symbol)
                    .font(.system(size: size * 0.72, weight: .black))
                    .foregroundStyle(option.side)
                    .offset(x: CGFloat(layer) * size * 0.006, y: size * 0.045 + CGFloat(layer) * size * 0.018)
            }

            Image(systemName: option.symbol)
                .font(.system(size: size * 0.72, weight: .black))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(LinearGradient(colors: [option.top, option.bottom], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(alignment: .topLeading) {
                    Image(systemName: option.symbol)
                        .font(.system(size: size * 0.72, weight: .black))
                        .foregroundStyle(.white.opacity(0.14))
                        .offset(x: -size * 0.012, y: -size * 0.012)
                        .mask {
                            LinearGradient(colors: [.white, .clear], startPoint: .topLeading, endPoint: .center)
                        }
                }
                .offset(y: size * 0.035)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
