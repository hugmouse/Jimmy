//
//  ContentParser.swift
//  jimmy
//
//  Created by Jonathan Foucher on 17/02/2022.
//

import Foundation

import SwiftUI

enum BlockType {
    case text
    case pre
    case list
    case link
    case title1
    case title2
    case title3
    case quote
    case end
}


class ContentParser {
    var parsed: [LineView] = []
    var header: Header
    var attrStr: NSAttributedString
    let tab: Tab
    let fontManager: NSFontManager = NSFontManager.shared
    var firstTitle = ""
    
    init(content: Data, tab: Tab) {
        self.attrStr = NSAttributedString(string: "")
        self.tab = tab
        self.parsed = []
        self.header = Header(line: "")
        self.firstTitle = ""
        
        if let range = content.firstRange(of: Data("\r\n".utf8)) {
            let headerRange = content.startIndex..<range.lowerBound
            let firstLineData = content.subdata(in: headerRange)
            let firstlineString = String(decoding: firstLineData, as: UTF8.self)
            self.header = Header(line: firstlineString)
            
            let contentRange = range.upperBound..<content.endIndex
            let contentData = content.subdata(in: contentRange)
            
            if (20...29).contains(self.header.code) {
                // if we have a success response code
                if self.header.contentType.starts(with: "image/") {
                    self.parsed = [LineView(data: contentData, type: self.header.contentType, tab: tab)]
                } else if self.header.contentType.starts(with: "text/gemini") {
                    self.attrStr = parseGemText(String(decoding: contentData, as: UTF8.self).replacingOccurrences(of: "\r", with: ""))
                    

                } else if self.header.contentType.starts(with: "text/") {
                    self.attrStr = NSMutableAttributedString(string: String(decoding: contentData, as: UTF8.self), attributes: self.getAttributesForType(.pre, link: nil))
                        //.font(.system(size: 14, weight: .light, design: .monospaced))
                } else {
                    // Download unknown file type
                    DispatchQueue.main.async {
                        let mySave = NSSavePanel()
                        mySave.prompt = "Save"
                        mySave.title = "Saving " + tab.url.lastPathComponent
                        mySave.nameFieldStringValue = tab.url.lastPathComponent

                        mySave.begin { (result: NSApplication.ModalResponse) -> Void in
                            if result == NSApplication.ModalResponse.OK {
                                if let fileurl = mySave.url {
                                    print("file url is", fileurl)
                                    do {
                                        try contentData.write(to: fileurl)
                                    } catch {
                                        print("error writing")
                                    }
                                } else {
                                    print("no file url")
                                }
                            } else {
                                print ("cancel")
                            }
                        }
                    }
                }
            }
        }
    }
    
    func parseGemText(_ content: String) -> NSAttributedString {
        let lines = content.split(separator: "\n")
        let result = NSMutableAttributedString(string: "")
        var str: String = ""
        var pre = false
        var firstTitle: String? = nil
        for (index, l) in lines.enumerated() {
            let line = l.trimmingCharacters(in: CharacterSet(charactersIn: "\u{FEFF}"))
            let blockType = getBlockType(String(line))
            if blockType == .pre {
                pre = !pre
                
                if !pre {
                    let attr = getAttributesForType(.pre, link: nil)
                    let pstr = NSAttributedString(string: "\n" + str + "\n", attributes: attr)

                    result.append(pstr)
                    
                    str = ""
                }
                continue
            }

            str += getLineForType(String(line), type: blockType) + "\n"
            if pre {
                continue
            }
            
            let nextBlockType: BlockType = index+1 < lines.count ? getBlockType(String(lines[index+1])) : .end
            
            
            if (blockType != nextBlockType) || blockType == .link || blockType == .title1 || blockType == .title2 || blockType == .title3 {
                // output previous block
                
                if blockType == .quote || blockType == .list {
                    str = "\n" + str
                }
                
                if (blockType == .title1 || blockType == .title1 || blockType == .title3)  && firstTitle == nil {
                    firstTitle = str.replacingOccurrences(of: "#", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                    self.firstTitle = firstTitle!
                }
                
                if blockType == .link {
                    let linkAS = getLinkAS(str)
                    result.append(linkAS)
                } else if blockType == .quote {
                    let quoteAS = getQuoteAS(str)
                    result.append(quoteAS)
                } else {
                    let attr = getAttributesForType(blockType, link: nil)

                    result.append(NSAttributedString(string: str.trimmingCharacters(in: .whitespaces), attributes: attr))
                }
                
                str = ""
            }
        }
        
        return result
    }
    
    func getBlockType(_ l: String) -> BlockType {
        let line = l.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: CharacterSet(charactersIn: "\u{FEFF}"))
        if line.starts(with: "###") {
            return .title3
        } else if line.starts(with: "##") {
            return .title2
        } else if line.starts(with: "#") {
            return .title1
        } else if line.starts(with: "=>") {
            return .link
        } else if line.starts(with: "*") {
            return .list
        } else if line.starts(with: ">") {
            return .quote
        } else if line.starts(with: "```") {
           return .pre
        } else {
            return .text
        }
    }
    
    func getLinkAS(_ str: String) -> NSAttributedString {
        // create our NSTextAttachment
        let image1Attachment = NSTextAttachment()
        var newStr = str.replacingOccurrences(of: "=>", with: "", options: [], range: .init(NSRange(location: 0, length: 2), in: str)).trimmingCharacters(in: .whitespaces)
        if newStr.starts(with: "//") {
            newStr = newStr.replacingOccurrences(of: "//", with: "gemini://")
        }
        
        let link = parseLink(newStr)
        
        var linkLabel = ""
        if let label = link.label {
            linkLabel = label + "\n"
        } else {
            linkLabel = link.original + "\n"
        }
        let url = link.link
        let attr = getAttributesForType(.link, link: url)
        if linkLabel.startsWithEmoji {
            return  NSAttributedString(string: linkLabel, attributes: attr)
        }
        var imgName = "arrow.right"
        if let scheme = url.scheme {
            if scheme.starts(with: "http") {
                imgName = "network"
            }
            if scheme.starts(with: "mailto") {
                imgName = "mail"
            }
        }


        image1Attachment.image = NSImage(systemSymbolName: imgName, accessibilityDescription: "")
        
//        // wrap the attachment in its own attributed string so we can append it
        let image1String = NSMutableAttributedString(attachment: image1Attachment)

        image1String.append(NSAttributedString(string: " "))

        image1String.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: NSRange(location: 0, length: 2))
        image1String.addAttribute(.font, value: NSFont.systemFont(ofSize: tab.fontSize * 1.4), range: NSRange(location: 0, length: 2))
        image1String.addAttribute(.baselineOffset, value: -tab.fontSize * 0.1, range: NSRange(location: 0, length: 2))
        image1String.addAttribute(.paragraphStyle, value: attr[.paragraphStyle] ?? [], range: NSRange(location: 0, length: 2))

        image1String.append(NSAttributedString(string: linkLabel, attributes: attr))

        //
        return image1String
    }
    
    
    func getQuoteAS(_ str: String) -> NSAttributedString {
        // create our NSTextAttachment
        let image1Attachment = NSTextAttachment()
        let newStr = str.replacingOccurrences(of: ">", with: "", options: [], range: .init(NSRange(location: 0, length: 2), in: str)).trimmingCharacters(in: .whitespacesAndNewlines)

        let attr = getAttributesForType(.quote, link: nil)

        let imgName = "quote.opening"

        image1Attachment.image = NSImage(systemSymbolName: imgName, accessibilityDescription: "Quote")
        
//        // wrap the attachment in its own attributed string so we can append it
        let image1String = NSMutableAttributedString(attachment: image1Attachment)

        image1String.append(NSAttributedString(string: " "))
        
        let range = NSRange(location: 0, length: image1String.string.count)

        image1String.addAttribute(.foregroundColor, value: NSColor.controlAccentColor.blended(withFraction: 0.3, of: NSColor.green) ?? NSColor.green, range: range)
        image1String.addAttribute(.font, value: NSFont.systemFont(ofSize: tab.fontSize * 1.4), range: range)
        image1String.addAttribute(.baselineOffset, value: -tab.fontSize * 0.1, range: range)
        image1String.addAttribute(.kern, value: tab.fontSize * 2, range: range)
        let pst: NSMutableParagraphStyle = attr[.paragraphStyle] as? NSMutableParagraphStyle ?? NSMutableParagraphStyle()
        
        pst.paragraphSpacingBefore = tab.fontSize
    
        image1String.addAttribute(.paragraphStyle, value: pst, range: range)

        image1String.append(NSAttributedString(string: newStr + "\n", attributes: attr))

        
        return image1String
    }
    
    func getLineForType(_ str: String, type: BlockType) -> String {
        switch type {
        case .text, .pre:
            return str
            
        case .list:
            return str.replacingOccurrences(of: "*", with: "•", options: [], range: .init(NSRange(location: 0, length: 1), in: str)).trimmingCharacters(in: .whitespaces)
        
        case .link:
            return str
            
        case .title1:
            return str.replacingOccurrences(of: "#", with: "", options: [], range: .init(NSRange(location: 0, length: 1), in: str)).trimmingCharacters(in: .whitespaces)
        case .title2:
            return str.replacingOccurrences(of: "#", with: "", options: [], range: .init(NSRange(location: 0, length: 2), in: str)).trimmingCharacters(in: .whitespaces)
        case .title3:
            return str.replacingOccurrences(of: "#", with: "", options: [], range: .init(NSRange(location: 0, length: 3), in: str)).trimmingCharacters(in: .whitespaces)
        case .quote:
            return str.replacingOccurrences(of: ">", with: "", options: [], range: .init(NSRange(location: 0, length: 1), in: str)).trimmingCharacters(in: .whitespaces)
        case .end:
            return str
        }
    }
    
    var title1Style: [NSAttributedString.Key: Any] {
        let pst = NSMutableParagraphStyle()
        pst.alignment = .left
        pst.lineSpacing = 2
        pst.paragraphSpacing = tab.fontSize
        pst.paragraphSpacingBefore = tab.fontSize

        let boldFont = NSFont.systemFont(ofSize: tab.fontSize * 2.5, weight: .bold)

        return [
            .font: boldFont,
            .paragraphStyle: pst,
            .foregroundColor: NSColor.labelColor
        ]
    }

    var title2Style: [NSAttributedString.Key: Any] {
        let pst = NSMutableParagraphStyle()
        pst.alignment = .left
        pst.lineSpacing = 2
        pst.paragraphSpacing = tab.fontSize
        pst.paragraphSpacingBefore = tab.fontSize

        let semiboldFont = NSFont.systemFont(ofSize: tab.fontSize * 1.8, weight: .semibold)

        return [
            .font: semiboldFont,
            .paragraphStyle: pst,
            .foregroundColor: NSColor.labelColor
        ]
    }

    var title3Style: [NSAttributedString.Key: Any] {
        let pst = NSMutableParagraphStyle()
        pst.alignment = .left
        pst.lineSpacing = 2
        pst.paragraphSpacing = tab.fontSize
        pst.paragraphSpacingBefore = tab.fontSize

        let regularFont = NSFont.systemFont(ofSize: tab.fontSize * 1.5, weight: .regular)

        return [
            .font: regularFont,
            .paragraphStyle: pst,
            .foregroundColor: NSColor.labelColor
        ]
    }
    
    var listStyle: [NSAttributedString.Key: Any] {
        let pst = NSMutableParagraphStyle()
        pst.alignment = .left
        pst.headIndent = tab.fontSize * 2.5
        pst.firstLineHeadIndent = tab.fontSize * 2.5
        pst.lineSpacing = tab.fontSize / 3
        pst.paragraphSpacing = tab.fontSize / 2

        let font = NSFont.systemFont(ofSize: tab.fontSize, weight: .regular)
        return [
            .font: font,
            .foregroundColor: NSColor.labelColor,
            .paragraphStyle: pst
        ]
    }
    
    var preStyle: [NSAttributedString.Key: Any] {
        let pst = NSMutableParagraphStyle()
        pst.alignment = .left
        pst.paragraphSpacing = 0
        pst.paragraphSpacingBefore = 0
        let tabInterval: CGFloat = 80.0
        pst.tabStops = (1...20).map { NSTextTab(textAlignment: .left, location: CGFloat($0) * tabInterval) }

        return [
            .font: NSFont.monospacedSystemFont(ofSize: tab.fontSize, weight: .regular),
            .foregroundColor: NSColor.secondaryLabelColor,
            .backgroundColor: NSColor.controlBackgroundColor,
            .paragraphStyle: pst
        ]
    }
    
    var textStyle: [NSAttributedString.Key: Any] {
        let pst = NSMutableParagraphStyle()
        pst.alignment = .left
        pst.lineSpacing = tab.fontSize / 4
        pst.paragraphSpacing = tab.fontSize
        pst.paragraphSpacingBefore = tab.fontSize

        let font = NSFont.systemFont(ofSize: tab.fontSize, weight: .regular)
        return [
            .font: font,
            .foregroundColor: NSColor.labelColor,
            .paragraphStyle: pst
        ]
    }
    
    var quoteStyle: [NSAttributedString.Key: Any] {
        let pst = NSMutableParagraphStyle()
        pst.alignment = .left
        pst.lineSpacing = tab.fontSize / 3
        pst.headIndent = tab.fontSize * 3
        pst.firstLineHeadIndent = tab.fontSize * 3
        pst.paragraphSpacing = tab.fontSize / 2

        let baseFont = NSFont.systemFont(ofSize: tab.fontSize * 1.2, weight: .regular)
        let italicFont = fontManager.convert(baseFont, toHaveTrait: .italicFontMask)

        return [
            .font: italicFont,
            .foregroundColor: NSColor.secondaryLabelColor,
            .paragraphStyle: pst
        ]
    }
    
    func getLinkAttributes(link: URL?, fontSize: CGFloat) -> [NSAttributedString.Key: Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        paragraphStyle.lineSpacing = 0
        paragraphStyle.paragraphSpacing = fontSize / 2
        paragraphStyle.paragraphSpacingBefore = fontSize / 2

        let font = NSFont.systemFont(ofSize: fontSize, weight: .medium)
        return [
            .font: font,
            .link: link ?? URL(string: "gemini://about")!,
            .foregroundColor: NSColor.linkColor,
            .cursor: NSCursor.pointingHand,
            .paragraphStyle: paragraphStyle
        ]
    }

    
    func getAttributesForType(_ type: BlockType, link: URL?) -> [NSAttributedString.Key: Any] {
        switch type {
        case .text:
            return textStyle
        case .pre:
            return preStyle
        case .list:
            return listStyle
        case .link:
            return getLinkAttributes(link: link, fontSize: tab.fontSize)
        case .title1:
            return title1Style
        case .title2:
            return title2Style
        case .title3:
            return title3Style
        case .quote:
            return quoteStyle
        case .end:
            return [:]
        }
    }
    
    private func parseLink(_ l: String) -> Link {
        let line = l.replacingOccurrences(of: "=>", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        let start = line.startIndex
        var end = line.endIndex
        if let endRange = line.range(of: "\t") {
            end = endRange.upperBound
        } else if let endRange = line.range(of: " ") {
            end = endRange.upperBound
        }
        

        
        let linkString = line[start..<end].trimmingCharacters(in: .whitespaces)
        
        
        let original = linkString
        var link = URLParser(baseURL: tab.url, link: linkString).toAbsolute()
        if linkString.starts(with: "gemini://") {
            if let p = URL(string: String(linkString)) {
                link = p
            }
        }
        
        var label = String(line[end..<line.endIndex]).trimmingCharacters(in: .whitespaces)
        if end == line.endIndex {
            label = link.absoluteString.decodedURLString ?? link.absoluteString
        }
        
        return Link(link: link, label: label, original: original)
    }
}



struct Link {
    var link: URL
    var label: String?
    var original: String
}

extension Character {
    /// A simple emoji is one scalar and presented to the user as an Emoji
    var isSimpleEmoji: Bool {
        guard let firstScalar = unicodeScalars.first else { return false }
        return firstScalar.properties.isEmoji && firstScalar.value > 0x238C
    }

    /// Checks if the scalars will be merged into an emoji
    var isCombinedIntoEmoji: Bool { unicodeScalars.count > 1 && unicodeScalars.first?.properties.isEmoji ?? false }

    var isEmoji: Bool { isSimpleEmoji || isCombinedIntoEmoji }
}

extension String {
    var isSingleEmoji: Bool { count == 1 && containsEmoji }

    var containsEmoji: Bool { contains { $0.isEmoji } }
    
    var startsWithEmoji: Bool {
        if let f = self.first {
            return f.isEmoji
        }
        return false
    }

    var containsOnlyEmoji: Bool { !isEmpty && !contains { !$0.isEmoji } }

    var emojiString: String { emojis.map { String($0) }.reduce("", +) }

    var emojis: [Character] { filter { $0.isEmoji } }

    var emojiScalars: [UnicodeScalar] { filter { $0.isEmoji }.flatMap { $0.unicodeScalars } }
}
