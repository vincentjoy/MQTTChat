//
//  SettingsView+Previews.swift
//  MQTTChat
//
//  Created by Vincent Joy on 08/08/25.
//

import SwiftUI

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(SettingsViewModel(mqttService: MQTTService()))
    }
}
#endif
