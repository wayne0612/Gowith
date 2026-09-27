import SwiftUI

// MARK: - 首启引导动画（基础 · 仅一次）：把核心功能按 1-2-3-4 步教给用户

/// 全屏聚光灯引导：挖洞高亮真实控件（家 Tab → ＋ 按钮 → 拿东西 → 检查），
/// 每步一张分步卡（第 X 步 · 一句话 · 下一步/跳过），点高亮区或「下一步」推进。
/// 完成或跳过写入 gowith.hasSeenGuidedTour，从此不再出现；「我的 → 重新观看引导动画」可重置。
struct GuidedTourOverlay: View {
    let step: Int
    let tabAnchors: [AppTab: CGPoint]
    let addButtonAnchor: CGPoint?
    let onAdvance: () -> Void
    let onFinish: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse = false
    @State private var handNudge = false

    private struct TourStep {
        let icon: String
        let title: String
        let message: String
        let anchor: CGPoint?
        let holeSize: CGSize
    }

    private var steps: [TourStep] {
        [
            TourStep(
                icon: "house.fill",
                title: "这里是「家」",
                message: "你的每件物品都记录在家的货架上；顶部胶囊可随时切换不同的家。",
                anchor: tabAnchors[.library],
                holeSize: CGSize(width: 66, height: 52)
            ),
            TourStep(
                icon: "plus.circle.fill",
                title: "点 ＋ 添加东西",
                message: "右下角 ＋ 可以添加物品、背包和新家。先放几件常带的东西进去。",
                anchor: addButtonAnchor,
                holeSize: CGSize(width: 68, height: 68)
            ),
            TourStep(
                icon: "backpack.fill",
                title: "装包出发",
                message: "点物品行的 ＋ 装进背包，到「拿东西」核对清单，再点底部按钮开始出行。",
                anchor: tabAnchors[.packing],
                holeSize: CGSize(width: 66, height: 52)
            ),
            TourStep(
                icon: "checklist",
                title: "回家逐项打勾",
                message: "到家自动提醒清点；没带回来的 3 天内可补登——出门带的，一件不少。",
                anchor: tabAnchors[.check],
                holeSize: CGSize(width: 66, height: 52)
            ),
        ]
    }

    private var current: TourStep { steps[min(step, steps.count - 1)] }
    private var isLastStep: Bool { step >= steps.count - 1 }

    var body: some View {
        GeometryReader { geo in
            let anchor = current.anchor ?? CGPoint(x: geo.size.width / 2, y: geo.size.height - 60)
            ZStack {
                spotlightScrim(anchor: anchor, container: geo.size)
                spotlightRing(anchor: anchor)
                spotlightTap(anchor: anchor)
                pointingHand(anchor: anchor)
                tourCard(anchor: anchor, container: geo.size)
            }
            .animation(reduceMotion ? nil : .spring(response: 0.42, dampingFraction: 0.85), value: step)
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) { pulse = true }
            withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) { handNudge = true }
        }
    }

    // MARK: 挖洞遮罩

    private func spotlightScrim(anchor: CGPoint, container: CGSize) -> some View {
        SpotlightScrim(center: anchor, holeSize: current.holeSize)
            .fill(Color.black.opacity(0.62), style: FillStyle(eoFill: true))
            .frame(width: container.width, height: container.height)
            .contentShape(Rectangle())
            .onTapGesture {} // 挡住底层点击，避免引导期间误操作
            .accessibilityHidden(true)
    }

    private func spotlightRing(anchor: CGPoint) -> some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(.white.opacity(pulse ? 0.15 : 0.6), lineWidth: 2)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.white.opacity(pulse ? 0.05 : 0.12))
            }
            .frame(width: current.holeSize.width + 14, height: current.holeSize.height + 14)
            .scaleEffect(pulse ? 1.06 : 1)
            .position(anchor)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    /// 高亮区本身可点：点按即推进（引导用户“按提示点这里”）。
    private func spotlightTap(anchor: CGPoint) -> some View {
        Button(action: onAdvance) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.clear)
                .frame(width: current.holeSize.width + 14, height: current.holeSize.height + 14)
        }
        .buttonStyle(.plain)
        .position(anchor)
        .accessibilityLabel("点按继续：\(current.title)")
    }

    private func pointingHand(anchor: CGPoint) -> some View {
        Image(systemName: "hand.point.up.left.fill")
            .font(.system(size: 22, weight: .semibold))
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.4), radius: 4, y: 2)
            .position(x: anchor.x + current.holeSize.width * 0.52 + 10,
                      y: anchor.y + current.holeSize.height * 0.5 + (handNudge ? 12 : 2))
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    // MARK: 分步卡

    private func tourCard(anchor: CGPoint, container: CGSize) -> some View {
        let cardWidth: CGFloat = 300
        let cardHeight: CGFloat = 178
        let holeTop = anchor.y - (current.holeSize.height + 14) / 2
        let cardCenter = CGPoint(
            x: min(max(anchor.x, cardWidth / 2 + 12), container.width - cardWidth / 2 - 12),
            y: max(holeTop - 20 - cardHeight / 2, cardHeight / 2 + 20)
        )
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: current.icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(GowithColor.onPrimary)
                    .frame(width: 26, height: 26)
                    .background(GowithColor.ink, in: Circle())
                Text("第 \(step + 1) 步 · 共 \(steps.count) 步")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(GowithColor.inkTertiary)
                Spacer()
                Button("跳过引导") { onFinish() }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(GowithColor.inkTertiary)
                    .frame(minHeight: 32)
            }
            Text(current.title)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(GowithColor.ink)
                .padding(.top, 10)
            Text(current.message)
                .font(.system(size: 12.5))
                .foregroundStyle(GowithColor.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 6)
            HStack(spacing: 12) {
                HStack(spacing: 5) {
                    ForEach(steps.indices, id: \.self) { index in
                        Capsule()
                            .fill(index == step ? GowithColor.accent : GowithColor.inkTertiary.opacity(0.3))
                            .frame(width: index == step ? 16 : 5, height: 5)
                    }
                }
                Spacer()
                Button {
                    onAdvance()
                } label: {
                    Text(isLastStep ? "开始使用" : "下一步")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundStyle(GowithColor.onPrimary)
                        .padding(.horizontal, 18)
                        .frame(minHeight: 36)
                        .background(GowithColor.ink, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityHint(isLastStep ? "完成引导" : "进入第 \(step + 2) 步")
            }
            .padding(.top, 14)
        }
        .padding(16)
        .frame(width: cardWidth, alignment: .leading)
        .background(GowithColor.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(GowithColor.surfaceBorder.opacity(0.7), lineWidth: 1).allowsHitTesting(false)
        }
        .shadow(color: .black.opacity(0.28), radius: 24, y: 10)
        .position(cardCenter)
        .id(step)
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .opacity
        ))
    }
}

/// 大矩形 + 圆角洞的 even-odd 路径。
struct SpotlightScrim: Shape {
    let center: CGPoint
    let holeSize: CGSize

    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addRect(rect)
        let hole = CGRect(x: center.x - holeSize.width / 2,
                          y: center.y - holeSize.height / 2,
                          width: holeSize.width,
                          height: holeSize.height)
        p.addRoundedRect(in: hole, cornerSize: CGSize(width: 16, height: 16))
        return p
    }
}
