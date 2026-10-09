import Flutter
import UIKit
import AuthenticationServices

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    if SpotifyBrowserAuthorization.shared.handle(url: url) { return true }
    return super.application(app, open: url, options: options)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "BingusSpotifyAuthorization") {
      SpotifyBrowserAuthorization.shared.register(messenger: registrar.messenger())
    }
  }
}


// The same session receives both ASWebAuthenticationSession completion and
// app-to-app redirects delivered to UIScene. Only the first result is emitted.
@objc class SceneDelegate: FlutterSceneDelegate {
  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    let remaining = URLContexts.filter {
      !SpotifyBrowserAuthorization.shared.handle(url: $0.url)
    }
    if !remaining.isEmpty { super.scene(scene, openURLContexts: Set(remaining)) }
  }
}

private final class SpotifyBrowserAuthorization: NSObject, ASWebAuthenticationPresentationContextProviding {
  static let shared = SpotifyBrowserAuthorization()
  private var channel: FlutterMethodChannel?
  private var session: ASWebAuthenticationSession?
  private var pending: FlutterResult?
  private var attempt: UUID?
  private var redirect: URL?
  private var anchor: UIWindow?

  func register(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "bingusfy/spotify_authorization", binaryMessenger: messenger)
    channel?.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      switch call.method {
      case "authorize": self.authorize(arguments: call.arguments, result: result)
      case "cancel":
        if let id = self.attempt {
          self.finish(id: id, value: FlutterError(code: "cancelled", message: "Login cancelado.", details: nil))
        }
        result(nil)
      default: result(FlutterMethodNotImplemented)
      }
    }
  }

  private func authorize(arguments: Any?, result: @escaping FlutterResult) {
    guard pending == nil else {
      result(FlutterError(code: "busy", message: "Já existe um login em andamento.", details: nil))
      return
    }
    guard let args = arguments as? [String: String],
          let value = args["url"], let url = URL(string: value),
          url.scheme == "https", url.host == "accounts.spotify.com",
          let target = args["redirectUri"], let redirect = URL(string: target),
          redirect.scheme == "br.com.theusmatag.bingo",
          let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .filter({ $0.activationState == .foregroundActive })
            .flatMap({ $0.windows }).first(where: { $0.isKeyWindow }) else {
      result(FlutterError(code: "unavailable", message: "Não foi possível abrir o login.", details: nil))
      return
    }
    let id = UUID()
    self.pending = result
    self.attempt = id
    self.redirect = redirect
    self.anchor = window
    let browser = ASWebAuthenticationSession(url: url, callbackURLScheme: redirect.scheme) { [weak self] callback, error in
      DispatchQueue.main.async {
        guard let self = self, self.attempt == id else { return }
        if let callback = callback {
          self.finish(id: id, value: callback.absoluteString)
        } else {
          let cancelled = (error as? ASWebAuthenticationSessionError)?.code == .canceledLogin
          self.finish(id: id, value: FlutterError(
            code: cancelled ? "cancelled" : "authorization_failed",
            message: cancelled ? "Login cancelado." : "Não foi possível concluir o login.", details: nil))
        }
      }
    }
    browser.presentationContextProvider = self
    self.session = browser
    if !browser.start() {
      finish(id: id, value: FlutterError(code: "unavailable", message: "Não foi possível abrir o login.", details: nil))
    }
  }

  func handle(url: URL) -> Bool {
    guard let id = attempt, let target = redirect,
          url.scheme == target.scheme, url.host == target.host else { return false }
    // Dart validates the complete redirect, state, error and code before any
    // token exchange. Never log this URL or its query parameters.
    finish(id: id, value: url.absoluteString)
    return true
  }

  private func finish(id: UUID, value: Any?) {
    guard attempt == id, let result = pending else { return }
    let browser = session
    pending = nil
    attempt = nil
    session = nil
    redirect = nil
    anchor = nil
    browser?.cancel()
    result(value)
  }

  func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    return anchor ?? ASPresentationAnchor()
  }
}
