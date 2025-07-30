import Testing
@testable import LoadingView

@Suite
struct LoadingProgressTests {
    @Test
    func testPercentValidation() {
        // Test normal range
        let progress1 = LoadingProgress(percent: 50)
        #expect(progress1.percent == 50)

        // Test clamping to 0
        let progress2 = LoadingProgress(percent: -10)
        #expect(progress2.percent == 0)

        // Test clamping to 100
        let progress3 = LoadingProgress(percent: 150)
        #expect(progress3.percent == 100)

        // Test boundary values
        let progress4 = LoadingProgress(percent: 0)
        #expect(progress4.percent == 0)

        let progress5 = LoadingProgress(percent: 100)
        #expect(progress5.percent == 100)

        // Test nil percent
        let progress6 = LoadingProgress(percent: nil)
        #expect(progress6.percent == nil)
    }
}