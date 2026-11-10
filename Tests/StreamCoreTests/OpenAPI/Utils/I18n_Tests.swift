//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamCore
import Testing

struct I18n_Tests {
    // MARK: - originalLanguage

    @Test func originalLanguageReadsLanguageKey() {
        #expect(I18n.originalLanguage(from: ["en_text": "Hello", "language": "en"]) == "en")
        #expect(I18n.originalLanguage(from: ["en_text": "Hello"]) == nil)
        #expect(I18n.originalLanguage(from: nil) == nil)
    }

    // MARK: - translations

    @Test func translationsKeepsTextKeysByLanguageCode() {
        let translations = I18n.translations(from: ["fr_text": "Bonjour", "language": "en", "zh-TW_text": "你好"])
        #expect(translations == ["fr": "Bonjour", "zh-TW": "你好"])
    }

    @Test func translationsIsNilWithoutTextKeys() {
        #expect(I18n.translations(from: nil) == nil)
        #expect(I18n.translations(from: [:]) == nil)
        #expect(I18n.translations(from: ["language": "en"]) == nil)
    }

    // MARK: - validTranslation

    @Test func validTranslationReturnsTranslation() {
        let translations = ["en": "Hello", "fr": "Bonjour"]
        #expect(I18n.validTranslation(of: "Hello", in: translations, for: "fr", originalLanguage: "en") == "Bonjour")
    }

    @Test func validTranslationIsNilWhenNotUsable() {
        let translations = ["de": "Hello", "en": "Hello", "es": "", "fr": "Bonjour"]
        #expect(I18n.validTranslation(of: "Hello", in: translations, for: "en", originalLanguage: "en") == nil)
        #expect(I18n.validTranslation(of: "Hello", in: translations, for: "de", originalLanguage: "en") == nil)
        #expect(I18n.validTranslation(of: "Hello", in: translations, for: "es", originalLanguage: "en") == nil)
        #expect(I18n.validTranslation(of: "Hello", in: translations, for: "it", originalLanguage: "en") == nil)
        #expect(I18n.validTranslation(of: "Hello", in: nil, for: "fr", originalLanguage: "en") == nil)
        #expect(I18n.validTranslation(of: "", in: translations, for: "fr", originalLanguage: "en") == nil)
        #expect(I18n.validTranslation(of: nil, in: translations, for: "fr", originalLanguage: "en") == nil)
    }

    @Test func validTranslationWorksWithCustomLanguageType() {
        struct Language: Hashable {
            let code: String
        }
        let translations = [Language(code: "fr"): "Bonjour"]
        let english = Language(code: "en")
        #expect(I18n.validTranslation(of: "Hello", in: translations, for: Language(code: "fr"), originalLanguage: english) == "Bonjour")
        #expect(I18n.validTranslation(of: "Hello", in: translations, for: english, originalLanguage: english) == nil)
    }
}
