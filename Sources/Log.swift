import os

/// Diagnose-Ausgaben ins Systemprotokoll (sichtbar mit diag.sh bzw. `log show`).
enum Log {
    static let logger = Logger(subsystem: "de.wanner-it.wortuhr", category: "saver")
    static func n(_ s: String) { logger.notice("\(s, privacy: .public)") }
}
