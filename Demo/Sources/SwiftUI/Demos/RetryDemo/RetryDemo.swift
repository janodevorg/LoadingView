import LoadingView
import SwiftUI

/// Demonstrates automatic retry functionality with configurable attempts for handling transient failures.
struct RetryDemo: View {
    @State private var baseLoader: FlakeyLoader?
    @State private var retryableLoader: RetryableLoader<FlakeyLoader>?
    @State private var maxAttempts = 5
    @State private var successAfter = 3
    @State private var lastAppliedMaxAttempts: Int?
    @State private var lastAppliedSuccessAfter: Int?

    var body: some View {
        VStack(spacing: 20) {
            RetryConfigurationView(
                maxAttempts: $maxAttempts,
                successAfter: $successAfter,
                onStartTest: {
                    print("🔵 RetryDemo: Start Test button clicked")
                    print("  - Current settings: maxAttempts=\(maxAttempts), successAfter=\(successAfter)")
                    print("  - Last applied: maxAttempts=\(lastAppliedMaxAttempts ?? -1), successAfter=\(lastAppliedSuccessAfter ?? -1)")
                    print("  - retryableLoader is \(retryableLoader == nil ? "nil" : "not nil")")

                    if retryableLoader == nil || maxAttempts != lastAppliedMaxAttempts || successAfter != lastAppliedSuccessAfter {
                        print("🟢 Creating new loaders")
                        baseLoader = FlakeyLoader(successAfterAttempts: successAfter)
                        retryableLoader = RetryableLoader(base: baseLoader!, maxAttempts: maxAttempts)
                        lastAppliedMaxAttempts = maxAttempts
                        lastAppliedSuccessAfter = successAfter
                    } else {
                        print("🟡 Resetting existing loaders")
                        baseLoader?.hardReset()
                        retryableLoader?.reset()
                    }

                    Task {
                        print("🚀 Starting load task")
                        if let loader = retryableLoader {
                            print("  - Loader state before load: \(loader.state)")
                            await loader.load()
                            print("  - Loader state after load: \(loader.state)")
                        } else {
                            print("❌ ERROR: retryableLoader is nil after creation!")
                        }
                    }
                }
            )

            // Fixed height container to prevent layout shift
            VStack {
                if let loader = retryableLoader {
                    LoadingView(loader: loader, loadOnAppear: false) { message in
                        print("🎉 SUCCESS VIEW RENDERED: \(message)")
                        return RetrySuccessView(message: message)
                    }
                    .progressView { progress in
                        print("⏳ PROGRESS VIEW RENDERED: \(progress?.message ?? "no message")")
                        return RetryProgressView(progress: progress)
                    }
                    .errorView { error in
                        print("❌ ERROR VIEW RENDERED: \(error)")
                        return RetryErrorView(error: error, maxAttempts: maxAttempts)
                    }
                    .onAppear {
                        print("📱 LoadingView appeared with loader state: \(loader.state)")
                    }
                    .task {
                        print("📊 Starting to observe loader state changes...")
                        for await state in loader.state {
                            switch state {
                            case .idle:
                                print("📊 State: IDLE")
                            case .loading(let progress):
                                print("📊 State: LOADING - \(progress?.message ?? "no message")")
                            case .loaded(let value):
                                print("📊 State: SUCCESS - \(value)")
                            case .failure(let error):
                                print("📊 State: FAILURE - \(error)")
                            }
                        }
                        print("📊 State observation stream ended")
                    }
                } else {
                    RetryPlaceholderView()
                }
            }
            .frame(height: 200)
            .frame(maxWidth: .infinity)

            Spacer()
        }
        .padding()
        .navigationTitle("Retry Demo")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}