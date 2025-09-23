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
                onStartTest: handleStartTest
            )

            loadingContainer

            Spacer()
        }
        .padding()
        .navigationTitle("Retry Demo")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    // MARK: - View Components

    @ViewBuilder
    private var loadingContainer: some View {
        VStack {
            if let loader = retryableLoader {
                LoadingView(loader: loader, loadOnAppear: false) { message in
                    log(.viewRendered(.success(message)))
                    return RetrySuccessView(message: message)
                }
                .progressView { progress in
                    log(.viewRendered(.progress(progress)))
                    return RetryProgressView(progress: progress)
                }
                .errorView { error in
                    log(.viewRendered(.error(error)))
                    return RetryErrorView(error: error, maxAttempts: maxAttempts)
                }
                .onAppear {
                    log(.viewAppeared(loader.currentState))
                }
                .task {
                    await observeStateChanges(loader)
                }
            } else {
                RetryPlaceholderView()
            }
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Actions

    private func handleStartTest() {
        logStartTest()

        if shouldCreateNewLoaders() {
            createNewLoaders()
        } else {
            resetExistingLoaders()
        }

        startLoadingTask()
    }

    private func shouldCreateNewLoaders() -> Bool {
        retryableLoader == nil ||
        maxAttempts != lastAppliedMaxAttempts ||
        successAfter != lastAppliedSuccessAfter
    }

    private func createNewLoaders() {
        print("🟢 Creating new loaders")
        baseLoader = FlakeyLoader(successAfterAttempts: successAfter)
        retryableLoader = RetryableLoader(wrapping: baseLoader!, maxAttempts: maxAttempts)
        lastAppliedMaxAttempts = maxAttempts
        lastAppliedSuccessAfter = successAfter
    }

    private func resetExistingLoaders() {
        print("🟡 Resetting existing loaders")
        baseLoader?.hardReset()
        retryableLoader?.reset()
    }

    private func startLoadingTask() {
        Task {
            print("🚀 Starting load task")
            if let loader = retryableLoader {
                print("  - Loader state before load: \(loader.currentState)")
                await loader.load()
                print("  - Loader state after load: \(loader.currentState)")
            } else {
                print("❌ ERROR: retryableLoader is nil after creation!")
            }
        }
    }

    // MARK: - Logging

    private func log(_ event: LogEvent) {
        print(event.message)
    }

    private func logStartTest() {
        log(.startTest)
        print("""
            - Current settings: maxAttempts=\(maxAttempts), successAfter=\(successAfter)
            - Last applied: maxAttempts=\(lastAppliedMaxAttempts ?? -1), successAfter=\(lastAppliedSuccessAfter ?? -1)
            - retryableLoader is \(retryableLoader == nil ? "nil" : "not nil")
        """)
    }

    // MARK: - State Observation

    private func observeStateChanges(_ loader: RetryableLoader<FlakeyLoader>) async {
        print("📊 Starting to observe loader state changes...")
        for await state in loader.state {
            log(.stateChange(state))
        }
        print("📊 State observation stream ended")
    }
}

private enum LogEvent {
    case startTest
    case stateChange(LoadingState<String>)
    case viewRendered(ViewType)
    case viewAppeared(LoadingState<String>)

    enum ViewType {
        case success(String)
        case progress(LoadingProgress?)
        case error(any Error)
    }

    var message: String {
        switch self {
        case .startTest:
            "🔵 RetryDemo: Start Test button clicked"
        case .stateChange(let state):
            Self.stateChangeMessage(for: state)
        case .viewRendered(let viewType):
            Self.viewRenderedMessage(for: viewType)
        case .viewAppeared(let state):
            "📱 LoadingView appeared with loader state: \(state)"
        }
    }

    private static func stateChangeMessage(for state: LoadingState<String>) -> String {
        switch state {
        case .idle:
            "📊 State: IDLE"
        case .loading(let progress):
            "📊 State: LOADING - \(progress?.message ?? "no message")"
        case .loaded(let value):
            "📊 State: SUCCESS - \(value)"
        case .failure(let error):
            "📊 State: FAILURE - \(error)"
        }
    }

    private static func viewRenderedMessage(for viewType: ViewType) -> String {
        switch viewType {
        case .success(let message):
            "🎉 SUCCESS VIEW RENDERED: \(message)"
        case .progress(let progress):
            "⏳ PROGRESS VIEW RENDERED: \(progress?.message ?? "no message")"
        case .error(let error):
            "❌ ERROR VIEW RENDERED: \(error)"
        }
    }
}
