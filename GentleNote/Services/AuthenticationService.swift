import LocalAuthentication

@MainActor
final class AuthenticationService: ObservableObject {
    @Published private(set) var lastError: String?

    func authenticate(reason: String) async -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            lastError = "Set up a passcode, Face ID, or Touch ID in iPhone Settings, then try again."
            return false
        }
        do {
            let ok = try await context.evaluatePolicy(.deviceOwnerAuthentication,
                                                      localizedReason: reason)
            lastError = nil
            return ok
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }
}
