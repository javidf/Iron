//
//  UnlockWithProOverlay.swift
//  Iron
//
//  Created by Karim Abou Zeid on 29.09.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct UnlockProOverlay: View {
    @EnvironmentObject var entitlementStore: EntitlementStore

    @State private var showingPurchaseSheet = false
    
    var body: some View {
        Button(action: {
            self.showingPurchaseSheet = true
        }) {
            HStack {
                Text("Unlock with Iron Pro").font(.headline)
                Image(systemName: "lock")
            }
            .padding()
        }
        .buttonStyle(BorderlessButtonStyle()) // otherwise the whole table view cell becomes selected
        .background(VisualEffectView(effect: UIBlurEffect(style: .regular)).cornerRadius(8))
        .sheet(isPresented: $showingPurchaseSheet) {
            PurchaseSheet().environmentObject(self.entitlementStore)
        }
    }
}

#if DEBUG
struct UnlockWithProOverlay_Previews: PreviewProvider {
    static var previews: some View {
        Color.gray.overlay(UnlockProOverlay())
            .environmentObject(EntitlementStore.mockNoPro)
    }
}
#endif