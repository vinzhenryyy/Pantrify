//
//  UserView.swift
//  Pantrify
//
//  Created by STUDENT on 9/23/25.
//

import Foundation
import SwiftData
import SwiftUI

struct ProfileView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    
    @Bindable var user: User
    let onLogout: () -> Void
        
    @State private var showImagePicker = false
    @State private var inputImage: UIImage?
    @State private var sessionStart: Date?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                HStack(spacing: 16) {
                    ZStack(alignment: .bottomTrailing) {
                        if let data = user.profileImageData,
                           let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(Circle())
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                                .foregroundColor(.gray.opacity(0.4))
                        }
                                        
                        Button {
                            showImagePicker = true
                        } label: {
                            Image(systemName: "pencil.circle.fill")
                                .foregroundColor(.pantrifyMint)
                                .background(Circle().fill(Color.white))
                        }
                        .offset(x: 4, y: 4)
                    }
                                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(user.firstName) \(user.lastName)")
                            .font(.headline)
                            .fontWeight(.semibold)
                                    
                        Text("@\(user.username)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                                        
                        Text("Member since \(formattedJoinDate(user.createdAt))")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
                )

                SectionCard(title: "Your Cooking Journey") {
                    HStack {
                        StatView(icon: "star.fill", value: "\(user.recipes.count)", label: "Recipes Saved")
                        StatView(icon: "fork.knife", value: "\(user.recipes.filter { $0.isCooked }.count)", label: "Recipes Cooked")
                        StatView(icon: "clock", value: "\(Int(user.hoursSpent))", label: "Hours Spent")
                    }
                }

                SectionCard(title: "Your Pantry") {
                    HStack {
                        StatView(icon: "cube.box.fill", value: "\(user.ingredients.count)", label: "Ingredients")
                        
                        // Just count unique ingredient IDs
                        StatView(
                            icon: "checkmark.seal.fill",
                            value: "\(Set(user.ingredients.map { $0.id }).count)",
                            label: "Ready to Cook"
                        )
                    }
                }
            
                SectionCard(title: "Settings") {
                    VStack(spacing: 12) {
                        NavigationLink(destination: AccountSettingsView(user: user)) {
                            SettingsRow(icon: "gear", text: "Account Settings")
                        }
                        NavigationLink(destination: HelpAndSupportView()) {
                            SettingsRow(icon: "questionmark.circle", text: "Help & Support")
                        }
                        Button {
                            onLogout()
                        } label: {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Log Out")
                                Spacer()
                            }
                            .foregroundColor(.red)
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 20)
        }
        .sheet(isPresented: $showImagePicker, onDismiss: saveProfileImage) {
            ImagePicker(image: $inputImage)
        }
        .onAppear {
            sessionStart = Date()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background || newPhase == .inactive {
                endSession()
            } else if newPhase == .active {
                sessionStart = Date()
            }
        }
    }
                
    private func saveProfileImage() {
        guard let inputImage else { return }
            user.profileImageData = inputImage.jpegData(compressionQuality: 0.8)
            try? context.save()
    }
                
    private func formattedJoinDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: date)
    }
    
    private func endSession() {
        guard let start = sessionStart else { return }
        let duration = Date().timeIntervalSince(start) / 3600
        user.hoursSpent += duration
        try? context.save()
        sessionStart = nil
    }
}

struct AccountSettingsView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var user: User
    
    @State private var darkMode = false
    @State private var language = "English"
    @State private var showPasswordSheet = false
    @State private var showDeleteAlert = false
    @State private var isEditing = false

    @State private var tempFirstName = ""
    @State private var tempLastName = ""
    @State private var tempUsername = ""
    @State private var tempEmail = ""
    @State private var tempPhoneNumber = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                VStack(alignment: .leading, spacing: 12) {
                    Text("Personal Information")
                        .font(.headline)
                        .padding(.bottom, 4)
                    
                    if isEditing {
                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("First Name")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                TextField("Enter first name", text: $tempFirstName)
                                    .textFieldStyle(.roundedBorder)
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Last Name")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                TextField("Enter last name", text: $tempLastName)
                                    .textFieldStyle(.roundedBorder)
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Username")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                TextField("Enter username", text: $tempUsername)
                                    .textFieldStyle(.roundedBorder)
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Email")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                TextField("Enter email", text: $tempEmail)
                                    .textFieldStyle(.roundedBorder)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Phone Number")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                TextField("Enter phone number", text: $tempPhoneNumber)
                                    .textFieldStyle(.roundedBorder)
                                    .keyboardType(.phonePad)
                            }
                            
                            // Action Buttons
                            HStack(spacing: 12) {
                                Button("Cancel") {
                                    isEditing = false
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.15))
                                .foregroundColor(.black)
                                .cornerRadius(8)
                                
                                Button("Save") {
                                    saveDetails()
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.pantrifyMint)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                        }

                    } else {
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundColor(.pantrifyMint)
                                Text("\(user.firstName) \(user.lastName)")
                                Spacer()
                            }
                            Divider()
                            
                            HStack {
                                Image(systemName: "at")
                                    .foregroundColor(.pantrifyMint)
                                Text(user.username)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            Divider()
                            
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(.pantrifyMint)
                                Text(user.email)
                                Spacer()
                            }
                            Divider()
                            
                            if ((user.phoneNumber?.isEmpty) == nil) {
                                HStack {
                                    Image(systemName: "phone.fill")
                                        .foregroundColor(.pantrifyMint)
                                    Text(user.phoneNumber ?? "")
                                    Spacer()
                                }
                            }
                            
                            Button("Edit Details") {
                                startEditing()
                            }
                            .font(.subheadline)
                            .foregroundColor(.pantrifyMint)
                            .padding(.top, 6)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
                )

                VStack(alignment: .leading, spacing: 12) {
                    Text("Security")
                        .font(.headline)
                    
                    Button {
                        showPasswordSheet = true
                    } label: {
                        HStack {
                            Label("Change Password", systemImage: "lock.fill")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Label("Delete Account", systemImage: "trash.fill")
                    }
                    .alert("Delete Account?", isPresented: $showDeleteAlert) {
                        Button("Cancel", role: .cancel) {}
                        Button("Delete", role: .destructive) {
                            context.delete(user)
                            try? context.save()
                            dismiss()
                        }
                    } message: {
                        Text("This action cannot be undone.")
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
                )

                VStack(alignment: .leading, spacing: 12) {
                    Text("Preferences")
                        .font(.headline)
                    
                    HStack {
                        Label("Language", systemImage: "globe")
                        Spacer()
                        Text(language)
                            .foregroundColor(.secondary)
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    
                    Toggle(isOn: $darkMode) {
                        Label("Dark Mode", systemImage: "moon.fill")
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
                )
                
                Spacer(minLength: 40)
            }
            .padding()
        }
        .navigationTitle("Account Settings")
        .sheet(isPresented: $showPasswordSheet) {
            ChangePasswordView(user: user)
        }
    }
    
    private func startEditing() {
        tempFirstName = user.firstName
        tempLastName = user.lastName
        tempUsername = user.username
        tempEmail = user.email
        tempPhoneNumber = user.phoneNumber ?? ""
        isEditing = true
    }
    
    private func saveDetails() {
        user.firstName = tempFirstName
        user.lastName = tempLastName
        user.username = tempUsername
        user.email = tempEmail
        user.phoneNumber = tempPhoneNumber
        try? context.save()
        isEditing = false
    }
}

struct ChangePasswordView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var user: User
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var error: String?
    
    var body: some View {
        NavigationView {
            Form {
                SecureField("New Password", text: $newPassword)
                SecureField("Confirm Password", text: $confirmPassword)
                
                if let error {
                    Text(error).foregroundColor(.red)
                }
                
                Button("Save") {
                    guard !newPassword.isEmpty else {
                        error = "Password cannot be empty"
                        return
                    }
                    guard newPassword == confirmPassword else {
                        error = "Passwords do not match"
                        return
                    }
                    user.password = newPassword
                    try? context.save()
                    dismiss()
                }
            }
            .navigationTitle("Change Password")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct HelpAndSupportView: View {
    @State private var subject = ""
    @State private var message = ""
    
    var body: some View {
        Form {
            Section(header: Text("Contact Support")) {
                TextField("Subject", text: $subject)
                TextField("Message", text: $message, axis: .vertical)
                    .lineLimit(4, reservesSpace: true)
                Button {
                    // send email logic
                } label: {
                    Label("Send Email", systemImage: "envelope.fill")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                }
                .listRowBackground(Color.pantrifyMint)
            }
            
            Section(header: Text("Other Ways to Reach Us")) {
                Label("Phone Support: 1-800-PANTRY-1", systemImage: "phone.fill")
            }
            
            Section(header: Text("App Information")) {
                Label("Version 1.1", systemImage: "info.circle.fill")
                Label("Last Updated Sept 23, 2025", systemImage: "calendar")
                Label("Build 2025.09.23.1", systemImage: "hammer.fill")
            }
        }
        .navigationTitle("Help & Support")
    }
}

struct SectionCard<Content: View>: View {
    let title: String
    let content: () -> Content
    
    init(title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            content()
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemBackground)).shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1))
    }
}

struct StatView: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(.pantrifyMint)
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.pantrifyMint)
            Text(label)
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct SettingsRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.pantrifyMint)
            Text(text)
                .foregroundColor(.black)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 6)
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    @Binding var image: UIImage?
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }
        
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.editedImage] as? UIImage ??
                info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.dismiss()
        }
    }
}
