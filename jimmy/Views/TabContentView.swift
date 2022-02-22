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
        tabView
    }
    
    @ViewBuilder
    private var tabView: some View {
//        if tab.id == tabList.activeTabId {
            ZStack(alignment: .bottomLeading) {
                HStack {
                    ScrollView {
                        ForEach(tab.content, id: \.self) { view in
                            view
                                .frame(maxWidth: 800, alignment: .leading)
                                .id(view.id)
                        }
                        .padding(48)
                        .frame(minWidth: 200, maxWidth: .infinity, alignment: .center)
                    }
                    .textSelection(.enabled)
                    .frame(minWidth: 200, maxWidth: .infinity, alignment: .leading)
                }
                status
            }
            .background(Color.clear)
//        }
    }
    
    @ViewBuilder
    private var status: some View {
        if !tab.status.isEmpty {
            HStack {
                Text(tab.status)
                    .font(.system(size: 12, weight: .light))
                    .padding(.leading, 20)
                    .padding(.trailing, 12)
                    .padding(.bottom, 8)
                    .padding(.top, 2)
                    .opacity(0.5)
                    .background(Color("urlbackground").opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .padding(.leading, -12)
            .padding(.bottom, -4)
            
            
        }
    }
}

