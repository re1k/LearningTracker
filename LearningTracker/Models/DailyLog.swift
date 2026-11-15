import Foundation
import SwiftData
// Data struct with ( day date + logged as Freeze/streak/Skipped? )


// Codable so model knows how to deal with it:SwiftData needs to know how to store custom types.
// it tells SwiftData how to save and retrieve the enum.
enum LogStatus:String, Codable {
    case freeze
    case streak
    case skip
}

// a var being static means the propery value belongs to the struct it self,
// not indivual to each struct instance which is wrong to use here

//final so class can not be subClassed

@Model
final class DailyLog {

    var dayDate: Date

    // Actual value stored in SwiftData, just like the duration
    var statusRawValue: String

    // Enum used by your Swift code
    var logStatus: LogStatus {
        get {
            LogStatus(rawValue: statusRawValue) ?? .skip
        }
        set {
            statusRawValue = newValue.rawValue
        }
    }

    init(dayDate: Date, logStatus: LogStatus) {
        self.dayDate = dayDate
        self.statusRawValue = logStatus.rawValue
    }
}
