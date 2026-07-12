import SwiftUI

/// オンボーディングのルート。環境からストア/セッションを受け取り VM を組み立てる。
struct OnboardingView: View {
    @Environment(AppContainer.self) private var container
    @Environment(SessionModel.self) private var session
    @State private var model: OnboardingViewModel?

    var body: some View {
        ZStack {
            if let model {
                OnboardingFlow(model: model)
            } else {
                ProgressView()
            }
        }
        .task {
            guard model == nil else { return }
            model = OnboardingViewModel(
                profileStore: container.profileStore,
                onComplete: { contributor in session.completeOnboarding(with: contributor) }
            )
        }
    }
}

/// ステップ表示と下部ナビゲーションを担う本体。
private struct OnboardingFlow: View {
    @Bindable var model: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    switch model.step {
                    case .welcome: welcome
                    case .consent: consent
                    case .profile: profile
                    case .tutorial: tutorial
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let errorMessage = model.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(GavelTheme.momiji)
                    .padding(.horizontal, 24)
            }

            bottomBar
        }
    }

    // MARK: - ステップ

    private var welcome: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("gavel へようこそ")
                .font(.largeTitle.bold())
            Text("あなたの「手元の動作」が、日本の生活に対応するロボットを育てる学習データになります。")
                .font(.body)
                .foregroundStyle(.secondary)
            Label("一人称・マウント撮影で「映像＋IMU」を集めます", systemImage: "camera.viewfinder")
            Label("1回の撮影＝1つのタスクの1実演", systemImage: "square.stack.3d.up")
            Label("まずは撮り方に慣れることから始めましょう", systemImage: "sparkles")
        }
    }

    private var consent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(ConsentText.title)
                .font(.title2.bold())
            ForEach(Array(ConsentText.points.enumerated()), id: \.offset) { _, point in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "checkmark.seal")
                        .foregroundStyle(GavelTheme.indigo)
                    Text(point)
                        .font(.callout)
                }
            }
            Text(ConsentText.footnote)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Toggle("上記の内容に同意します", isOn: $model.consentAccepted)
                .tint(GavelTheme.indigo)
                .padding(.top, 4)
        }
    }

    private var profile: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("プロフィール登録")
                .font(.title2.bold())
            Text("v1 は招待制です。配布された招待コードと表示名を入力してください。")
                .font(.callout)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 6) {
                Text("表示名").font(.subheadline.bold())
                TextField("例：たろう", text: $model.displayName)
                    .textFieldStyle(.roundedBorder)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("招待コード").font(.subheadline.bold())
                TextField("例：GAVEL-XXXX", text: $model.inviteCode)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("マウント位置").font(.subheadline.bold())
                Picker("マウント位置", selection: $model.mountType) {
                    ForEach(MountType.allCases, id: \.self) { mount in
                        Text(mount.displayName).tag(mount)
                    }
                }
                .pickerStyle(.segmented)
                Text("スマホを体に装着して撮ることで、IMU（動き）が意味を持ちます。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var tutorial: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("上手に撮るコツ")
                .font(.title2.bold())
            Text("最初の数件で撮り方を体に入れると、その後がぐっと安定します。")
                .font(.callout)
                .foregroundStyle(.secondary)
            ForEach(Self.tutorialTips, id: \.self) { tip in
                Label(tip, systemImage: "hand.point.right")
                    .font(.callout)
            }
        }
    }

    private static let tutorialTips: [String] = [
        "スマホを頭または胸のクリップに装着し、両手を空ける",
        "手元がいつも画面の中央に入るように体を向ける",
        "手元に光が当たるようにする（暗い・逆光を避ける）",
        "1回の撮影で「1つのタスクを1回」だけ実演する",
        "撮り終えたら、成功/失敗を自分で判断して記録する",
    ]

    // MARK: - 下部ナビ

    private var bottomBar: some View {
        HStack(spacing: 12) {
            if model.step != .welcome {
                Button("戻る") { model.back() }
                    .buttonStyle(.bordered)
                    .disabled(model.isSaving)
            }
            Button {
                Task { await model.advance() }
            } label: {
                Group {
                    if model.isSaving {
                        ProgressView()
                    } else {
                        Text(model.step == .tutorial ? "撮影をはじめる" : "次へ")
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!model.canAdvance || model.isSaving)
        }
        .padding(16)
        .background(.bar)
    }
}
