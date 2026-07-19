import Testing
@testable import FileAtlas

@MainActor
struct FirstLaunchHelpTests {
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
