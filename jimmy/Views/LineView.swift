//
//  LineView.swift
//  jimmy
//
//  Created by Jonathan Foucher on 17/02/2022.
//

import SwiftUI

struct LineView: View, Hashable {
    
    var line: String
    var data: Data
    var type: String
    var tab: Tab
    
    var id: UUID
    
    @State var answer = ""
    
    init(data: Data, type: String, tab:Tab) {
        self.line = String(decoding: data, as: UTF8.self)
        self.data = data
        
        self.type = type
        self.id = UUID()
        self.tab = tab
    }
    var body: some View {
        textView
    }
    
    @ViewBuilder
    private var textView: some View {
        if type.starts(with: "text/gemini") {
            if self.line.starts(with: "=>") {
                LinkView(line: self.line, tab: tab).padding(.leading, 12)
            } else if line.starts(with: "* ") {
                Text(line.replacingOccurrences(of: "* ", with: "• "))
                    .fixedSize(horizontal: false, vertical: true)
                    .font(.system(size: tab.fontSize))
                    .lineSpacing(tab.fontSize * 0.5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 24)
                    .padding(.bottom, 8)
                    .padding(.top, 3)
            }  else if self.line.starts(with: "###") {
                Text(line.replacingOccurrences(of: "#", with: "").trimmingCharacters(in: .whitespacesAndNewlines))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.system(size: tab.fontSize*1.4, weight: .thin, design: .default))
                    .padding(.bottom, 5)
            } else if self.line.starts(with: "##") {
                Text(line.replacingOccurrences(of: "#", with: "").trimmingCharacters(in: .whitespacesAndNewlines))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.system(size: tab.fontSize*1.6, weight: .thin, design: .serif).italic())
                    .padding(.bottom, 5)
            } else if self.line.starts(with: "#") {
                Text(line.replacingOccurrences(of: "#", with: "").trimmingCharacters(in: .whitespacesAndNewlines))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .font(.system(size: tab.fontSize * 2, weight: .heavy, design: .serif))
                    .padding(.bottom, tab.fontSize)
                    .padding(.top, tab.fontSize)
            } else {
                Text(line)
                    .fixedSize(horizontal: false, vertical: true)
                    .font(.system(size: tab.fontSize))
                    .lineSpacing(tab.fontSize * 0.5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 5)
            }
        } else if type.starts(with: "text/pre") {
            Text(line)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 24)
                .font(.system(size: tab.fontSize * 1.1, weight: .light).monospaced())
                .fixedSize(horizontal: false, vertical: true)
        } else if type.starts(with: "text/answer") {
            // Line for an answer. The question should be above this
            HStack {
                TextField("Answer", text: $answer)
                    .onSubmit {
                        send()
                    }
                Button(action: send) {
                    Text("Send")
                }
            }
        }  else if type.starts(with: "image/") {
            // Line for an answer. The question should be above this
            if let img = NSImage(data: Data(self.data)) {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .layoutPriority(-1)
            } else {
                Image(systemName: "xmark")
            }
        } else {
            Text(line)
                .font(.system(size: tab.fontSize))
                .lineSpacing(tab.fontSize * 0.5)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 5)
                .padding(.leading, 12)
        }
    }
    
    func send () {
        if let url = URL(string: tab.url.absoluteString + "?" + answer) {
            tab.url = url
            tab.load()
        }
    }
    
    static func == (lhs: LineView, rhs: LineView) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}