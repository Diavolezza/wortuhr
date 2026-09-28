import os

/// Diagnostic messages to the system log (visible via diag.sh or `log show`).
enum Log {
    static let logger = Logger(subsystem: "de.wanner-it.wortuhr", category: "saver")
    static func n(_ s: String) { logger.notice("\(s, privacy: .public)") }
}
