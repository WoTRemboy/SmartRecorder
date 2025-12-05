import Foundation
import SwiftUI
import Combine
import UIKit

@MainActor
final class ProfileViewModel: ObservableObject {
    
    @Published internal private(set) var isAuthorized: Bool = false
    @Published internal private(set) var nickname: String = ""
    @Published internal private(set) var email: String = ""

    @Published internal var meetingsCount: Int = 8
    @Published internal var minutesInMeetings: Int = 50

    // Audio cache stats
    @Published internal private(set) var audioFilesCount: Int = 0
    @Published internal private(set) var audioCacheBytes: Int64 = 0
    
    @Published private(set) var mode: AuthMode = .login
    @Published private(set) var isLoading = false
    
    @Published internal var login = LoginForm()
    @Published internal var registerForm = RegistrationForm()
    
    @Published internal var errorMessage: String? = nil
    @Published internal var infoMessage: String? = nil
    
    private let authService = AuthorizationService()
    
    init() {
        Task { [weak self] in
            guard let self = self else { return }
            let authorized = await self.authService.isAuthorized()
            await MainActor.run { self.isAuthorized = authorized }
            await self.loadCurrentUser()
            await self.refreshAudioCacheStats()
        }
    }
        
    internal var stats: [String: Int] {
        [
            "meetings": meetingsCount,
            "meetingsCount": meetingsCount,
            "minutes": minutesInMeetings,
            "minutesInMeetings": minutesInMeetings
        ]
    }
    
    internal func value(forKeys keys: [String]) -> Int {
        for key in keys {
            if let v = stats[key] { return v }
        }
        return 0
    }
    
    internal func memoryUsageAttributed() -> AttributedString {
        let total = formatBytes(audioCacheBytes)
        var base = AttributedString("\(Texts.ProfilePage.Dashboard.Cache.desctiption) \(total) \(Texts.ProfilePage.Dashboard.Cache.memory)")
        if let range = base.range(of: total) {
            base[range].font = .system(size: UIFont.preferredFont(forTextStyle: .title3).pointSize, weight: .semibold)
        }
        return base
    }
    
    internal func clearCacheTapped() {
        Task {
            await clearAudioCache()
        }
    }
    
    // Helper to format bytes as readable string
    internal func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        formatter.includesUnit = true
        return formatter.string(fromByteCount: bytes)
    }
    
    // MARK: - Form state
    
    internal var canSubmit: Bool {
        switch mode {
        case .register:
            return registerForm.isValid
        case .login:
            return login.isValid
        }
    }
    
    internal func toggleMode() {
        withAnimation {
            mode = mode == .login ? .register : .login
        }
    }
    
    internal func submit() async {
        switch mode {
        case .register:
            await register()
        case .login:
            await login()
        }
    }
    
    internal func register() async {
        isLoading = true
        
        defer {
            isLoading = false
        }
        
        do {
            let payload = RegistrationPayload(
                username: registerForm.username,
                email: registerForm.email,
                password: registerForm.password,
                firstName: registerForm.firstName,
                lastName: registerForm.lastName
            )
            try await authService.register(payload)
            infoMessage = Texts.ProfilePage.Toasts.registrationSuccess
            self.isAuthorized = true
            await self.loadCurrentUser()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            infoMessage = nil
        }
    }
    
    internal func login() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let payload = LoginPayload(
                email: login.email,
                password: login.password
            )
            try await authService.login(payload)
            infoMessage = Texts.ProfilePage.Toasts.loginSuccess
            self.isAuthorized = true
            await self.loadCurrentUser()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            infoMessage = nil
        }
    }
    
    private func clearMessages() {
        errorMessage = nil
        infoMessage = nil
    }
    
    // MARK: - User & Authorization
    
    private func loadCurrentUser() async {
        guard isAuthorized else { return }
        do {
            if let user = try await authService.currentUser() {
                await MainActor.run {
                    self.nickname = user.username ?? Texts.ProfilePage.FloatingFields.Nickname.placeholder
                    self.email = user.email ?? Texts.ProfilePage.FloatingFields.Email.placeholder
                    self.meetingsCount = Int(user.countRecords)
                    self.minutesInMeetings = Int(user.countMinutes)
                }
            }
        } catch {
            await MainActor.run { self.errorMessage = error.localizedDescription }
        }
    }
    
    internal func logoutTapped() {
        Task { @MainActor in
            do {
                // 1) Clear auth tokens and stored user
                try TokenService.shared.clear()
                try await authService.clearUserStorage()

                // 2) Delete all Core Data notes
                let noteService = NoteEntityService()
                try await noteService.deleteAll(inFolder: nil)

                // 3) Clear audio caches: temporary m4a and Documents/Audio
                await clearAudioCache()
                await clearDocumentsAudioDirectory()

                // 4) Reset local state
                self.isAuthorized = false
                self.nickname = ""
                self.email = ""
                self.meetingsCount = 0
                self.minutesInMeetings = 0
                self.audioFilesCount = 0
                self.audioCacheBytes = 0

                self.infoMessage = Texts.ProfilePage.Dashboard.Logout.success
                self.errorMessage = nil
            } catch {
                self.errorMessage = error.localizedDescription
                self.infoMessage = nil
            }
        }
    }

    // MARK: - Audio cache
    
    @MainActor
    internal func refreshAudioCacheStats() async {
        let fm = FileManager.default
        let dir = FileManager.default.temporaryDirectory
        let urls = (try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.fileSizeKey], options: [.skipsHiddenFiles])) ?? []
        let audio = urls.filter { $0.pathExtension.lowercased() == "m4a" }
        var total: Int64 = 0
        for url in audio {
            if let values = try? url.resourceValues(forKeys: [.fileSizeKey]), let size = values.fileSize {
                total += Int64(size)
            }
        }
        self.audioFilesCount = audio.count
        self.audioCacheBytes = total
    }

    internal func clearAudioCache() async {
        let fm = FileManager.default
        let dir = FileManager.default.temporaryDirectory
        let urls = (try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])) ?? []
        let audio = urls.filter { $0.pathExtension.lowercased() == "m4a" }
        for url in audio {
            try? fm.removeItem(at: url)
        }
        await refreshAudioCacheStats()
        await MainActor.run { self.infoMessage = Texts.ProfilePage.Dashboard.Cache.success }
    }

    /// Clears downloaded audio files stored under Documents/Audio (used for offline playback/sharing).
    internal func clearDocumentsAudioDirectory() async {
        let fm = FileManager.default
        do {
            let docs = try fm.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let audioDir = docs.appendingPathComponent("Audio", isDirectory: true)
            if fm.fileExists(atPath: audioDir.path) {
                let urls = (try? fm.contentsOfDirectory(at: audioDir, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])) ?? []
                for url in urls where url.pathExtension.lowercased() == "m4a" {
                    try? fm.removeItem(at: url)
                }
            }
        } catch {
            // Swallow errors silently during logout cleanup
        }
        await refreshAudioCacheStats()
    }
}
