import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Query private var usersRaw: [User]
    
    private var usersSorted: [User] { usersRaw.sorted { $0.createdAt < $1.createdAt } }
    @State private var currentUser: User? = nil
    @State private var showSignup = false
    @State private var didAutoSelectAtLaunch = false
    
    var body: some View {
        NavigationStack {
            if let user = currentUser {
                MainTabs(user: user, onLogout: { currentUser = nil })
            } else {
                LandingView(
                    login: LoginView(onLogin: { u in currentUser = u }), // ✅ pass directly
                    onSignup: { showSignup = true }
                )
                .navigationDestination(isPresented: $showSignup) {
                    SignupView { u in currentUser = u } // ✅ inherits modelContext
                }
                .toolbar(.hidden, for: .navigationBar)
            }
        }
        .onAppear {
            if !didAutoSelectAtLaunch, currentUser == nil, let u = usersRaw.first {
                currentUser = u
            }
            didAutoSelectAtLaunch = true
        }
    }
}

struct LandingView<LoginViewContent: View>: View { // ✅ generic over view type
    let login: LoginViewContent
    let onSignup: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            
            VStack(spacing: 8) {
                Text("Pantrify")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.pantrifyMint)
                Text("Turn your pantry into meals.")
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 16) {
                NavigationLink { login } label: {
                    Text("Log In")
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .font(.title3.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(.pantrifyMint)
                .padding(.horizontal)
                
                Button("Sign Up") {
                    onSignup()
                }
                .frame(maxWidth: .infinity, minHeight: 48)
                .font(.title3.weight(.semibold))
                .foregroundColor(.pantrifyMint)
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding(.horizontal)
    }
}
