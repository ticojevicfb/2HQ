//
//  PullToRefresh.swift
//  2HQ
//
//  Created by Nikola Ticojevic on 12. 1. 2026..
//

import SwiftUI

struct PullToRefresh: View {
    var coordinateSpace: CoordinateSpace
    @Binding var isRefreshing: Bool
    var onRefresh: () -> Void
    
    var body: some View {
        GeometryReader { geo in
            if geo.frame(in: coordinateSpace).midY > 50 {
                Spacer()
                    .onAppear {
                        if !isRefreshing {
                            isRefreshing = true
                            onRefresh()
                        }
                    }
            }
            
            HStack {
                Spacer()
                if isRefreshing {
                    ProgressView()
                        .scaleEffect(1.2)
                }
                Spacer()
            }
        }
        .padding(.top, -50)
    }
}
