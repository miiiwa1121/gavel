import SwiftUI

/// アプリのブランドカラー。モックの配色トークン（和を意識した indigo / momiji / sage）を
/// 参考にしつつ、ライト/ダーク両対応はシステム標準の背景色に委ねる（`datamine_prototype.jsx`）。
enum GavelTheme {
    /// 主要アクセント（藍）。ボタン・選択状態。
    static let indigo = Color(hex: 0x1E4B7A)
    /// 差し色（紅葉）。報酬・強調。
    static let momiji = Color(hex: 0xC1440E)
    /// 進捗・落ち着いた強調（青竹）。
    static let sage = Color(hex: 0x5C7F63)
    /// 成功。
    static let success = Color(hex: 0x2F7D4F)
}

extension Color {
    /// 0xRRGGBB 形式の整数から不透明色を作る。
    init(hex: UInt32) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: 1.0)
    }
}
