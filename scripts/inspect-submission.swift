#!/usr/bin/env swift
// 実機 smoke test 用: 保存された1投稿フォルダ（manifest.json + video + imu.jsonl [+ annotation]）を
// 検査し、F-1 の確認項目を機械的に判定する。
//   使い方: swift scripts/inspect-submission.swift <submission-folder>
// 判定: (1) IMU 件数 ≒ 尺×100、(2) IMU の開始 t ≈ 0、(3) 本編 mov に音声トラックが無い、
//       (4) 映像トラックが1本存在、(5) manifest とファイルの整合。

import AVFoundation
import Foundation

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data((message + "\n").utf8))
    exit(1)
}

let args = CommandLine.arguments
guard args.count >= 2 else { fail("usage: swift inspect-submission.swift <submission-folder>") }
let folder = URL(fileURLWithPath: args[1], isDirectory: true)

// --- manifest.json ---
let manifestURL = folder.appendingPathComponent("manifest.json")
guard let manifestData = try? Data(contentsOf: manifestURL),
      let root = (try? JSONSerialization.jsonObject(with: manifestData)) as? [String: Any],
      let submission = root["submission"] as? [String: Any],
      let files = root["files"] as? [String: Any] else {
    fail("manifest.json を読めません: \(manifestURL.path)")
}

let duration = (submission["videoDurationSec"] as? Double) ?? 0
let rate = (submission["imuSampleRateHz"] as? Double) ?? 100
let claimedIMUCount = (submission["imuSampleCount"] as? Int) ?? -1
let missionId = (submission["missionId"] as? String) ?? "?"
let outcome = (submission["outcome"] as? String) ?? "?"
let hasAudioAnnotation = (submission["hasAudioAnnotation"] as? Bool) ?? false
let videoName = (files["video"] as? String) ?? "video.mov"
let imuName = (files["imu"] as? String) ?? "imu.jsonl"
let annotationName = files["audioAnnotation"] as? String

var passed = true
func check(_ label: String, _ ok: Bool, _ detail: String) {
    if !ok { passed = false }
    print("\(ok ? "✅" : "❌") \(label): \(detail)")
}

print("=== 投稿検査: \(folder.lastPathComponent) ===")
print("ミッション: \(missionId) / 結果: \(outcome) / 尺: \(String(format: "%.2f", duration))秒 / 音声アノテ: \(hasAudioAnnotation ? "あり" : "なし")")
print("")

// --- (1) IMU 件数 ≒ 尺×100 と (2) 開始 t ≈ 0 ---
let imuURL = folder.appendingPathComponent(imuName)
if let imuData = try? Data(contentsOf: imuURL) {
    let lines = imuData.split(separator: 0x0A, omittingEmptySubsequences: true)
    let imuCount = lines.count
    let expected = duration * rate
    let ratio = expected > 0 ? Double(imuCount) / expected : 0
    check("IMU 件数", ratio >= 0.8 && ratio <= 1.2,
          "\(imuCount)件（期待≒\(Int(expected.rounded())) = 尺×\(Int(rate))Hz, カバレッジ \(String(format: "%.0f%%", ratio * 100))）")
    check("manifest の件数一致", imuCount == claimedIMUCount, "manifest=\(claimedIMUCount) / 実ファイル=\(imuCount)")

    // 開始・終了 t
    if let first = lines.first,
       let obj = (try? JSONSerialization.jsonObject(with: Data(first))) as? [String: Any],
       let firstT = obj["t"] as? Double {
        check("IMU 開始 t ≈ 0", abs(firstT) < 0.05, "先頭 t = \(String(format: "%.4f", firstT))秒")
    }
    if let last = lines.last,
       let obj = (try? JSONSerialization.jsonObject(with: Data(last))) as? [String: Any],
       let lastT = obj["t"] as? Double {
        let drift = abs(lastT - duration)
        check("IMU 終了 t ≈ 尺", drift < 0.5, "末尾 t = \(String(format: "%.2f", lastT))秒（映像尺との差 \(String(format: "%.2f", drift))秒）")
    }
} else {
    check("imu.jsonl 読み込み", false, "見つかりません: \(imuURL.path)")
}

// --- (3)(4) 映像トラック: 音声0本・映像1本 ---
let videoURL = folder.appendingPathComponent(videoName)
let asset = AVURLAsset(url: videoURL)
let semaphore = DispatchSemaphore(value: 0)
Task {
    defer { semaphore.signal() }
    do {
        let videoTracks = try await asset.loadTracks(withMediaType: .video)
        let audioTracks = try await asset.loadTracks(withMediaType: .audio)
        check("本編クリップに音声トラックが無い", audioTracks.isEmpty, "音声トラック \(audioTracks.count) 本")
        check("映像トラックが存在", videoTracks.count == 1, "映像トラック \(videoTracks.count) 本")
        if let track = videoTracks.first {
            let size = try await track.load(.naturalSize)
            print("ℹ️  解像度: \(Int(abs(size.width)))×\(Int(abs(size.height)))")
        }
    } catch {
        check("映像トラックの読み込み", false, "AVAsset の読み込みに失敗（\(error.localizedDescription)）")
    }
}
semaphore.wait()

// --- (5) 任意の音声アノテーション整合 ---
if hasAudioAnnotation {
    if let annotationName {
        let ok = FileManager.default.fileExists(atPath: folder.appendingPathComponent(annotationName).path)
        check("音声アノテーション実体", ok, ok ? annotationName : "ファイルが無い: \(annotationName)")
    } else {
        check("音声アノテーション整合", false, "hasAudioAnnotation=true だが files.audioAnnotation が無い")
    }
}

print("")
print(passed ? "🟢 判定: すべての確認項目に合格" : "🔴 判定: 不合格の項目あり（上記 ❌ を確認）")
exit(passed ? 0 : 1)
