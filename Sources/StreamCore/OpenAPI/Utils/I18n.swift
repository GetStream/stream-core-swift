//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Parses the automatic translations that the API returns in `i18n` objects.
///
/// An `i18n` object has one `<language-code>_text` key per language, plus `language` for the original language code.
public enum I18n {
    private static let originalLanguageKey = "language"
    private static let translatedSuffix = "_text"

    /// The language code of the original text in the `i18n` object, for example `en`.
    public static func originalLanguage(from i18n: [String: String]?) -> String? {
        i18n?[originalLanguageKey]
    }

    /// The translations in the `i18n` object, keyed by language code, or `nil` when it has none.
    public static func translations(from i18n: [String: String]?) -> [String: String]? {
        guard let i18n, !i18n.isEmpty else { return nil }
        var translations = [String: String]()
        for (key, value) in i18n where key.hasSuffix(translatedSuffix) {
            translations[String(key.dropLast(translatedSuffix.count))] = value
        }
        return translations.isEmpty ? nil : translations
    }

    /// The translation of the text to the given language, or `nil` when there is none, it is empty, or it is the same as the text.
    public static func validTranslation<Language: Hashable>(
        of text: String?,
        in translations: [Language: String]?,
        for language: Language,
        originalLanguage: Language?
    ) -> String? {
        guard let text, !text.isEmpty, language != originalLanguage else { return nil }
        guard let translatedText = translations?[language], !translatedText.isEmpty, translatedText != text else { return nil }
        return translatedText
    }
}
