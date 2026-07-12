import Foundation

/// v1 の常設ミッション（日本特化タスク）のカタログ。
///
/// 情報源の優先順位に従い、`docs/biz/usecases.md` の旗艦シナリオ（料理中の手元・箸・和食器・
/// 狭い台所での配膳）と `docs/tech/tech-notes.md` §3（卵の置き場所という判断）を具体化した。
/// マーケットプレイスは持たず、少数の狙ったミッションに集中する（`requirements.md` §3）。
enum MissionCatalog {
    /// 表示順に並べた全ミッション。
    static let all: [Mission] = [
        chopsticksPlating,
        washokuTableware,
        narrowKitchenServing,
        eggHandling,
        teaPouring,
    ]

    /// id からミッションを引く。存在しなければ nil。
    static func mission(id: String) -> Mission? {
        all.first { $0.id == id }
    }

    // MARK: - 常設ミッション定義

    static let chopsticksPlating = Mission(
        id: "chopsticks-plating",
        title: "箸で料理を盛り付ける",
        category: .tableware,
        summary: "箸を使って料理を器に美しく盛り付ける手元動作",
        taskDescription: "箸を使って、おかずや小鉢の料理を器に盛り付ける一連の動作を撮影します。つかむ・運ぶ・置く・形を整える、までを1回の実演として行ってください。",
        exampleGuidance: "箸先だけでなく、持ち替えや添え手の使い方も自然に見せてください。盛り付けの向き・高さを整える所作が入ると価値が上がります。",
        successConditions: [
            "箸で対象をつかみ、器へ移して置くまでが1本のクリップに収まっている",
            "手元（箸先と器）が常に画角に入っている",
            "盛り付け後の状態が確認できる",
        ],
        shootingTips: [
            "手元が影にならないよう、手前から光を当てる",
            "器と作業面のコントラストを確保する",
            "早すぎる動作は避け、箸の動きが追える速度で",
        ],
        recommendedMountType: .chest
    )

    static let washokuTableware = Mission(
        id: "washoku-tableware",
        title: "和食器を扱う",
        category: .tableware,
        summary: "茶碗・汁椀・小鉢など和食器を持ち上げ、置き、重ねる所作",
        taskDescription: "和食器（茶碗・汁椀・小鉢・湯呑みなど）を持ち上げる／両手で扱う／静かに置く／重ねる、といった扱いの動作を撮影します。",
        exampleGuidance: "片手持ち・両手持ちの使い分け、指のかけ方、割れ物を静かに置く配慮が見えると良いお手本になります。",
        successConditions: [
            "食器を持ち上げてから置く（または重ねる）までが1クリップに収まっている",
            "食器と手の接点が画角に入っている",
        ],
        shootingTips: [
            "光沢のある器はハレーション（白飛び）に注意し、角度を調整する",
            "重ねる動作は接触の瞬間が見える位置で",
        ],
        recommendedMountType: .chest
    )

    static let narrowKitchenServing = Mission(
        id: "narrow-kitchen-serving",
        title: "狭い台所で配膳する",
        category: .housework,
        summary: "限られた作業スペースで料理を器から膳へ運び配膳する動作",
        taskDescription: "狭い台所やカウンターで、調理済みの料理を器やトレイに載せて配膳位置まで運び、配置する動作を撮影します。日本の住環境特有の「狭さの中での取り回し」が対象です。",
        exampleGuidance: "限られたスペースでの持ち替え・体の向きの変え方・物の一時置きなど、狭さゆえの工夫が見えると価値が高いです。",
        successConditions: [
            "料理を持ち上げてから配膳位置に置くまでが1クリップに収まっている",
            "運搬経路の手元が画角から大きく外れていない",
        ],
        shootingTips: [
            "移動を伴うため、胸マウントで視点を安定させる",
            "振り向き時の急なブレを避け、ゆっくり体を回す",
        ],
        recommendedMountType: .chest,
        allowsAudioAnnotation: true
    )

    static let eggHandling = Mission(
        id: "egg-handling",
        title: "卵を割って中身を移す",
        category: .cooking,
        summary: "卵を割り、殻を分け、中身を器へ移す（置き場所の判断を含む）",
        taskDescription: "卵を割り、殻から中身を器やフライパンへ移す動作を撮影します。割った後の殻や卵をどこに置くか、といった判断も含めて実演してください。",
        exampleGuidance: "「卵はまな板だと転がって落ちるので、コンロの隙間や器の縁に置く」といった“なぜそうしたか”の判断を音声アノテーションで添えると高単価になります（判断・暗黙知＝差別化の柱）。",
        successConditions: [
            "卵を割ってから中身を移し終えるまでが1クリップに収まっている",
            "割る瞬間と中身の移動が画角に入っている",
        ],
        shootingTips: [
            "割る位置（器の縁・平面）が見える角度にする",
            "殻や中身の置き場所まで画角に含める",
        ],
        recommendedMountType: .chest,
        allowsAudioAnnotation: true
    )

    static let teaPouring = Mission(
        id: "tea-pouring",
        title: "急須でお茶を注ぐ",
        category: .cooking,
        summary: "急須から複数の湯呑みへ均等にお茶を注ぐ所作",
        taskDescription: "急須を使って、複数の湯呑みへお茶を注ぎ分ける動作を撮影します。注ぐ量の調整・最後の一滴まで注ぎ切る所作を1回の実演として行ってください。",
        exampleGuidance: "濃さを均等にするための注ぎ分け（回し注ぎ）や、注ぎ口を切る所作が入ると日本特有の手元として価値が上がります。",
        successConditions: [
            "急須を持ち上げてから注ぎ終えるまでが1クリップに収まっている",
            "急須の注ぎ口と湯呑みが画角に入っている",
        ],
        shootingTips: [
            "湯気や液面が見えるよう、やや手前上方から",
            "注ぐ手元がブレないよう肘を安定させる",
        ],
        recommendedMountType: .chest
    )
}
