//
//  ConnectionStatusView.swift
//  MQTTChat
//
//  Created by Vincent Joy on 08/08/25.
//

import SwiftUI

struct ConnectionStatusView: View {
    let state: ConnectionState
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color(state.color))
                .frame(width: 8, height: 8)
            
            Text(state.rawValue)
                .font(.caption)
                .fontWeight(.medium)
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(UIColor.systemGray6))
        .cornerRadius(8)
    }
}
