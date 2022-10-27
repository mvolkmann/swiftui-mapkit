import Foundation // for Bundle
import os

// This is necessary to allow OSLogType values to be Dictionary keys.
extension OSLogType: Hashable {}

enum Log {
    // MARK: - Constants

    private static let typeToEmoji: [OSLogType: String] = [
        .debug: "🪲",
        .error: "❌",
        .fault: "☠️",
        .info: "🔎"
    ]

    private static let typeToName: [OSLogType: String] = [
        .debug: "debug",
        .error: "error",
        .fault: "fault",
        .info: "info"
    ]

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: ""
    )

    // MARK: - Methods

    private static func buildMessage(
        _ type: OSLogType,
        _ message: String,
        _ file: String,
        _ function: String,
        _ line: Int
    ) -> String {
        let fileName = file.components(separatedBy: "/").last ?? "unknown"
        let emoji = typeToEmoji[type] ?? ""
        let name = typeToName[type] ?? ""
        return """
        \(fileName) \(function) line \(line)
        \(emoji) \(name): \(message)
        """
    }

    static func debug(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let message = buildMessage(.debug, message, file, function, line)
        log(message: message, type: .debug)
    }

    static func error(
        _ err: Error,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let message = err.localizedDescription
        error(message, file: file, function: function, line: line)
    }

    static func error(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let message = buildMessage(.error, message, file, function, line)
        log(message: message, type: .error)
    }

    static func fault(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let message = buildMessage(.fault, message, file, function, line)
        log(message: message, type: .fault)
    }

    static func info(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let message = buildMessage(.info, message, file, function, line)
        log(message: message, type: .info)
    }

    /*
     This sets "privacy" to "public" to prevent values
     in string interpolations from being redacted.
     From https://developer.apple.com/documentation/os/logger
     "When you include an interpolated string or custom object in your message,
     the system redacts the value of that string or object by default.
     This behavior prevents the system from leaking potentially user-sensitive
     information in the log files, such as the user’s account information.
     If the data doesn’t contain sensitive information, change the
     privacy option of that value when logging the information."
     */
    private static func log(message: String, type: OSLogType) {
        switch type {
        case .debug:
            // The argument in each of the logger calls below
            // MUST be a string interpolation!
            logger.debug("\(message, privacy: .public)")
        case .error:
            logger.error("\(message, privacy: .public)")
        case .fault:
            logger.fault("\(message, privacy: .public)")
        case .info:
            logger.info("\(message, privacy: .public)")
        default:
            logger.log("\(message, privacy: .public)")
        }
    }
}

// This simplifies print statements that use string interpolation
// to print values with types like Bool.
// For example: print("isHavingFun = \(sd(isHavingFun))")
func sd(_ css: CustomStringConvertible) -> String {
    String(describing: css)
}
