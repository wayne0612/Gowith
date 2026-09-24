import SwiftUI
import UIKit

enum GowithColor {
    static let appBackground = adaptive(light: (0.961, 0.953, 0.941), dark: (0.07, 0.07, 0.07))
    static let surface = adaptive(light: (1, 1, 1), dark: (0.14, 0.14, 0.14))
    static let softSurface = adaptive(light: (0.925, 0.918, 0.902), dark: (0.20, 0.20, 0.20))
    static let primary = adaptive(light: (0.067, 0.067, 0.067), dark: (0.94, 0.94, 0.94))
    static let onPrimary = adaptive(light: (1, 1, 1), dark: (0.067, 0.067, 0.067))
    static let heroBackground = Color(red: 0.067, green: 0.067, blue: 0.067)
    static let secondary = adaptive(light: (0.435, 0.427, 0.404), dark: (0.70, 0.70, 0.70))
    static let tertiary = adaptive(light: (0.61, 0.59, 0.56), dark: (0.56, 0.56, 0.56))
    static let border = adaptive(light: (0.887, 0.875, 0.85), dark: (0.28, 0.28, 0.28))
    static let pending = adaptive(light: (0.93, 0.91, 0.84), dark: (0.31, 0.28, 0.20))
    static let success = adaptive(light: (0.88, 0.93, 0.90), dark: (0.18, 0.29, 0.22))
    static let lost = adaptive(light: (0.95, 0.89, 0.89), dark: (0.34, 0.20, 0.20))
    static let sceneMint = adaptive(light: (0.737, 0.937, 0.878), dark: (0.15, 0.34, 0.29))
    static let sceneCoral = adaptive(light: (0.949, 0.416, 0.408), dark: (0.45, 0.18, 0.17))
    static let sceneAmber = adaptive(light: (0.969, 0.784, 0.420), dark: (0.43, 0.31, 0.12))
    static let sceneSky = adaptive(light: (0.663, 0.851, 0.961), dark: (0.16, 0.30, 0.40))
    static let sceneViolet = adaptive(light: (0.788, 0.722, 0.961), dark: (0.28, 0.22, 0.42))
    static let sceneOrange = adaptive(light: (0.949, 0.651, 0.427), dark: (0.42, 0.25, 0.14))
    static let sceneBlue = adaptive(light: (0.682, 0.741, 0.922), dark: (0.20, 0.26, 0.42))

    private static func adaptive(light: (CGFloat, CGFloat, CGFloat), dark: (CGFloat, CGFloat, CGFloat)) -> Color {
        Color(uiColor: UIColor { traits in
            let values = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: values.0, green: values.1, blue: values.2, alpha: 1)
        })
    }
}

enum GowithMetrics {
    static let pagePadding: CGFloat = 20
    static let cardPadding: CGFloat = 18
    static let cardRadius: CGFloat = 28
    static let rowRadius: CGFloat = 12
    static let sectionSpacing: CGFloat = 24
    static let topBarHeight: CGFloat = 68
    static let bottomBarHeight: CGFloat = 64
    static let focusHeight: CGFloat = 292
    static let rowHeight: CGFloat = 68
}

enum GowithMotion {
    static let row = Animation.easeInOut(duration: 0.19)
    static let content = Animation.easeInOut(duration: 0.24)
    static let object = Animation.spring(response: 0.34, dampingFraction: 0.86)
}

/// 关键时刻的触觉反馈：到达提醒、清点勾选、开始/完成出行。
enum GowithHaptics {
    /// 清单勾选类轻反馈
    static func selection() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }

    /// 到达地点、完成出行等成功节点
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }

    /// 开始出行等状态切换
    static func stateChange() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
}

struct GowithCard<Content: View>: View {
    var padding: CGFloat = GowithMetrics.cardPadding
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background(GowithColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: GowithMetrics.cardRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: GowithMetrics.cardRadius, style: .continuous)
                    .stroke(GowithColor.border.opacity(0.7), lineWidth: 1)
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
                .font(.body.weight(.semibold))
                .foregroundStyle(GowithColor.onPrimary)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(GowithColor.primary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
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
                .font(.body.weight(.semibold))
                .foregroundStyle(GowithColor.primary)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(GowithColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(GowithColor.border, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }
}

struct GowithSectionHeader: View {
    let title: String
    var trailing: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.headline)
                .foregroundStyle(GowithColor.primary)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(GowithColor.tertiary)
            }
        }
    }
}

struct GowithTopBar<Trailing: View>: View {
    let pageTitle: String
    var showsPlace: Bool = true
    @ViewBuilder let trailing: () -> Trailing

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Gowith")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(GowithColor.primary)
                Text(pageTitle)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(GowithColor.secondary)
                    .contentTransition(.opacity)
            }
            Spacer(minLength: 4)
            if showsPlace {
                PlacePickerMenu()
            }
            trailing()
        }
        .frame(maxWidth: .infinity, minHeight: GowithMetrics.topBarHeight, alignment: .topLeading)
    }
}

struct GowithFocusField<Content: View>: View {
    let color: Color
    var height: CGFloat = GowithMetrics.focusHeight
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .frame(maxWidth: .infinity, minHeight: height)
            .background(color, in: RoundedRectangle(cornerRadius: GowithMetrics.cardRadius, style: .continuous))
            .clipped(antialiased: true)
    }
}

struct GowithObjectRail<Content: View>: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let itemCount: Int
    @Binding var selectedIndex: Int
    @ViewBuilder let content: (Int, Bool) -> Content

    var body: some View {
        GeometryReader { proxy in
            let itemWidth = max(264, proxy.size.width - 76)
            ScrollView(.horizontal) {
                LazyHStack(spacing: 14) {
                    ForEach(0..<itemCount, id: \.self) { index in
                        Button {
                            withAnimation(reduceMotion ? nil : GowithMotion.object) { selectedIndex = index }
                        } label: {
                            content(index, index == selectedIndex)
                                .frame(width: itemWidth)
                                .scaleEffect(index == selectedIndex ? 1 : 0.88)
                                .opacity(index == selectedIndex ? 1 : 0.54)
                                .blur(radius: index == selectedIndex ? 0 : 1.6)
                        }
                        .buttonStyle(.plain)
                        .id(index)
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal, 38)
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: Binding<Int?>(
                get: { selectedIndex },
                set: { if let value = $0 { selectedIndex = value } }
            ), anchor: .center)
        }
        .frame(height: GowithMetrics.focusHeight)
    }
}

struct GowithCategoryRail: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let categories: [(id: UUID?, name: String, icon: String)]
    @Binding var selectedID: UUID?

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(Array(categories.enumerated()), id: \.offset) { _, category in
                    let isSelected = selectedID == category.id
                    Button {
                        withAnimation(reduceMotion ? nil : GowithMotion.content) { selectedID = category.id }
                    } label: {
                        Label(category.name, systemImage: category.icon)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(isSelected ? GowithColor.primary : GowithColor.secondary)
                            .padding(.horizontal, 14)
                            .frame(minHeight: 42)
                            .background(isSelected ? GowithColor.sceneMint : GowithColor.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(isSelected ? .clear : GowithColor.border, lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .scrollIndicators(.hidden)
    }
}

struct GowithBottomAction: View {
    let title: String
    var systemImage: String? = nil
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        GowithPrimaryButton(title: title, systemImage: systemImage, action: action)
            .disabled(!isEnabled)
            .opacity(isEnabled ? 1 : 0.44)
    }
}

struct GowithStatusScene: View {
    let color: Color
    let systemImage: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(GowithColor.primary)
                .frame(width: 48, height: 48)
                .background(.white.opacity(0.48), in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(GowithColor.primary)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(GowithColor.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 4)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(GowithColor.primary)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color, in: RoundedRectangle(cornerRadius: GowithMetrics.cardRadius, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title)，\(message)")
    }
}

struct GowithContextStrip: View {
    @EnvironmentObject private var store: GowithStore
    @EnvironmentObject private var locationService: LocationService
    var showsBackpack = true

    private var place: GowithPlace? { store.selectedPlace }
    private var backpack: GowithBackpack? { store.selectedBackpack }
    private var isNearby: Bool {
        guard let place else { return false }
        return locationService.isInside(place)
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isNearby ? "location.fill" : "mappin.and.ellipse")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(isNearby ? GowithColor.primary : GowithColor.onPrimary)
                .frame(width: 34, height: 34)
                .background(isNearby ? GowithColor.sceneMint : GowithColor.primary, in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(isNearby ? "你在这里" : "当前地点")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(GowithColor.tertiary)
                Text(place?.name ?? "还没有地点")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(GowithColor.primary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            if showsBackpack, let backpack {
                HStack(spacing: 7) {
                    GowithBackpackPreview(backpack: backpack, size: 32)
                    Text(backpack.name)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(GowithColor.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("当前地点：\(place?.name ?? "还没有地点")，\(isNearby ? "在范围内" : "不在范围内")\(backpack.map { "，当前背包：\($0.name)" } ?? "")")
    }
}

struct GowithInventoryRow: View {
    let item: GowithItem
    let stateTitle: String
    let stateIcon: String
    var actionTitle: String? = nil
    var actionIcon: String? = nil
    let action: (() -> Void)?

    var body: some View {
        HStack(spacing: 14) {
            ItemThumbnail(fileName: item.imageFileName, symbolName: item.symbolName, size: 48)
            VStack(alignment: .leading, spacing: 5) {
                Text(item.name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(GowithColor.primary)
                    .lineLimit(2)
                Label(stateTitle, systemImage: stateIcon)
                    .font(.caption)
                    .foregroundStyle(GowithColor.secondary)
            }
            Spacer(minLength: 4)
            if let action, let actionTitle, let actionIcon {
                Button(action: action) {
                    Label(actionTitle, systemImage: actionIcon)
                        .labelStyle(.iconOnly)
                        .foregroundStyle(GowithColor.primary)
                        .frame(width: 44, height: 44)
                        .background(GowithColor.softSurface, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(actionTitle)
            }
        }
        .padding(.horizontal, 4)
        .frame(minHeight: GowithMetrics.rowHeight)
        .contentShape(Rectangle())
    }
}

struct GowithBackpackPreview: View {
    let backpack: GowithBackpack?
    var size: CGFloat = 48

    var body: some View {
        Group {
            if let backpack, let image = LocalImageStore.cachedImage(fileName: backpack.imageFileName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else if let backpack, let option = Gowith3DIconOption.option(for: backpack.symbolName) {
                Gowith3DIcon(option: option, size: size)
            } else {
                Image(systemName: backpack?.symbolName ?? "backpack.fill")
                    .font(.system(size: size * 0.48, weight: .semibold))
                    .foregroundStyle(GowithColor.primary)
            }
        }
        .frame(width: size, height: size)
        .background(GowithColor.softSurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityHidden(true)
    }
}

struct GowithHeroView: View {
    let onContinue: () -> Void
    @State private var isPresented = false

    var body: some View {
        ZStack {
            GowithColor.heroBackground.ignoresSafeArea()
            Circle()
                .fill(GowithColor.success.opacity(0.22))
                .frame(width: 330, height: 330)
                .blur(radius: 2)
                .offset(x: 120, y: -270)
            VStack(alignment: .leading, spacing: 0) {
                Spacer()
                Text("Gowith")
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .tracking(-1.8)
                    .foregroundStyle(.white)
                Text("带上要带的，记住带回的。")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.white.opacity(0.72))
                    .padding(.top, 12)

                ZStack {
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .fill(.white.opacity(0.08))
                        .overlay { RoundedRectangle(cornerRadius: 34, style: .continuous).stroke(.white.opacity(0.14), lineWidth: 1) }
                    VStack(spacing: 16) {
                        if let option = Gowith3DIconOption.option(for: "gowith3d.backpack") {
                            Gowith3DIcon(option: option, size: 160)
                        }
                        HStack(spacing: 8) {
                            Circle().fill(GowithColor.success).frame(width: 8, height: 8)
                            Text("从家出发 · 在目的地放下 · 回家清点")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.white.opacity(0.78))
                        }
                    }
                }
                .frame(height: 270)
                .padding(.top, 44)

                Text("一个清晰的出行看板，帮你知道物品在哪里、正在跟着谁走。")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.68))
                    .lineSpacing(4)
                    .padding(.top, 24)
                Spacer()
                Button(action: onContinue) {
                    Text("开始使用")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(GowithColor.primary)
                        .frame(maxWidth: .infinity, minHeight: 54)
                        .background(GowithColor.success, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.bottom, 14)
            }
            .padding(.horizontal, 24)
        }
        .opacity(isPresented ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.35)) { isPresented = true }
        }
    }
}

struct GowithInlineStatus: View {
    let title: String
    let systemImage: String
    var isPositive = false

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.medium))
            .foregroundStyle(isPositive ? GowithColor.primary : GowithColor.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isPositive ? GowithColor.success.opacity(0.18) : GowithColor.softSurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

/// 定位权限被拒后的恢复条：解释影响 + 一键跳转系统设置。
struct GowithLocationRecoveryBanner: View {
    @EnvironmentObject private var locationService: LocationService

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "location.slash.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(GowithColor.onPrimary)
                .frame(width: 34, height: 34)
                .background(GowithColor.primary, in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text("定位未开启")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(GowithColor.primary)
                Text("无法判断是否在地点范围内")
                    .font(.caption2)
                    .foregroundStyle(GowithColor.secondary)
            }
            Spacer(minLength: 8)
            Button("前往设置") { locationService.openSystemSettings() }
                .font(.caption.weight(.semibold))
                .foregroundStyle(GowithColor.onPrimary)
                .padding(.horizontal, 12)
                .frame(minHeight: 32)
                .background(GowithColor.primary, in: Capsule())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(GowithColor.softSurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("定位未开启，无法判断是否在地点范围内。前往设置开启。")
        .accessibilityHint("双击打开系统设置")
    }
}

struct GowithStatusBadge: View {
    let status: SessionItemStatus

    var body: some View {
        Label(status.title, systemImage: status.icon)
            .font(.caption)
            .foregroundStyle(status.foreground)
            .padding(.horizontal, 10)
            .frame(minHeight: 28)
            .background(status.background)
            .clipShape(Capsule())
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

    var background: Color {
        switch self {
        case .unconfirmed: return GowithColor.softSurface
        case .returned: return GowithColor.success
        case .pending: return GowithColor.pending
        case .lost: return GowithColor.lost
        case .stored: return GowithColor.success
        case .carried: return GowithColor.softSurface
        }
    }

    var foreground: Color {
        switch self {
        case .unconfirmed: return GowithColor.secondary
        case .returned, .pending, .lost, .stored, .carried: return GowithColor.primary
        }
    }
}
