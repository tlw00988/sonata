import AVFoundation
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    configureAudioSession()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  /// 音乐播放需要 `playback` 类别的音频会话：默认的 `soloAmbient` 会在 App
  /// 切到后台或锁屏时被系统挂起。配合 Info.plist 里的 `UIBackgroundModes: audio`
  /// 才能让 media_kit 在后台 / 锁屏继续出声（并忽略静音键）。
  private func configureAudioSession() {
    try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
  }
}
