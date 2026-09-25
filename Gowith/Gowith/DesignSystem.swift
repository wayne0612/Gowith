import SwiftUI
import UIKit

// MARK: - 模式与页面

/// 运行时双模式：基础（浅色） / 进阶（深色），`@AppStorage("gowith.appMode")` 持久化。
enum AppMode: String {
    case basic
    case advanced
}

enum AppTab: Hashable {
    case library
    case packing
    case check
    case map
    case profile
}

// MARK: - 设计令牌（黑白体系 + 全局唯一强调色，规格 2.1）

enum GowithColor {
    static let appBackground = adaptive(light: (0.949, 0.949, 0.957, 1), dark: (0.063, 0.063, 0.071, 1)) // #F2F2F4 / #101012
    static let surface = adaptive(light: (1, 1, 1, 0.94), dark: (1, 1, 1, 0.05))
    static let surfaceBorder = adaptive(light: (0.925, 0.925, 0.941, 1), dark: (0.149, 0.149, 0.169, 1)) // #ECECF0 / #26262B
    static let ink = adaptive(light: (0.067, 0.067, 0.067, 1), dark: (0.957, 0.957, 0.961, 1)) // #111111 / #F4F4F5
    static let inkSecondary = adaptive(light: (0.443, 0.443, 0.478, 1), dark: (0.545, 0.545, 0.576, 1)) // #71717A / #8B8B93
    static let inkTertiary = adaptive(light: (0.631, 0.631, 0.667, 1), dark: (0.631, 0.631, 0.667, 1)) // #A1A1AA
    static let hairline = adaptive(light: (0.941, 0.941, 0.949, 1), dark: (1, 1, 1, 0.07)) // #F0F0F2 / white 7%
    static let accent = adaptive(light: (1, 0.353, 0.149, 1), dark: (1, 0.353, 0.149, 1)) // #FF5A26
    static let accentSoft = adaptive(light: (1, 0.549, 0.353, 1), dark: (1, 0.549, 0.353, 1)) // #FF8C5A

    // 深色资产卡渐变（规格 4.2 / 5.6）
    static let cardGradientTop = Color(red: 0.149, green: 0.149, blue: 0.169) // #26262B
    static let cardGradientAdvancedTop = Color(red: 0.180, green: 0.180, blue: 0.20) // #2E2E33
    static let cardGradientBottom = Color(red: 0.063, green: 0.063, blue: 0.071) // #101012

    /// 旧令牌别名：保留页（首启设置）与少数复用组件仍以旧名取色，自动跟随新黑白体系。
    static let primary = ink
    static let onPrimary = adaptive(light: (1, 1, 1, 1), dark: (0.067, 0.067, 0.067, 1))
    static let secondary = inkSecondary
    static let tertiary = inkTertiary
    static let border = surfaceBorder
    static let softSurface = adaptive(light: (0.941, 0.941, 0.949, 1), dark: (1, 1, 1, 0.08))
    static let success = accent
    static let heroBackground = Color(red: 0.067, green: 0.067, blue: 0.067)

    private static func adaptive(light: (CGFloat, CGFloat, CGFloat, CGFloat), dark: (CGFloat, CGFloat, CGFloat, CGFloat)) -> Color {
        Color(uiColor: UIColor { traits in
            let values = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: values.0, green: values.1, blue: values.2, alpha: values.3)
        })
    }
}

enum GowithMetrics {
    static let pagePadding: CGFloat = 14
    static let moduleSpacing: CGFloat = 10
    static let contentCardRadius: CGFloat = 18
    static let phoneCardRadius: CGFloat = 20
    static let rowIconSize: CGFloat = 38
    static let rowIconRadius: CGFloat = 12
    static let rowHeight: CGFloat = 56
}

enum GowithMotion {
    /// 胶囊滑块弹性平移（规格 2.4）
    static let capsule = Animation.timingCurve(0.34, 1.4, 0.44, 1, duration: 0.38)
    static let capsuleText = Animation.easeInOut(duration: 0.3)
    /// 装包小球飞行
    static let packBall = Animation.timingCurve(0.3, 0.7, 0.4, 1, duration: 0.55)
    static let badgeBounce = Animation.spring(response: 0.28, dampingFraction: 0.55)
    static let tabSelect = Animation.easeInOut(duration: 0.25)
    static let content = Animation.easeInOut(duration: 0.24)
    static let row = Animation.easeInOut(duration: 0.19)
}

/// 关键时刻的触觉反馈；「我的 → 触感反馈」可关闭（gowith.hapticsEnabled）。
enum GowithHaptics {
    private static var isEnabled: Bool {
        guard UserDefaults.standard.object(forKey: "gowith.hapticsEnabled") != nil else { return true }
        return UserDefaults.standard.bool(forKey: "gowith.hapticsEnabled")
    }

    /// 清单勾选类轻反馈
    static func selection() {
        guard isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }

    /// 到达地点、完成出行等成功节点
    static func success() {
        guard isEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }

    /// 开始出行、模式切换等状态变更
    static func stateChange() {
        guard isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
}

// MARK: - 字体速记（规格 2.2，rounded 设计）

enum GowithFont {
    static let brand = Font.system(size: 19, weight: .heavy, design: .rounded)
    static let assetNumber = Font.system(size: 50, weight: .heavy, design: .rounded)
    static let assetUnit = Font.system(size: 13, weight: .semibold, design: .rounded)
    static let cardKicker = Font.system(size: 9.5, weight: .bold)
    static let rowTitle = Font.system(size: 13, weight: .bold)
    static let rowSubtitle = Font.system(size: 10, weight: .medium)
    static let tabLabel = Font.system(size: 9.5, weight: .bold)
    static let mainButton = Font.system(size: 13, weight: .heavy, design: .rounded)
    static let cta = Font.system(size: 10.5, weight: .medium)
}

// MARK: - 胶囊模式开关（规格 4.1）

struct ModeCapsule: View {
    @Binding var mode: AppMode
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var sliderSpace

    var body: some View {
        HStack(spacing: 4) {
            segment("基础", isSelected: mode == .basic)
                .onTapGesture { select(.basic) }
            segment("进阶", isSelected: mode == .advanced)
                .onTapGesture { select(.advanced) }
        }
        .padding(2)
        .frame(width: 96, height: 30)
        .background(track, in: Capsule())
        .overlay { Capsule().stroke(borderColor, lineWidth: 1).allowsHitTesting(false) }
        .contentShape(Capsule())
        .onTapGesture { select(mode == .basic ? .advanced : .basic) }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("基础与进阶模式切换")
        .accessibilityValue(mode == .basic ? "基础模式" : "进阶模式")
        .accessibilityAddTraits(.isButton)
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: select(.advanced)
            case .decrement: select(.basic)
            @unknown default: break
            }
        }
    }

    private func select(_ target: AppMode) {
        guard target != mode else { return }
        withAnimation(reduceMotion ? nil : GowithMotion.capsule) { mode = target }
        GowithHaptics.selection()
    }

    private func segment(_ title: String, isSelected: Bool) -> some View {
        Text(title)
            .font(.system(size: 12, weight: isSelected ? .bold : .medium, design: .rounded))
            .foregroundStyle(isSelected ? sliderForeground : GowithColor.inkTertiary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                if isSelected {
                    Capsule()
                        .fill(sliderBackground)
                        .matchedGeometryEffect(id: "slider", in: sliderSpace)
                }
            }
            .contentShape(Rectangle())
    }

    private var track: Color {
        scheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.85)
    }
    private var borderColor: Color {
        scheme == .dark ? Color.white.opacity(0.08) : Color(red: 0.894, green: 0.894, blue: 0.906) // #E4E4E7
    }
    /// 进阶（深色）下滑块翻转为白底黑字（规格 5.5），基础为黑色渐变滑块（规格 4.1）。
    private var sliderBackground: some ShapeStyle {
        scheme == .dark
            ? AnyShapeStyle(Color.white)
            : AnyShapeStyle(LinearGradient(colors: [Color(red: 0.165, green: 0.165, blue: 0.18), .black], startPoint: .top, endPoint: .bottom))
    }
    private var sliderForeground: Color {
        scheme == .dark ? .black : .white
    }
}

// MARK: - 固定头部（规格 3）

struct AppHeader: View {
    @Binding var mode: AppMode

    var body: some View {
        HStack(spacing: 12) {
            (Text("Gowith")
                .font(GowithFont.brand)
                .tracking(-0.4)
                .foregroundStyle(GowithColor.ink)
             + Text(".")
                .font(GowithFont.brand)
                .tracking(-0.4)
                .foregroundStyle(GowithColor.accent))
            Spacer(minLength: 8)
            ModeCapsule(mode: $mode)
        }
        .padding(.horizontal, GowithMetrics.pagePadding + 2)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .overlay(alignment: .bottom) { Divider().opacity(0.4) }
    }
}

// MARK: - 资产卡片（规格 4.2）

enum AssetCardTexture {
    case flow      // 物品库
    case rings     // 拿东西
    case crossCircle // 检查
    case none      // 历史深色卡
}

struct AssetCard: View {
    let header: String
    let headerEN: String
    var badge: String? = nil
    var badgeAction: (() -> Void)? = nil
    let leftValue: String
    let leftUnit: String
    let leftLabel: String
    let rightValue: String
    let rightUnit: String
    let rightLabel: String
    var ctaPlain: String? = nil
    var ctaAccent: String? = nil
    var texture: AssetCardTexture = .none
    var isDarkVariant = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Text("\(header) · \(headerEN)")
                    .font(GowithFont.cardKicker)
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.5))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 8)
                if let badge {
                    Button {
                        badgeAction?()
                    } label: {
                        HStack(spacing: 3) {
                            Text(badge)
                                .font(.system(size: 10, weight: .semibold))
                                .lineLimit(1)
                            if badgeAction != nil {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 8, weight: .bold))
                            }
                        }
                        .foregroundStyle(GowithColor.accentSoft)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(badgeAction == nil)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 13)

            HStack(spacing: 0) {
                dataHalf(value: leftValue, unit: leftUnit, label: leftLabel, color: .white)
                VerticalDashedLine()
                    .stroke(.white.opacity(0.28), style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                    .frame(width: 1.5, height: 54)
                dataHalf(value: rightValue, unit: rightUnit, label: rightLabel, color: GowithColor.accent)
            }
            .padding(.top, 6)

            if let ctaPlain, let ctaAccent {
                (Text(ctaPlain) + Text(ctaAccent).fontWeight(.bold).foregroundColor(GowithColor.accent))
                    .font(GowithFont.cta)
                    .foregroundStyle(.white.opacity(0.72))
                    .padding(.top, 10)
                    .padding(.bottom, 12)
            } else {
                // 无操作可说时省略 CTA 层，保持底部间距一致
                Color.clear.frame(height: 12)
            }
        }
        .frame(maxWidth: .infinity)
        .background {
            LinearGradient(
                stops: isDarkVariant
                    ? [Gradient.Stop(color: GowithColor.cardGradientAdvancedTop, location: 0), Gradient.Stop(color: GowithColor.cardGradientBottom, location: 1)]
                    : [Gradient.Stop(color: GowithColor.cardGradientTop, location: 0), Gradient.Stop(color: .black, location: 0.72)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: GowithMetrics.phoneCardRadius, style: .continuous))
        .overlay {
            if isDarkVariant {
                RoundedRectangle(cornerRadius: GowithMetrics.phoneCardRadius, style: .continuous)
                    .stroke(GowithColor.surfaceBorder, lineWidth: 1)
                    .allowsHitTesting(false)
            }
        }
        .overlay { textureOverlay.clipShape(RoundedRectangle(cornerRadius: GowithMetrics.phoneCardRadius, style: .continuous)).allowsHitTesting(false) }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(header)：\(leftValue)\(leftUnit)\(leftLabel)，\(rightValue)\(rightUnit)\(rightLabel)\(badge.map { "，\($0)" } ?? "")")
    }

    private func dataHalf(value: String, unit: String, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(GowithFont.assetNumber)
                    .tracking(-2)
                    .foregroundStyle(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
                Text(unit)
                    .font(GowithFont.assetUnit)
                    .tracking(1)
                    .foregroundStyle(.white.opacity(0.45))
            }
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .tracking(1)
                .foregroundStyle(.white.opacity(0.55))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var textureOverlay: some View {
        if texture != .none {
            Canvas { context, size in
                var path = Path()
                switch texture {
                case .flow:
                    path.move(to: CGPoint(x: -10, y: size.height * 0.82))
                    path.addCurve(to: CGPoint(x: size.width + 10, y: size.height * 0.3),
                                  control1: CGPoint(x: size.width * 0.3, y: size.height * 1.05),
                                  control2: CGPoint(x: size.width * 0.7, y: size.height * 0.05))
                    context.stroke(path, with: .color(.white.opacity(0.14)), lineWidth: 1)
                    var second = Path()
                    second.move(to: CGPoint(x: -10, y: size.height * 0.2))
                    second.addCurve(to: CGPoint(x: size.width + 10, y: size.height * 0.75),
                                    control1: CGPoint(x: size.width * 0.35, y: -size.height * 0.1),
                                    control2: CGPoint(x: size.width * 0.6, y: size.height * 0.95))
                    context.stroke(second, with: .color(.white.opacity(0.1)), lineWidth: 1)
                case .rings:
                    let center = CGPoint(x: size.width * 0.86, y: size.height * 0.42)
                    path.addEllipse(in: CGRect(x: center.x - 78, y: center.y - 78, width: 156, height: 156))
                    context.stroke(path, with: .color(.white.opacity(0.14)), lineWidth: 1)
                    var inner = Path()
                    inner.addEllipse(in: CGRect(x: center.x - 46, y: center.y - 46, width: 92, height: 92))
                    context.stroke(inner, with: .color(.white.opacity(0.1)), lineWidth: 1)
                case .crossCircle:
                    let center = CGPoint(x: size.width * 0.85, y: size.height * 0.44)
                    path.addEllipse(in: CGRect(x: center.x - 40, y: center.y - 40, width: 80, height: 80))
                    context.stroke(path, with: .color(.white.opacity(0.14)), lineWidth: 1)
                    var cross = Path()
                    cross.move(to: CGPoint(x: center.x - 24, y: center.y - 24))
                    cross.addLine(to: CGPoint(x: center.x + 24, y: center.y + 24))
                    cross.move(to: CGPoint(x: center.x + 24, y: center.y - 24))
                    cross.addLine(to: CGPoint(x: center.x - 24, y: center.y + 24))
                    context.stroke(cross, with: .color(.white.opacity(0.12)), lineWidth: 1)
                case .none:
                    break
                }
            }
        }
    }
}

struct VerticalDashedLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        return path
    }
}

// MARK: - 内容卡与说明卡

struct ContentCard<Content: View>: View {
    var padding: CGFloat = 14
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(GowithColor.surface, in: RoundedRectangle(cornerRadius: GowithMetrics.contentCardRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: GowithMetrics.contentCardRadius, style: .continuous)
                    .stroke(GowithColor.surfaceBorder.opacity(0.7), lineWidth: 1).allowsHitTesting(false)
            }
    }
}

/// 功能性说明卡（出行后 / 清点小贴士等）：只有数据与规则，没有装饰文案（规格 2.5）。
struct NoteCard: View {
    var title: String? = nil
    var systemImage: String? = nil
    let lines: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let title {
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(GowithColor.inkSecondary)
            }
            ForEach(lines, id: \.self) { line in
                HStack(alignment: .top, spacing: 6) {
                    if let systemImage {
                        Image(systemName: systemImage)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(GowithColor.accent)
                            .frame(width: 14)
                            .padding(.top, 1)
                    }
                    Text(line)
                        .font(.system(size: 11))
                        .foregroundStyle(GowithColor.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(GowithColor.surface, in: RoundedRectangle(cornerRadius: GowithMetrics.contentCardRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: GowithMetrics.contentCardRadius, style: .continuous)
                .stroke(GowithColor.surfaceBorder.opacity(0.7), lineWidth: 1).allowsHitTesting(false)
        }
        .accessibilityElement(children: .combine)
    }
}

/// 围栏外的功能性提示行。
struct FenceGateNote: View {
    let placeName: String
    var body: some View {
        Label("到达「\(placeName)」约 50 米内可拿取或调整物品", systemImage: "lock.fill")
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(GowithColor.inkSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(GowithColor.softSurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - 货架行（规格 4.3）

struct ShelfRow: View {
    let item: GowithItem
    let placeName: String?
    let isPacked: Bool
    var isEditable: Bool = true
    var highlight: Bool = false
    /// 装包/移除；携带按钮在坐标系 "root" 中的位置供飞球动画使用
    let onTogglePack: () -> Void
    let onEdit: () -> Void

    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 12) {
            ItemThumbnail(fileName: item.imageFileName, symbolName: item.symbolName, size: GowithMetrics.rowIconSize, isSymbolLight: isPacked)
                .background(isPacked ? GowithColor.ink : GowithColor.softSurface, in: RoundedRectangle(cornerRadius: GowithMetrics.rowIconRadius, style: .continuous))
                .animation(reduceMotion ? nil : GowithMotion.row, value: isPacked)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(GowithFont.rowTitle)
                    .foregroundStyle(GowithColor.ink)
                    .lineLimit(1)
                Text(isPacked ? "已装入背包" : statusText)
                    .font(GowithFont.rowSubtitle)
                    .foregroundStyle(isPacked ? GowithColor.accent : GowithColor.inkTertiary)
                    .animation(reduceMotion ? nil : GowithMotion.row, value: isPacked)
            }
            Spacer(minLength: 8)

            PackPlusButton(isPacked: isPacked, isEnabled: isEditable) {
                onTogglePack()
            }
            .disabled(!isEditable)
            .opacity(isEditable ? 1 : 0.4)
        }
        .padding(.horizontal, 12)
        .frame(minHeight: GowithMetrics.rowHeight)
        .contentShape(Rectangle())
        .background(highlight ? GowithColor.accent.opacity(0.1) : .clear)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: highlight)
        .onTapGesture { if isEditable { onEdit() } }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(item.name)，\(isPacked ? "已装入背包" : statusText)")
        .accessibilityHint(isEditable ? "双击\(isPacked ? "移出背包" : "装入背包")，长按编辑物品" : "到达地点范围内后才能操作")
        .accessibilityAddTraits(.isButton)
    }

    private var statusText: String {
        placeName.map { "在「\($0)」" } ?? "随身"
    }
}

/// 装包按钮：+ 旋转 45° 变 ✕ 并转橙（规格 2.4）；按钮中心位置通过 PreferenceKey 上报给飞球动画。
struct PackPlusButton: View {
    let isPacked: Bool
    var isEnabled: Bool = true
    var anchorID: UUID? = nil
    let action: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(isPacked ? .white : GowithColor.onPrimary)
                .frame(width: 29, height: 29)
                .background(isPacked ? GowithColor.accent : GowithColor.ink, in: Circle())
                .rotationEffect(.degrees(isPacked ? 45 : 0))
                .animation(reduceMotion ? nil : GowithMotion.row, value: isPacked)
        }
        .buttonStyle(.plain)
        .background(
            GeometryReader { geo in
                let frame = geo.frame(in: .named("root"))
                return Color.clear
                    .preference(key: PackSourceKey.self, value: [PackAnchor(id: anchorID, center: CGPoint(x: frame.midX, y: frame.midY))])
            }
        )
        .accessibilityLabel(isPacked ? "从背包移除" : "装入背包")
    }
}

struct PackAnchor: Equatable {
    let id: UUID?
    let center: CGPoint
}

struct PackSourceKey: PreferenceKey {
    static var defaultValue: [PackAnchor] = []
    static func reduce(value: inout [PackAnchor], nextValue: () -> [PackAnchor]) {
        value.append(contentsOf: nextValue())
    }
}

/// Tab 按钮中心位置（飞球终点），在命名坐标系 "root" 中测量。
struct TabAnchorKey: PreferenceKey {
    static var defaultValue: [AppTab: CGPoint] = [:]
    static func reduce(value: inout [AppTab: CGPoint], nextValue: () -> [AppTab: CGPoint]) {
        value.merge(nextValue()) { _, new in new }
    }
}

// MARK: - 清点行（规格 4.4）

struct CheckRow: View {
    let name: String
    let fileName: String?
    let symbolName: String
    let isReturned: Bool
    var subtitle: String? = nil
    var selectedTitle: String = "已带回"
    var unselectedTitle: String = "待确认"
    let onToggle: () -> Void
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                ItemThumbnail(fileName: fileName, symbolName: symbolName, size: GowithMetrics.rowIconSize, isSymbolLight: isReturned)
                    .background(isReturned ? GowithColor.ink : GowithColor.softSurface, in: RoundedRectangle(cornerRadius: GowithMetrics.rowIconRadius, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    Text(name)
                        .font(GowithFont.rowTitle)
                        .foregroundStyle(GowithColor.ink)
                        .lineLimit(1)
                    if let subtitle {
                        Text(subtitle)
                            .font(GowithFont.rowSubtitle)
                            .foregroundStyle(GowithColor.inkTertiary)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 8)
                HStack(spacing: 8) {
                    Text(isReturned ? selectedTitle : unselectedTitle)
                        .font(GowithFont.rowSubtitle)
                        .foregroundStyle(isReturned ? GowithColor.inkSecondary : GowithColor.accent)
                    Image(systemName: isReturned ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(isReturned ? GowithColor.ink : GowithColor.inkTertiary.opacity(0.6))
                        .contentTransition(.symbolEffect(.replace))
                }
                .frame(minHeight: 44, alignment: .trailing)
            }
            .padding(.horizontal, 12)
            .frame(minHeight: GowithMetrics.rowHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(name)，\(isReturned ? selectedTitle : unselectedTitle)")
        .accessibilityHint(isReturned ? "双击改为\(unselectedTitle)" : "双击标记为\(selectedTitle)")
    }
}

// MARK: - 分类胶囊条（规格 4.6）

struct CategoryChips: View {
    struct Chip: Identifiable {
        let id: UUID?
        let name: String
        var systemImage: String? = nil
    }

    let chips: [Chip]
    @Binding var selection: UUID?
    var trailingNew: (() -> Void)? = nil
    var onEditChip: ((UUID) -> Void)? = nil
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(chips) { chip in
                    let isSelected = chip.id == selection
                    Button {
                        withAnimation(GowithMotion.tabSelect) { selection = chip.id }
                        GowithHaptics.selection()
                    } label: {
                        HStack(spacing: 4) {
                            if let systemImage = chip.systemImage {
                                Image(systemName: systemImage).font(.system(size: 10, weight: .semibold))
                            }
                            Text(chip.name)
                        }
                        .font(.system(size: 11.5, weight: isSelected ? .bold : .medium))
                        .foregroundStyle(isSelected ? GowithColor.onPrimary : GowithColor.inkSecondary)
                        .padding(.horizontal, 12)
                        .frame(minHeight: 30)
                        .background(isSelected ? GowithColor.ink : GowithColor.surface, in: Capsule())
                        .overlay { Capsule().stroke(isSelected ? .clear : GowithColor.surfaceBorder, lineWidth: 1).allowsHitTesting(false) }
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        if let onEditChip, let id = chip.id {
                            Button("编辑「\(chip.name)」", systemImage: "pencil") { onEditChip(id) }
                        }
                    }
                }
                if let trailingNew {
                    Button(action: trailingNew) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(GowithColor.inkSecondary)
                            .frame(width: 30, height: 30)
                            .background(GowithColor.surface, in: Capsule())
                            .overlay { Capsule().stroke(GowithColor.surfaceBorder, lineWidth: 1).allowsHitTesting(false) }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("新建分类")
                }
            }
            .padding(.horizontal, 1)
            .padding(.vertical, 1)
        }
    }
}

// MARK: - Tab 栏与角标（规格 4.5 / 3）

struct GowithTabItem: Identifiable {
    var id: AppTab { tab }
    let tab: AppTab
    let title: String
    let icon: String
    var badge: Int = 0
}

struct GowithTabBar: View {
    let items: [GowithTabItem]
    @Binding var selection: AppTab
    @Namespace private var capsuleSpace
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 4) {
            ForEach(items) { item in
                tabButton(item)
            }
        }
        .padding(5)
        .frame(maxWidth: .infinity)
        .background(GowithColor.appBackground.opacity(0.96))
        .overlay(alignment: .top) { Divider().opacity(0.4) }
    }

    private func tabButton(_ item: GowithTabItem) -> some View {
        let isSelected = selection == item.tab
        return Button {
            guard selection != item.tab else { return }
            withAnimation(reduceMotion ? nil : GowithMotion.tabSelect) { selection = item.tab }
            GowithHaptics.selection()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: item.icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(item.title)
                    .font(GowithFont.tabLabel)
            }
            .foregroundStyle(isSelected ? GowithColor.onPrimary : GowithColor.inkTertiary)
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, minHeight: 40)
            .background {
                if isSelected {
                    Capsule()
                        .fill(GowithColor.ink)
                        .matchedGeometryEffect(id: "tab", in: capsuleSpace)
                }
            }
            .overlay(alignment: .topTrailing) {
                if item.badge > 0 {
                    Text(item.badge > 99 ? "99+" : "\(item.badge)")
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 4)
                        .frame(minWidth: 15, minHeight: 15)
                        .background(GowithColor.accent, in: Capsule())
                        .offset(x: 12, y: -5)
                        .modifier(BadgePulseModifier(token: item.badge))
                }
            }
            .contentShape(Rectangle())
            .background(
                GeometryReader { geo in
                    let frame = geo.frame(in: .named("root"))
                    return Color.clear.preference(key: TabAnchorKey.self, value: [item.tab: CGPoint(x: frame.midX, y: frame.midY)])
                }
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.title + (item.badge > 0 ? "，\(item.badge) 项待处理" : ""))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// 角标数值变化时弹跳（规格 2.4：1 → 1.45 → 1）。
struct BadgePulseModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let token: Int
    @State private var scale: CGFloat = 1

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .onChange(of: token) { _, _ in
                guard !reduceMotion else { return }
                withAnimation(GowithMotion.badgeBounce) { scale = 1.45 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
                    withAnimation(GowithMotion.badgeBounce) { scale = 1 }
                }
            }
    }
}

// MARK: - 悬浮主按钮（规格 3 / 2.2）

struct MainButtonArea: View {
    let title: String
    var isEnabled: Bool = true
    let action: () -> Void
    var showsFade: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            if showsFade {
                LinearGradient(colors: [GowithColor.appBackground.opacity(0), GowithColor.appBackground], startPoint: .top, endPoint: .bottom)
                    .frame(height: 26)
                    .allowsHitTesting(false)
            }
            Button(action: action) {
                Text(title)
                    .font(GowithFont.mainButton)
                    .foregroundStyle(GowithColor.onPrimary)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(GowithColor.ink, in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(!isEnabled)
            .opacity(isEnabled ? 1 : 0.4)
            .accessibilityHint(isEnabled ? "" : "当前不可用")
            .padding(.horizontal, GowithMetrics.pagePadding)
            .padding(.top, 2)
            .padding(.bottom, 10)
        }
    }
}

// MARK: - 二级页 Sheet 骨架（规格 5.7）

struct SheetNavBar: View {
    let title: String
    var saveTitle: String = "保存"
    var saveEnabled: Bool = true
    var showsCancel: Bool = true
    let onCancel: () -> Void
    var onSave: () -> Void = {}

    var body: some View {
        ZStack {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(GowithColor.ink)
            HStack {
                if showsCancel {
                    Button("取消", action: onCancel)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(GowithColor.inkSecondary)
                }
                Spacer()
                Button(action: onSave) {
                    Text(saveTitle)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(GowithColor.onPrimary)
                        .padding(.horizontal, 14)
                        .frame(minHeight: 28)
                        .background(GowithColor.ink, in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(!saveEnabled)
                .opacity(saveEnabled ? 1 : 0.35)
            }
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 44)
    }
}

// MARK: - 状态徽标（历史详情复用，跟随黑白体系）

struct GowithStatusBadge: View {
    let status: SessionItemStatus

    var body: some View {
        Label(status.title, systemImage: status.icon)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(status.isNeutral ? GowithColor.ink : GowithColor.accent)
            .padding(.horizontal, 9)
            .frame(minHeight: 24)
            .background(GowithColor.softSurface, in: Capsule())
    }
}

extension SessionItemStatus {
    var title: String {
        switch self {
        case .unconfirmed: return "待处理"
        case .returned: return "已带回"
        case .pending: return "待确认"
        case .lost: return "遗失"
        case .stored: return "已放入"
        case .carried: return "继续携带"
        }
    }

    var icon: String {
        switch self {
        case .unconfirmed: return "circle"
        case .returned: return "checkmark.circle.fill"
        case .pending: return "clock.fill"
        case .lost: return "exclamationmark.circle.fill"
        case .stored: return "shippingbox.fill"
        case .carried: return "backpack.fill"
        }
    }

    /// 已带回类为中性黑白；待确认/遗失用强调橙提示（规格 2.1）。
    var isNeutral: Bool {
        switch self {
        case .returned, .stored, .carried: return true
        case .unconfirmed, .pending, .lost: return false
        }
    }
}

// MARK: - 定位恢复条

/// 定位权限被拒后的恢复条：解释影响 + 一键跳转系统设置。
struct GowithLocationRecoveryBanner: View {
    @EnvironmentObject private var locationService: LocationService

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "location.slash.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(GowithColor.onPrimary)
                .frame(width: 30, height: 30)
                .background(GowithColor.ink, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text("定位未开启")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(GowithColor.ink)
                Text("无法判断是否在地点范围内")
                    .font(.system(size: 10))
                    .foregroundStyle(GowithColor.inkSecondary)
            }
            Spacer(minLength: 8)
            Button("前往设置") { locationService.openSystemSettings() }
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(GowithColor.onPrimary)
                .padding(.horizontal, 12)
                .frame(minHeight: 30)
                .background(GowithColor.ink, in: Capsule())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(GowithColor.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(GowithColor.surfaceBorder.opacity(0.7), lineWidth: 1).allowsHitTesting(false)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("定位未开启，无法判断是否在地点范围内。前往设置开启。")
    }
}

// MARK: - 保留的基础组件（首启设置页使用）

struct GowithCard<Content: View>: View {
    var padding: CGFloat = 18
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(GowithColor.surface, in: RoundedRectangle(cornerRadius: GowithMetrics.contentCardRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: GowithMetrics.contentCardRadius, style: .continuous)
                    .stroke(GowithColor.surfaceBorder.opacity(0.7), lineWidth: 1)
            }
    }
}

struct GowithPrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage ?? "")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(GowithColor.onPrimary)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(GowithColor.ink, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct GowithSecondaryButton: View {
    let title: String
    var systemImage: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage ?? "")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(GowithColor.ink)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(GowithColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(GowithColor.surfaceBorder, lineWidth: 1).allowsHitTesting(false)
                }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 物品缩略图（照片 / 3D 图标 / SF Symbol 三态）

struct ItemThumbnail: View {
    var data: Data? = nil
    let fileName: String?
    let symbolName: String
    let size: CGFloat
    /// 深色底上 SF Symbol 转白色，避免黑底黑字不可见
    var isSymbolLight: Bool = false

    init(data: Data? = nil, fileName: String?, symbolName: String, size: CGFloat, isSymbolLight: Bool = false) {
        self.data = data
        self.fileName = fileName
        self.symbolName = symbolName
        self.size = size
        self.isSymbolLight = isSymbolLight
    }

    var body: some View {
        Group {
            if let data, let image = UIImage(data: data) {
                Image(uiImage: image).resizable().scaledToFill()
            } else if let image = LocalImageStore.cachedImage(fileName: fileName) {
                Image(uiImage: image).resizable().scaledToFill()
            } else if let option = Gowith3DIconOption.option(for: symbolName) {
                Gowith3DIcon(option: option, size: size * 0.8)
            } else {
                Image(systemName: symbolName)
                    .font(.system(size: size * 0.42, weight: .medium))
                    .foregroundStyle(isSymbolLight ? GowithColor.onPrimary : GowithColor.ink)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: GowithMetrics.rowIconRadius, style: .continuous))
        .accessibilityHidden(true)
    }
}

/// 背包小预览（S3 / 说明行使用）
struct GowithBackpackPreview: View {
    let backpack: GowithBackpack?
    var size: CGFloat = 44

    var body: some View {
        Group {
            if let backpack, let image = LocalImageStore.cachedImage(fileName: backpack.imageFileName) {
                Image(uiImage: image).resizable().scaledToFit()
            } else if let backpack, let option = Gowith3DIconOption.option(for: backpack.symbolName) {
                Gowith3DIcon(option: option, size: size * 0.82)
            } else {
                Image(systemName: backpack?.symbolName ?? "backpack.fill")
                    .font(.system(size: size * 0.44, weight: .semibold))
                    .foregroundStyle(GowithColor.ink)
            }
        }
        .frame(width: size, height: size)
        .background(GowithColor.softSurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityHidden(true)
    }
}
