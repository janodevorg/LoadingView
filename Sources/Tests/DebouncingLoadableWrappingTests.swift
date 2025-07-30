import Testing
@testable import LoadingView

@MainActor
final class MockTrackingLoadable: Loadable {
    var resetCalled = false
    var cancelCalled = false
    var loadCalled = false

    typealias Value = String

    var isCanceled = false
    var currentState: LoadingState<String> = .idle
    var state: any AsyncSequence<LoadingState<String>, Never> {
        AsyncStream { continuation in
            continuation.yield(.idle)
            continuation.finish()
        }
    }

    func reset() {
        resetCalled = true
        isCanceled = false
        currentState = .idle
    }

    func cancel() {
        cancelCalled = true
        isCanceled = true
    }

    func load() async {
        loadCalled = true
    }
}

@Suite
struct DebouncingLoadableWrappingTests {
    @Test
    @MainActor
    func testResetCallsWrappedReset() async {
        let mockLoadable = MockTrackingLoadable()
        let debouncer = await DebouncingLoadable(wrapping: mockLoadable)

        #expect(!mockLoadable.resetCalled)

        debouncer.reset()

        #expect(mockLoadable.resetCalled)
    }

    @Test
    @MainActor
    func testCancelCallsWrappedCancel() async {
        let mockLoadable = MockTrackingLoadable()
        let debouncer = await DebouncingLoadable(wrapping: mockLoadable)

        #expect(!mockLoadable.cancelCalled)

        debouncer.cancel()

        #expect(mockLoadable.cancelCalled)
    }
}