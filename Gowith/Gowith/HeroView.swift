import SwiftUI

// MARK: - 冷启动品牌帧（信息与引导升级方案 3.1）

/// 黑底字标 + 橙色句点落下弹跳 + 口号淡入，总时长 ≤0.9s；点按任意处立即跳过。
/// 仅冷启动显示（进程生命周期内只出现一次）；Reduce Motion 降级为整体淡入淡出。
struct HeroSplashView: View {
    let onFinished: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var wordmarkVisible = false
    @State private var dotLanded = false
    @State private var taglineVisible = false
    @State private var isFadingOut = false

    private var dotDropHeight: CGFloat { -42 }

    var body: some View {
        ZStack {
            GowithColor.heroBackground
            VStack(spacing: 16) {
                HStack(alignment: .bottom, spacing: 0) {
                    Text("Gowith")
                        .font(.system(size: 46, weight: .heavy, design: .rounded))
                        .tracking(-1.6)
                        .foregroundStyle(.white)
                    Text(".")
                        .font(.system(size: 46, weight: .heavy, design: .rounded))
                        .tracking(-1.6)
                        .foregroundStyle(GowithColor.accent)
                        .offset(y: dotLanded ? 0 : dotDropHeight)
                        .opacity(dotLanded ? 1 : 0)
                }
                Text("出门带的，一件不少。")
                    .font(.system(size: 12, weight: .medium))
                    .tracking(1)
                    .foregroundStyle(.white.opacity(0.55))
                    .opacity(taglineVisible ? 1 : 0)
            }
        }
        .opacity(isFadingOut ? 0 : 1)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(GowithColor.heroBackground.ignoresSafeArea())
        .contentShape(Rectangle())
        .onTapGesture { finish() }
        .accessibilityHidden(true)
        .task { play() }
    }

    private func play() {
        if reduceMotion {
            withAnimation(.easeInOut(duration: 0.3)) {
                wordmarkVisible = true
                dotLanded = true
                taglineVisible = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { finish() }
            return
        }
        // 时序：字标浮现 0.25s → 句点 spring 落下 → 口号淡入 → 淡出，合计 ≈0.9s
        withAnimation(.easeOut(duration: 0.25)) { wordmarkVisible = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            withAnimation(GowithMotion.heroDot) { dotLanded = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
            withAnimation(.easeIn(duration: 0.2)) { taglineVisible = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.68) { finish() }
    }

    private func finish() {
        guard !isFadingOut else { return }
        withAnimation(.easeInOut(duration: 0.24)) { isFadingOut = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.26) { onFinished() }
    }
}
