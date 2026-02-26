import SwiftUI

/// First-launch onboarding screen to create the user profile.
struct SetupView: View {
    @ObservedObject var appViewModel: AppViewModel

    @State private var name = ""
    @State private var email = ""

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Logo
            VStack(spacing: 14) {
                Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.green)

                Text("Finance App")
                    .font(.largeTitle.bold())

                Text("Take control of your finances")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer().frame(height: 48)

            // Form
            VStack(spacing: 14) {
                TextField("Your Name", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.name)
                    .textInputAutocapitalization(.words)

                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, 36)

            Spacer().frame(height: 28)

            // CTA Button
            Button {
                appViewModel.createUser(
                    name: name.trimmingCharacters(in: .whitespaces),
                    email: email.trimmingCharacters(in: .whitespaces)
                )
            } label: {
                if appViewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    Text("Get Started")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
            .background(isValid ? Color.accentColor : Color.gray.opacity(0.3))
            .foregroundColor(.white)
            .cornerRadius(14)
            .padding(.horizontal, 36)
            .disabled(!isValid || appViewModel.isLoading)

            // Error message
            if let error = appViewModel.error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.top, 12)
                    .padding(.horizontal, 36)
            }

            Spacer()
        }
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !email.trimmingCharacters(in: .whitespaces).isEmpty
    }
}
