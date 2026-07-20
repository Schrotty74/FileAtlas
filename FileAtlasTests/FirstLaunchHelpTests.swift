import Foundation
import Testing
@testable import FileAtlas

@MainActor
struct FirstLaunchHelpTests {
    @Test
    func motionPreferencePersistsInTheSelectedDefaultsStore() {
        let suiteName = "FileAtlasTests.MotionPreferences.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let preferences = MotionPreferences(defaults: defaults)
        #expect(!preferences.reduceMotion)

        preferences.reduceMotion = true
        #expect(MotionPreferences(defaults: defaults).reduceMotion)
    }

    @Test
    func tooltipPreferenceDefaultsToVisibleAndPersists() {
        let suiteName = "FileAtlasTests.TooltipPreferences.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let preferences = TooltipPreferences(defaults: defaults)
        #expect(preferences.showTooltips)

        preferences.showTooltips = false
        #expect(!TooltipPreferences(defaults: defaults).showTooltips)
    }

    @Test
    func colorThemePersistsIndependentlyFromAppearance() {
        let suiteName = "FileAtlasTests.AppearanceManager.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let appearance = AppearanceManager(defaults: defaults, appliesToApplication: false)
        #expect(appearance.mode == .system)
        #expect(appearance.colorTheme == .midnightTeal)

        appearance.mode = .dark
        appearance.colorTheme = .graphiteLime

        let restored = AppearanceManager(defaults: defaults, appliesToApplication: false)
        #expect(restored.mode == .dark)
        #expect(restored.colorTheme == .graphiteLime)
    }

    @Test
    func serviceURLsUseTheOfficialWebsites() {
        #expect(FirstLaunchAIService.chatGPT.websiteURL.absoluteString == "https://chatgpt.com/")
        #expect(FirstLaunchAIService.gemini.websiteURL.absoluteString == "https://gemini.google.com/")
        #expect(FirstLaunchAIService.claude.websiteURL.absoluteString == "https://claude.ai/")
    }

    @Test
    func promptIsDataMinimalAndUsesOnlyThePublicManual() {
        let prompts = [
            FirstLaunchHelpContent(language: .de).prompt,
            FirstLaunchHelpContent(language: .en).prompt,
        ]

        for prompt in prompts {
            #expect(prompt.contains("FileAtlas"))
            #expect(prompt.contains("https://github.com/Schrotty74/FileAtlas/blob/main/output/pdf/"))
            #expect(!prompt.contains("/Users/"))
            #expect(!prompt.contains("/Volumes/"))
            #expect(!prompt.localizedCaseInsensitiveContains("token"))
            #expect(!prompt.localizedCaseInsensitiveContains("password"))
            #expect(!prompt.localizedCaseInsensitiveContains("health"))
        }
    }

    @Test
    func handbookLinkMatchesTheSelectedLanguage() {
        #expect(
            FirstLaunchHelpContent(language: .de).handbookURL.absoluteString
                == "https://github.com/Schrotty74/FileAtlas/blob/main/output/pdf/FileAtlas-Handbuch.pdf"
        )
        #expect(
            FirstLaunchHelpContent(language: .en).handbookURL.absoluteString
                == "https://github.com/Schrotty74/FileAtlas/blob/main/output/pdf/FileAtlas-Manual-EN.pdf"
        )
    }
}
