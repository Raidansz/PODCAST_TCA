//
//  String+Extension.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 10. 31..
//

import Foundation

extension String {
    func cleanHTMLTags() -> String {
        let regex = try? NSRegularExpression(pattern: "<[^>]+>", options: .caseInsensitive)
        let range = NSRange(location: 0, length: self.count)
        let htmlLessString = regex?.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "")
        let cleanedString = htmlLessString?
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")

        return cleanedString?.trimmingCharacters(in: .whitespacesAndNewlines) ?? self
    }
}
