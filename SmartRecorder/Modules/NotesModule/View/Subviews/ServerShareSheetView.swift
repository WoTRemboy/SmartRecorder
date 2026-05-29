//
//  ServerShareSheetView.swift
//  SmartRecorder
//
//  Created by Roman Tverdokhleb on 29/05/2026.
//

import SwiftUI

struct ServerShareSheetView: View {
    @ObservedObject var detailsVM: RecordDetailsViewModel
    @Binding var isPresented: Bool

    internal var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                title
                description
                emailField
                shareButton
                errorMessage
                Divider()
                sharedUsersTitle
                sharedUsersSection
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .animation(.smooth(duration: 0.25), value: detailsVM.errorMessage)
            .animation(.smooth(duration: 0.3), value: detailsVM.sharedUsers)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    closeButton
                }
            }
        }
    }
    
    private var title: some View {
        Text(Texts.NotesPage.Sharing.title)
            .font(Font.subheadline())
    }

    private var description: some View {
        Text(Texts.NotesPage.Sharing.description)
            .font(Font.body())
            .foregroundStyle(Color.LabelColors.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var emailField: some View {
        TextField(Texts.NotesPage.Sharing.emailPlaceholder, text: $detailsVM.shareEmail)
            .textInputAutocapitalization(.never)
            .keyboardType(.emailAddress)
            .padding()
            .padding(.horizontal, 10)
            .glassEffect(.regular.tint(Color.BackgroundColors.primary).interactive())
    }

    private var shareButton: some View {
        Button {
            detailsVM.selectedRole = .viewer
            detailsVM.addShare()
        } label: {
            HStack {
                if detailsVM.isSharing {
                    ProgressView()
                        .transition(.scale.combined(with: .opacity))
                }
                Text(Texts.NotesPage.Sharing.add)
                    .font(Font.largeTitle3(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
            .frame(height: 46)
        }
        .buttonStyle(.glassProminent)
        .tint(Color.SupportColors.blue)
        .disabled(isShareDisabled)
        .animation(.easeInOut(duration: 0.2), value: isShareDisabled)
        .animation(.easeInOut(duration: 0.2), value: detailsVM.isSharing)
    }

    @ViewBuilder
    private var errorMessage: some View {
        if let error = detailsVM.errorMessage {
            Text(error)
                .font(.caption())
                .foregroundStyle(Color.SupportColors.red)
                .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    private var sharedUsersTitle: some View {
        Text(Texts.NotesPage.Sharing.sharedUsers)
            .font(.headline)
    }

    @ViewBuilder
    private var sharedUsersSection: some View {
        if detailsVM.sharedUsers.isEmpty {
            Text(Texts.NotesPage.Sharing.empty)
                .foregroundStyle(Color.LabelColors.secondary)
                .transition(.blurReplace)
        } else {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 10) {
                    ForEach(detailsVM.sharedUsers) { user in
                        sharedUserRow(user)
                    }
                }
            }
            .frame(maxHeight: 220)
            .transition(.blurReplace)
        }
    }

    private func sharedUserRow(_ user: SharedRecordUserResponse) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "person.crop.circle")
                .foregroundStyle(Color.SupportColors.blue)

            VStack(alignment: .leading, spacing: 2) {
                Text(user.fullName?.isEmpty == false ? user.fullName ?? user.email : user.email)
                    .lineLimit(1)
                Text(user.role.title)
                    .font(.caption())
                    .foregroundStyle(Color.LabelColors.secondary)
            }

            Spacer()

            Button(role: .destructive) {
                detailsVM.revokeAccess(for: user)
            } label: {
                Image(systemName: "trash")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.BackgroundColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .transition(.opacity.combined(with: .move(edge: .trailing)))
    }

    private var closeButton: some View {
        Button(Texts.NotesPage.Sharing.close) {
            isPresented = false
        }
        .font(Font.largeTitle3(.semibold))
    }

    private var isShareDisabled: Bool {
        detailsVM.shareEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || detailsVM.isSharing
    }
}

#Preview {
    ServerShareSheetView(
        detailsVM: RecordDetailsViewModel(recordId: nil),
        isPresented: .constant(true)
    )
}
