import SwiftUI

// MARK: - 冷启动品牌故事（仅首次启动出现一次；之后打开直进主界面）

/// 三幕结构：字标逐字浮现 + 句点落下 → 「家 / 背包 / 清点」图形动画（讲清核心模型）→ 记忆终帧（字标 + 口号 + 三关键词）。
/// 点按任意处：未到终帧时直接跳到终帧；终帧时结束。Reduce Motion 降级为静态终帧。
struct HeroSplashView: View {
    let onFinished: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var phase = 0 // 0 字标 · 1 三幕 · 2 终帧
    @State private var wordmarkIn = false
    @State private var dotIn = false
    @State private var sceneIndex = 0
    @State private var isFadingOut = false
    @State private var playTask: Task<Void, Never>?
    @State private var finishTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            GowithColor.heroBackground
            content
                .transition(.opacity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(GowithColor.heroBackground.ignoresSafeArea())
        .contentShape(Rectangle())
        .onTapGesture { handleTap() }
        .accessibilityHidden(true)
        .task { play() }
        .onDisappear { playTask?.cancel(); finishTask?.cancel() }
    }

    @ViewBuilder
    private var content: some View {
        if reduceMotion || phase == 2 {
            seedCard
        } else if phase == 0 {
            wordmark
        } else {
            storyScenes
        }
    }

    // MARK: 时间线

    private func play() {
        if reduceMotion {
            phase = 2
            scheduleFinish(after: 2.4)
            return
        }
        playTask = Task {
            withAnimation(.easeOut(duration: 0.4)) { wordmarkIn = true }
            try? await nap(0.66)
            guard !Task.isCancelled else { return }
            withAnimation(GowithMotion.heroDot) { dotIn = true }
            try? await nap(0.95)
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.3)) { phase = 1 }
            for index in 0..<3 {
                guard !Task.isCancelled else { return }
                sceneIndex = index
                try? await nap(1.05)
            }
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.32)) { phase = 2 }
            scheduleFinish(after: 3.2)
        }
    }

    private func nap(_ seconds: Double) async throws {
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }

    private func scheduleFinish(after seconds: Double) {
        finishTask?.cancel()
        finishTask = Task {
            try? await nap(seconds)
            guard !Task.isCancelled else { return }
            finish()
        }
    }

    private func handleTap() {
        guard !isFadingOut else { return }
        if phase < 2 && !reduceMotion {
            playTask?.cancel()
            finishTask?.cancel()
            withAnimation(.easeInOut(duration: 0.26)) { phase = 2 }
            scheduleFinish(after: 2.6)
        } else {
            finish()
        }
    }

    private func finish() {
        guard !isFadingOut else { return }
        playTask?.cancel()
        finishTask?.cancel()
        withAnimation(.easeInOut(duration: 0.3)) { isFadingOut = true }
        Task { @MainActor in
            try? await nap(0.32)
            onFinished()
        }
    }

    // MARK: 第一幕：字标逐字浮现 + 句点落下

    private var letters: [String] { "Gowith".map(String.init) }

    private var wordmark: some View {
        HStack(spacing: 0) {
            ForEach(letters.indices, id: \.self) { index in
                Text(letters[index])
                    .font(.system(size: 46, weight: .heavy, design: .rounded))
                    .tracking(-1.6)
                    .foregroundStyle(.white)
                    .opacity(wordmarkIn ? 1 : 0)
                    .offset(y: wordmarkIn ? 0 : 20)
                    .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.06), value: wordmarkIn)
            }
            Text(".")
                .font(.system(size: 46, weight: .heavy, design: .rounded))
                .tracking(-1.6)
                .foregroundStyle(GowithColor.accent)
                .opacity(dotIn ? 1 : 0)
                .offset(y: dotIn ? 0 : -44)
        }
    }

    // MARK: 第二幕：家 / 背包 / 清点 三幕图形动画

    private var storyScenes: some View {
        VStack(spacing: 26) {
            sceneGraphic
                .frame(height: 170)
            sceneCaption
        }
        .id(sceneIndex)
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
        .animation(.easeInOut(duration: 0.32), value: sceneIndex)
    }

    @ViewBuilder
    private var sceneGraphic: some View {
        switch sceneIndex {
        case 0: HomeScene()
        case 1: BackpackScene()
        default: CheckScene()
        }
    }

    private var sceneCaption: some View {
        VStack(spacing: 8) {
            Text(["HOME", "PACKING", "CHECK-IN"][sceneIndex])
                .font(.system(size: 10, weight: .bold))
                .tracking(3)
                .foregroundStyle(.white.opacity(0.4))
            Text(["家", "背包", "清点"][sceneIndex])
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
            Text(["物品放在哪", "出门装什么", "回家少没少"][sceneIndex])
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.55))
        }
        .animation(.easeOut(duration: 0.4).delay(0.15), value: sceneIndex)
    }

    // MARK: 第三幕：记忆终帧

    private var seedCard: some View {
        VStack(spacing: 18) {
            HStack(spacing: 0) {
                Text("Gowith")
                    .font(.system(size: 46, weight: .heavy, design: .rounded))
                    .tracking(-1.6)
                    .foregroundStyle(.white)
                Text(".")
                    .font(.system(size: 46, weight: .heavy, design: .rounded))
                    .tracking(-1.6)
                    .foregroundStyle(GowithColor.accent)
            }
            Text("出门带的，一件不少。")
                .font(.system(size: 13, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(.white.opacity(0.72))

            HStack(spacing: 8) {
                seedChip(icon: "house.fill", text: "家")
                seedChip(icon: "backpack.fill", text: "背包")
                seedChip(icon: "checkmark.circle.fill", text: "清点")
            }
            .padding(.top, 6)

            Text("轻点任意位置开始")
                .font(.system(size: 10, weight: .medium))
                .tracking(2)
                .foregroundStyle(.white.opacity(0.38))
                .padding(.top, 14)
                .modifier(BreathingModifier())
        }
    }

    private func seedChip(icon: String, text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(GowithColor.accent)
            Text(text)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.88))
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 32)
        .background(.white.opacity(0.08), in: Capsule())
        .overlay { Capsule().stroke(.white.opacity(0.12), lineWidth: 1).allowsHitTesting(false) }
    }
}

/// 终帧提示的呼吸循环（信息停留的节奏感；Reduce Motion 下静止）。
private struct BreathingModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isUp = false

    func body(content: Content) -> some View {
        content
            .opacity(isUp ? 0.85 : 0.4)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) { isUp = true }
            }
    }
}

// MARK: - 三幕图形（全部矢量代码绘制）

/// 幕一：房屋轮廓描线生长，橙色门浮现。
private struct HomeScene: View {
    @State private var drawn = false

    var body: some View {
        ZStack {
            HouseOutline()
                .trim(from: 0, to: drawn ? 1 : 0)
                .stroke(.white.opacity(0.9), style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round))
                .frame(width: 140, height: 130)
            RoundedRectangle(cornerRadius: 4)
                .fill(GowithColor.accent)
                .frame(width: 22, height: 30)
                .offset(y: 34)
                .opacity(drawn ? 1 : 0)
                .scaleEffect(drawn ? 1 : 0.4, anchor: .bottom)
                .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.5), value: drawn)
        }
        .onAppear { animate() }
    }

    private func animate() {
        withAnimation(.easeInOut(duration: 0.6)) { drawn = true }
    }
}

private struct HouseOutline: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.move(to: CGPoint(x: w * 0.06, y: h * 0.46))
        p.addLine(to: CGPoint(x: w * 0.5, y: h * 0.1))
        p.addLine(to: CGPoint(x: w * 0.94, y: h * 0.46))
        p.move(to: CGPoint(x: w * 0.18, y: h * 0.42))
        p.addLine(to: CGPoint(x: w * 0.18, y: h * 0.86))
        p.addLine(to: CGPoint(x: w * 0.82, y: h * 0.86))
        p.addLine(to: CGPoint(x: w * 0.82, y: h * 0.42))
        return p
    }
}

/// 幕二：三件随身物品飞进背包，计数徽标弹出。
private struct BackpackScene: View {
    @State private var backpackIn = false
    @State private var itemsIn = false
    @State private var badgeIn = false

    private let itemIcons = ["key.fill", "umbrella.fill", "headphones"]

    var body: some View {
        ZStack {
            Image(systemName: "bag.fill")
                .font(.system(size: 86, weight: .light))
                .foregroundStyle(.white.opacity(0.9))
                .scaleEffect(backpackIn ? 1 : 0.6)
                .opacity(backpackIn ? 1 : 0)

            HStack(spacing: 14) {
                ForEach(itemIcons.indices, id: \.self) { index in
                    Image(systemName: itemIcons[index])
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(.white.opacity(0.14), in: Circle())
                        .offset(x: itemsIn ? 0 : -120 - CGFloat(index) * 34,
                                y: itemsIn ? 0 : CGFloat(index - 1) * 26)
                        .opacity(itemsIn ? 0 : 1)
                        .animation(.easeIn(duration: 0.4).delay(Double(index) * 0.16), value: itemsIn)
                }
            }
            .offset(x: -34)

            Text("3")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(GowithColor.accent, in: Circle())
                .overlay { Circle().stroke(GowithColor.heroBackground, lineWidth: 3).allowsHitTesting(false) }
                .offset(x: 44, y: -42)
                .scaleEffect(badgeIn ? 1 : 0.2)
                .opacity(badgeIn ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) { backpackIn = true }
            withAnimation(.easeIn(duration: 0.4).delay(0.35)) { itemsIn = true }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.5).delay(0.95)) { badgeIn = true }
        }
    }
}

/// 幕三：圆环 + 橙色对勾描边生长。
private struct CheckScene: View {
    @State private var ringDrawn = false
    @State private var checkDrawn = false

    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: ringDrawn ? 1 : 0)
                .stroke(.white.opacity(0.9), style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 120, height: 120)
            Checkmark()
                .trim(from: 0, to: checkDrawn ? 1 : 0)
                .stroke(GowithColor.accent, style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
                .frame(width: 120, height: 120)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.55)) { ringDrawn = true }
            withAnimation(.easeOut(duration: 0.4).delay(0.45)) { checkDrawn = true }
        }
    }
}

private struct Checkmark: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.width * 0.3, y: rect.height * 0.52))
        p.addLine(to: CGPoint(x: rect.width * 0.45, y: rect.height * 0.66))
        p.addLine(to: CGPoint(x: rect.width * 0.72, y: rect.height * 0.36))
        return p
    }
}
