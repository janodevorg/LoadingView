import OSLog

/// Set to true to disable all logging from LoadingView
public nonisolated(unsafe) var isLoggingDisabled = false

/**
 Usage:
 ```
 let log = LoggerFactory.coredata.logger()
 log.debug("A message")
 ```

 Be aware
 - You can only log or interpolate strings.
 - Wrap with String(describing:) if it’s not a string.
 - Use self on the interpolated variables when logging from inside a closure
 */
enum LoggerFactory: String {
    case loadingview

    /// Returns a Logger instance whose category is the classname.
    func logger(classname: String = #fileID) -> Logger {
        guard !isLoggingDisabled else {
            return Logger(.disabled)
        }
        let className = classname.components(separatedBy: ".")
            .last?.components(separatedBy: "/")
            .last?.replacingOccurrences(of: "swift", with: "")
            .trimmingCharacters(in: .punctuationCharacters) ?? ""
        return Logger(subsystem: rawValue, category: className)
    }
}
