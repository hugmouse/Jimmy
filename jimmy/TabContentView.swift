//
//  TabContentView.swift
//  jimmy
//
//  Created by Jonathan Foucher on 18/02/2022.
//

import SwiftUI

struct TabContentView: View {
    @EnvironmentObject private var tabList: TabList
    @ObservedObject var tab: Tab
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            tabView
            
            Text("")
                .background(Color.gray)
        }
    }
    
    @ViewBuilder
    private var tabView: some View {
        if tab.id == tabList.activeTabId {
            ScrollView {
                HStack {
                    Spacer()
                    VStack {
                        ForEach(tab.content, id: \.self) { view in
                            view.frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.leading, 8)
                        .padding(.trailing, 8)
                        .frame(minWidth: 200, maxWidth: .infinity, alignment: .leading)
                    }.padding(.bottom, 12).padding(.top, 12).frame(minWidth: 200, maxWidth: 800, alignment: .center)
                    Spacer()
                }
            }
            .frame(minWidth: 200, maxWidth: .infinity, minHeight: 200, alignment: .center)
            .background(Color.clear)
        }
    }
}

