//
//  JourneyAView.swift
//  PBD
//
//  Created by Ste on 29/08/2026.
//

import SwiftUI

struct JourneyAView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Journey A")
                .font(.largeTitle).bold()

            Text("The first journey in the flow.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .navigationTitle("Journey A")
        .frameworkPill()
    }
}
