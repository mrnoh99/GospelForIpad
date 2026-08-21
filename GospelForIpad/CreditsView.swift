//
//  CreditsView.swift
//  GospelForIpad
//

import SwiftUI

struct CreditsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Image(systemName: "book.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.accentColor)

                    Text("복음서듣기")
                        .font(.title)
                        .fontWeight(.bold)
                }
                .padding(.vertical, 40)

                VStack(alignment: .center, spacing: 8) {
                    Text("by njs 2026")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)

                Spacer()

                VStack(alignment: .center, spacing: 4) {
                    Text("© 2026 All rights reserved")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(32)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.background.ignoresSafeArea())
            .navigationTitle("정보")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    CreditsView()
}
