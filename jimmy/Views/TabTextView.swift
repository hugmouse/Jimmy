//
//  TabContentView.swift
//  jimmy
//
//  Created by Jonathan Foucher on 27/02/2022.
//

import SwiftUI

struct TabTextView: View {
    
    @ObservedObject var tab: Tab
    @State var text = ""
    @State var textRanges: [Range<String.Index>] = []
    
    var close: () -> Void
    
    @ViewBuilder
    var textView: some View {
        AttributedText(
            tab.textContent,
            onOpenLink: { url in
                tab.url = url
                tab.load()
                close()
            },
            onHoverLink: { url, hovered in
                let loadingStatus = tab.loading ? "Loading " + tab.url.absoluteString : ""
                if let u = url {
                    let newStatus = hovered ? (u.absoluteString.decodedURLString ?? u.absoluteString).replacingOccurrences(of: "gemini://", with: "") : loadingStatus
                    if tab.status != newStatus {
                        tab.status = newStatus
                    }
                }
                if hovered == false {
                    tab.status = loadingStatus
                }
            }
        )
    }
    
    var body: some View {
        HStack {
            textView
            .textSelection(.enabled)
            .searchable(text: $text)
            .onChange(of: text, perform: { newValue in
                textRanges = tab.search(text)
            })
            .onSubmit(of: .search) {
                tab.enterSearch()
            }
            .frame(minWidth: 200, maxWidth: 800, alignment: .leading)
            .padding(.top, 24)
            .padding(.bottom, 24)
            
            
        }

        
        .frame(minWidth: 200, maxWidth: .infinity, alignment: .center)
    }
}

extension Text {
    init(_ string: String, configure: ((inout AttributedString) -> Void)) {
        var attributedString = AttributedString(string) /// create an `AttributedString`
        configure(&attributedString) /// configure using the closure
        self.init(attributedString) /// initialize a `Text`
    }
}
