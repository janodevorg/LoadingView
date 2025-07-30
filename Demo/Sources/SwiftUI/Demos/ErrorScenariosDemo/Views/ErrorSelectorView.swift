import SwiftUI

struct ErrorSelectorView: View {
    @Binding var selectedError: ErrorType
    let onTriggerError: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Select an error type to simulate:")
                .font(.headline)

            Picker("Error Type", selection: $selectedError) {
                ForEach(ErrorType.allCases, id: \.self) { errorType in
                    Text(errorType.rawValue).tag(errorType)
                }
            }
            .pickerStyle(SegmentedPickerStyle())

            Button("Trigger Error", action: onTriggerError)
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }
}