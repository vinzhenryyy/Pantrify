//
//  SignupView.swift
//  Pantrify
//
//  Created by STUDENT on 9/23/25.
//
import Foundation
import SwiftUI
import SwiftData

struct SignupView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var username = ""
    @State private var phoneNumber = ""
    @State private var dateOfBirth = Date()
    @State private var sex = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var agreeTerms = false
    @State private var subscribe = false
    @State private var error: String?
    
    let sexes = ["Male", "Female"]
    let onComplete: (User) -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text("Pantrify")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.pantrifyMint)
                    Text("Turn your pantry into meals")
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                Text("Create account")
                    .font(.title)
                    .fontWeight(.bold)
                Text("Join Pantrify today")
                    .foregroundColor(.secondary)

                // --- FORM ---
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("First Name").font(.footnote).foregroundColor(.secondary)
                            TextField("", text: $firstName)
                                .textFieldStyle(.roundedBorder)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Last Name").font(.footnote).foregroundColor(.secondary)
                            TextField("", text: $lastName)
                                .textFieldStyle(.roundedBorder)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Email").font(.footnote).foregroundColor(.secondary)
                        TextField("", text: $email)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Username").font(.footnote).foregroundColor(.secondary)
                        TextField("", text: $username)
                            .textFieldStyle(.roundedBorder)
                            .autocapitalization(.none)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Phone Number (Optional)").font(.footnote).foregroundColor(.secondary)
                        TextField("", text: $phoneNumber)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.phonePad)
                    }

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Date of Birth").font(.footnote).foregroundColor(.secondary)
                            DatePicker("", selection: $dateOfBirth, displayedComponents: .date)
                                .labelsHidden()
                                .datePickerStyle(.compact)
                                .frame(maxWidth: .infinity)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Sex")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                            Picker("Select sex", selection: $sex) {
                                ForEach(sexes, id: \.self) { g in
                                    Text(g).tag(g)
                                }
                            }
                            .pickerStyle(.segmented)
                            .frame(maxWidth: .infinity)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Password").font(.footnote).foregroundColor(.secondary)
                        SecureField("Create a strong password", text: $password)
                            .textFieldStyle(.roundedBorder)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Confirm Password").font(.footnote).foregroundColor(.secondary)
                        SecureField("Confirm your password", text: $confirmPassword)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                
                // --- ERROR MESSAGE ---
                if let error {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.footnote)
                }
                
                Toggle("I agree to the Terms of Service and Privacy Policy", isOn: $agreeTerms)
                    .font(.subheadline)
                    .fontWeight(.thin)
                Toggle("I’d like to receive updates about new features and recipes", isOn: $subscribe)
                    .font(.subheadline)
                    .fontWeight(.thin)
                
                Button {
                    handleSignup()
                } label: {
                    Text("Create Account")
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(Color.pantrifyMint)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(!agreeTerms)
                
                HStack {
                    Text("Already have an account?")
                    Button("Log in here") { dismiss() }
                        .foregroundColor(.pantrifyMint)
                }
                .font(.footnote)
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 24)
        }
    }
    
    // --- SIGNUP LOGIC ---
    private func handleSignup() {
        guard !firstName.isEmpty, !lastName.isEmpty, !email.isEmpty, !username.isEmpty else {
            error = "All required fields must be filled"
            return
        }
        guard password == confirmPassword else {
            error = "Passwords do not match"
            return
        }
        
        do {
            // 👇 Fetch fresh users to check duplicates
            let allUsers = try context.fetch(FetchDescriptor<User>())
            
            if allUsers.contains(where: { $0.email.lowercased() == email.lowercased() }) {
                error = "Email already exists"
                return
            }
            if allUsers.contains(where: { $0.username.lowercased() == username.lowercased() }) {
                error = "Username already exists"
                return
            }
            
            // Create user
            let newUser = User(
                firstName: firstName,
                lastName: lastName,
                email: email,
                username: username,
                phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber,
                dateOfBirth: dateOfBirth,
                sex: sex.isEmpty ? nil : sex,
                password: password
            )
            
            context.insert(newUser)
            try context.save()
            
            let afterSave = try context.fetch(FetchDescriptor<User>())
            print("✅ User saved: \(newUser.email). DB now has \(afterSave.count) users.")
            
            onComplete(newUser)
            dismiss()
            
        } catch {
            self.error = "Failed to save: \(error.localizedDescription)"
            print("❌ Save error:", error)
        }
    }
}
