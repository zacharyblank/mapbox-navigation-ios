import UIKit

let path = Bundle.mapboxNavigation.path(forResource: "Abbreviations", ofType: "plist")!
let allAbbrevations = NSDictionary(contentsOfFile: path) as! [String: [String: String]]

/// Options that specify what kinds of words in a string should be abbreviated.
struct StringAbbreviationOptions : OptionSet {
    let rawValue: Int
    
    /// Abbreviates ordinary words that have common abbreviations.
    static let abbreviations = StringAbbreviationOptions(rawValue: 1 << 0)
    /// Abbreviates directional words.
    static let directions = StringAbbreviationOptions(rawValue: 1 << 1)
    /// Abbreviates road name suffixes.
    static let classifications = StringAbbreviationOptions(rawValue: 1 << 2)
}

extension String {
    /// Returns an abbreviated copy of the string.
    func abbreviated(by options: StringAbbreviationOptions) -> String {
        return characters.split(separator: " ").map(String.init).map { (word) -> String in
            let lowercaseWord = word.lowercased()
            if let abbreviation = allAbbrevations["abbreviations"]![lowercaseWord], options.contains(.abbreviations) {
                return abbreviation
            }
            if let direction = allAbbrevations["directions"]![lowercaseWord], options.contains(.directions) {
                return direction
            }
            if let classification = allAbbrevations["classifications"]![lowercaseWord], options.contains(.classifications) {
                return classification
            }
            return word
            }.joined(separator: " ")
    }
    
    /// Returns the string abbreviated only as much as necessary to fit the given width and font.
    func abbreviated(toFit bounds: CGRect, font: UIFont) -> String {
        var fittedString = self
        let stringSize = fittedString.boundingRect(with: CGSize(width: bounds.width, height: .greatestFiniteMagnitude),
                                                   options: [.usesLineFragmentOrigin, .usesFontLeading],
                                                   attributes: [NSFontAttributeName: font], context: nil).size
        
        if stringSize.width < bounds.width && stringSize.height <= bounds.height {
            return fittedString
        }
        
        fittedString = fittedString.abbreviated(by: [.classifications])
        if stringSize.width < bounds.width && stringSize.height <= bounds.height {
            return fittedString
        }
        
        fittedString = fittedString.abbreviated(by: [.directions])
        if stringSize.width < bounds.width && stringSize.height <= bounds.height {
            return fittedString
        }
        
        return fittedString.abbreviated(by: [.abbreviations])
    }
}

extension NSMutableAttributedString {
    /// Abbreviates the string.
    func abbreviate(by options: StringAbbreviationOptions) {
        mutableString.enumerateSubstrings(in: string.wholeRange, options: .byWords) { (word, wordRange, enclosingRange, stop) in
            guard let lowercaseWord = word?.lowercased() else {
                return
            }
            
            if let abbreviation = allAbbrevations["abbreviations"]![lowercaseWord], options.contains(.abbreviations) {
                self.mutableString.replaceCharacters(in: wordRange, with: abbreviation)
            } else if let direction = allAbbrevations["directions"]![lowercaseWord], options.contains(.directions) {
                self.mutableString.replaceCharacters(in: wordRange, with: direction)
            } else if let classification = allAbbrevations["classifications"]![lowercaseWord], options.contains(.classifications) {
                self.mutableString.replaceCharacters(in: wordRange, with: classification)
            }
        }
    }
    
    /// Abbreviates only as much as necessary to fit the given width and font.
    func abbreviate(toFit bounds: CGRect) {
        let stringSize = boundingRect(with: CGSize(width: bounds.width, height: .greatestFiniteMagnitude),
                                      options: [.usesLineFragmentOrigin, .usesFontLeading],
                                      context: nil).size
        
        if stringSize.width < bounds.width && stringSize.height <= bounds.height {
            return
        }
        
        abbreviate(by: [.classifications])
        if stringSize.width < bounds.width && stringSize.height <= bounds.height {
            return
        }
        
        abbreviate(by: [.directions])
        if stringSize.width < bounds.width && stringSize.height <= bounds.height {
            return
        }
        
        abbreviate(by: [.abbreviations])
    }
}
