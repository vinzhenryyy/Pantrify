//
//  Style.swift
//  Pantrify
//
//  Created by STUDENT on 8/28/25.
//

import Foundation
import SwiftUI

extension Color {
    static let mintySoft = Color(red: 0.86, green: 0.97, blue: 0.94)
    static let mintyDim  = Color(red: 0.20, green: 0.55, blue: 0.48)
    static let surface   = Color(.secondarySystemBackground)
    static let outline   = Color(.separator)
    static let pantrifyMint = Color(red: 52/255, green: 211/255, blue: 153/255)
}

struct MintCard<Content: View>: View {
    var title: String?
    var subtitle: String?
    var trailing: AnyView?
    @ViewBuilder var content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if title != nil || trailing != nil {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        if let title { Text(title).font(.headline) }
                        if let subtitle { Text(subtitle).font(.subheadline).foregroundStyle(.secondary) }
                    }
                    Spacer()
                    trailing
                }
            }
            content()
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.pantrifyMint.opacity(0.15), lineWidth: 1)
        )
    }
}

struct TagChip: View {
    let text: String
    var systemImage: String?
    var tint: Color = .pantrifyMint
    var filled: Bool = false
    var body: some View {
        HStack(spacing: 6) {
            if let systemImage { Image(systemName: systemImage) }
            Text(text).font(.footnote.weight(.semibold))
        }
        .padding(.vertical, 6).padding(.horizontal, 10)
        .background(filled ? tint.opacity(0.15) : tint.opacity(0.10), in: Capsule())
        .foregroundStyle(tint)
    }
}

struct MintButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(Color.pantrifyMint, in: Capsule())
            .foregroundStyle(.white)
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

