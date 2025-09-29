//
//  LoginView.swift
//  Pantrify
//
//  Created by STUDENT on 9/23/25.
//

import Foundation
import SwiftData
import SwiftUI

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    enum LoginMethod: String, CaseIterable {
        case email = "Email"
        case username = "Username"
        case phone = "Phone"
    }
    
    @State private var selectedMethod: LoginMethod = .email
    @State private var identifier = ""
    @State private var password = ""
    @State private var error: String?
    
    let onLogin: (User) -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("Pantrify")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.pantrifyMint)
                    Text("Turn your pantry into meals")
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                Text("Welcome Back")
                    .font(.title)
                    .fontWeight(.semibold)

                Picker("Login Method", selection: $selectedMethod) {
                    ForEach(LoginMethod.allCases, id: \.self) { method in
                        Text(method.rawValue).tag(method)
                    }
                }
                .pickerStyle(.segmented)
                
                VStack(spacing: 16) {
                    TextField("Enter your \(selectedMethod.rawValue.lowercased())", text: $identifier)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .keyboardType(selectedMethod == .phone ? .phonePad : .default)
                    
                    SecureField("Enter your password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    if let error {
                        Text(error).foregroundColor(.red).font(.footnote)
                    }
                    
                    Button {
                        handleLogin()
                    } label: {
                        Text("Log In")
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(Color.pantrifyMint)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                
                Button("Forgot password?") {
                    error = "Password reset not implemented"
                }
                .font(.footnote)
                .foregroundColor(.pantrifyMint)
                
                HStack {
                    Text("Don’t have an account?")
                    Button("Sign up here") { dismiss() }
                        .foregroundColor(.pantrifyMint)
                }
                .font(.footnote)
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 24)
        }
    }
    
    private func handleLogin() {
        guard !identifier.isEmpty, !password.isEmpty else {
            error = "Please enter all fields"
            return
        }
        
        do {
            // 👇 Fetch fresh from DB every time
            let allUsers = try context.fetch(FetchDescriptor<User>())
            print("🔎 DB contains \(allUsers.count) user(s)")
            
            let user: User?
            switch selectedMethod {
            case .email:
                user = allUsers.first {
                    $0.email.lowercased() == identifier.lowercased() && $0.password == password
                }
            case .username:
                user = allUsers.first {
                    $0.username.lowercased() == identifier.lowercased() && $0.password == password
                }
            case .phone:
                user = allUsers.first {
                    $0.phoneNumber == identifier && $0.password == password
                }
            }
            
            guard let validUser = user else {
                error = "Invalid \(selectedMethod.rawValue.lowercased()) or password"
                print("❌ Login failed for \(identifier)")
                return
            }
            
            print("✅ Login success: \(validUser.email)")
            onLogin(validUser)
            dismiss()
            
        } catch {
            print("❌ Fetch error: \(error.localizedDescription)")
        }
    }
}
