import OSLog
import SwiftUI

/**
 A generic view that observes and renders different loading states from any `Loadable` object.
 Use it to display loading, success, and failure states in your SwiftUI interface.

 Using it requires passing a loader and a success view. The idle, loading, and error states
 have a default view, but you can specify your own calling the following view modifiers:

 ```swift
 LoadingView(loader: someLoader) { value in
     List(value, id: \.self) { item in
         Text(item)
     }
 }
 .emptyView {
     Text("No data yet")
 }
 .progressView { progress in
     VStack {
         ProgressView()
         if let message = progress?.message {
             Text(message)
         }
     }
 }
 .errorView { error in
     Text("Error: \(error.localizedDescription)")
 }
 ```
 */
@MainActor
public struct LoadingView<L: Loadable & Sendable, Content: View>: View {
    private let log = Logger(subsystem: "loadingview", category: "LoadingView")

    /// Internal state to track the currently rendered `LoadingState`.
    @State private var loadingState: LoadingState<L.Value> = .idle

    /// Task used to observe state changes from the loader.
    @State private var task: Task<Void, Never>?

    // A reference to a external loader that provides data and publishes loading state.
    private var loader: L

    /// A closure that, given a successfully loaded value, produces the main content of this view.
    private var content: (L.Value) -> Content

    /// Controls whether `LoadingView` triggers its loader's `load()` method automatically on `onAppear`.
    /// Set to `false` if you want to call `load()` manually or if you handle loading outside this view.
    private let loadOnAppear: Bool

    /**
     Creates a new `LoadingView` for a given `Loadable` and a success-rendering closure.

     - Parameters:
       - loader: The loader object that fetches and publishes the data.
       - loadOnAppear: Whether to invoke `load()` automatically on `onAppear`. Defaults to `true`.
       - content: A view builder that renders the successfully loaded value.
     */
    public init(loader: L, loadOnAppear: Bool = true, @ViewBuilder content: @escaping (L.Value) -> Content) {
        self.loader = loader
        self.loadOnAppear = loadOnAppear
        self.content = content
    }

    // MARK: - Accessory views

    private var _emptyView: () -> any View = {
        Text("")
    }

    private var _progressView: (LoadingProgress?) -> any View = { progress in
        VStack {
            ProgressView()
            VStack {
                if let percent = progress?.percent {
                    Text("\(percent)%")
                }
                if let message = progress?.message {
                    Text(message)
                }
                if let isCancelled = progress?.isCanceled, isCancelled {
                    Text("Loading cancelled.")
                }
            }
        }
    }

    private var _errorView: (Error) -> any View = { error in
        Text(".Error: \(error.localizedDescription)")
            .accessibilityLabel(".An error occurred")
            .accessibilityValue(error.localizedDescription)
    }

    /**
     Provides a custom view for the `.idle` state of the loader.

     - Parameter view: A closure returning the desired SwiftUI view for idle state.
     - Returns: A new `LoadingView` with the custom empty view.
     */
    public func emptyView(@ViewBuilder _ view: @escaping () -> any View) -> Self {
        var copy: Self = self
        copy._emptyView = view
        return copy
    }

    /**
     Provides a custom view for the `.loading` state of the loader.

     - Parameter view: A closure returning the desired SwiftUI view for loading state, with optional progress info.
     - Returns: A new `LoadingView` with the custom progress view.
     */
    public func progressView(@ViewBuilder _ view: @escaping (LoadingProgress?) -> any View) -> Self {
        var copy: Self = self
        copy._progressView = view
        return copy
    }

    /**
     Provides a custom view for the `.failure` state of the loader.

     - Parameter view: A closure returning the desired SwiftUI view for error state.
     - Returns: A new `LoadingView` with the custom error view.
     */
    public func errorView(@ViewBuilder _ view: @escaping (Error) -> any View) -> Self {
        var copy: Self = self
        copy._errorView = view
        return copy
    }

    // MARK: - View

    /**
     The main body of the `LoadingView`.

     Displays one of:
     - The *empty* view for `.idle`
     - The *progress* view for `.loading`
     - The provided content closure for `.loaded`
     - The *error* view for `.failure`

     Also initiates a `Task` to receive state updates from the `loader`.
     */
    public var body: some View {
        Group {
            switch loadingState {
            case .idle:
                AnyView(_emptyView())
            case .loading(let progress):
                AnyView(_progressView(progress))
            case .loaded(let value):
                content(value)
            case .failure(let error):
                AnyView(_errorView(error))
            }
        }
        .task {
            task = Task {
                for await state in loader.state {
                    if case .loading(nil) = state {
                        // skip nil progress
                    } else {
                        log.debug("Changing state to: \(state)")
                        loadingState = state
                    }
                    if case .loading(let progress) = state, progress?.isCanceled == true {
                        loader.cancel()
                    }
                }
            }
        }
        .onAppear {
            if loadOnAppear {
                Task {
                    await load()
                }
            }
        }
        // .onDisappear {
        //     task.cancel()   <- Do NOT do this. The task contains the listening loop that updates state.
        //     loader.cancel() <- not worthy. most ops take a fraction of a second and we may as well use the result.
        // }
    }

    /*
     Asks the loader to begin (or restart) loading, depending on the current `loadingState`.

     The logic ensures that `.loading` is not triggered repeatedly while the loader is already
     in an active loading state.
     */
    private func load() async {
        switch loadingState {
        case .idle, .failure, .loaded:
            log.debug("Called loader.load()")
            loader.reset()
            await loader.load()
        default:
            log.debug("Called loader.load() but state is \(self.loadingState) so ignored")
        }
    }
}
