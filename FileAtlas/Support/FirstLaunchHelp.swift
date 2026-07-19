//
//  FirstLaunchHelp.swift
//  FileAtlas
//
//  Privacy-safe first-launch assistance. It never includes local app data.
//

import AppKit
import Foundation

enum FirstLaunchAIService: String, CaseIterable, Identifiable {
    case chatGPT
    case gemini
    case claude

    var id: String { rawValue }

    var title: String {
        switch self {
        case .chatGPT: "ChatGPT"
        case .gemini: "Gemini"
        case .claude: "Claude"
        }
    }

    var logoResource: (name: String, fileExtension: String) {
        switch self {
        case .chatGPT: ("fileatlas-chatgpt-logo", "jpg")
        case .gemini: ("fileatlas-gemini-logo", "svg")
        case .claude: ("fileatlas-claude-logo", "png")
        }
    }

    var websiteURL: URL {
        switch self {
        case .chatGPT: URL(string: "https://chatgpt.com/")!
        case .gemini: URL(string: "https://gemini.google.com/")!
        case .claude: URL(string: "https://claude.ai/")!
        }
    }
}

struct FirstLaunchHelpContent {
    let language: AppLanguage

    init(language: AppLanguage) {
        self.language = language == .en ? .en : .de
    }

    var handbookURL: URL {
        switch language {
        case .de:
            return URL(string: "https://github.com/Schrotty74/FileAtlas/blob/main/output/pdf/FileAtlas-Handbuch.pdf")!
        case .en:
            return URL(string: "https://github.com/Schrotty74/FileAtlas/blob/main/output/pdf/FileAtlas-Manual-EN.pdf")!
        case .auto:
            assertionFailure("FirstLaunchHelpContent requires a resolved language")
            return URL(string: "https://github.com/Schrotty74/FileAtlas")!
        }
    }

    var prompt: String {
        switch language {
        case .de:
            return """
            Ich habe FileAtlas gerade zum ersten Mal geöffnet. Erkläre mir die App freundlich und in einfacher Sprache. Führe mich Schritt für Schritt durch den ersten sinnvollen Start. Erkläre die wichtigsten Funktionen, wo ich sie in der App finde und wann sie sinnvoll sind. Frage mich am Ende, wobei ich Hilfe benötige. Verwende dieses offizielle Handbuch:
            \(handbookURL.absoluteString)
            """
        case .en:
            return """
            I have just opened FileAtlas for the first time. Explain the app in a friendly and simple way. Guide me step by step through the first useful start. Explain the most important features, where to find them in the app, and when they are useful. At the end, ask me what I need help with. Use this official manual:
            \(handbookURL.absoluteString)
            """
        case .auto:
            assertionFailure("FirstLaunchHelpContent requires a resolved language")
            return ""
        }
    }

    var title: String { language == .de ? "Willkommen bei FileAtlas" : "Welcome to FileAtlas" }

    var introduction: String {
        language == .de
            ? "Füge zuerst einen Ordner hinzu. FileAtlas indiziert ihn lokal, damit du Dateien durchsuchen, vergleichen und sichern kannst."
            : "Start by adding a folder. FileAtlas indexes it locally so you can search, compare, and back up your files."
    }

    var addFolderTitle: String { language == .de ? "Ordner hinzufügen…" : "Add Folder…" }
    var manualButtonTitle: String { language == .de ? "Handbuch öffnen" : "Open Manual" }
    var aiHeading: String { language == .de ? "Erste Hilfe mit KI" : "Get Started with AI Help" }

    var privacyNote: String {
        language == .de
            ? "Die vorbereitete Frage enthält keine lokalen Daten. Sie wird nur in die Zwischenablage kopiert; füge sie beim gewählten Dienst selbst mit Cmd+V ein."
            : "The prepared question contains no local data. It is only copied to the clipboard; paste it into the chosen service yourself with Cmd+V."
    }

    func serviceHelp(_ service: FirstLaunchAIService) -> String {
        language == .de
            ? "Frage kopieren und \(service.title) öffnen"
            : "Copy the question and open \(service.title)"
    }
}

@MainActor
enum FirstLaunchHelpAction {
    static func copyPromptAndOpen(_ service: FirstLaunchAIService, language: AppLanguage) {
        let content = FirstLaunchHelpContent(language: language)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(content.prompt, forType: .string)
        NSWorkspace.shared.open(service.websiteURL)
    }

    static func openManual(for language: AppLanguage) {
        NSWorkspace.shared.open(FirstLaunchHelpContent(language: language).handbookURL)
    }
}
