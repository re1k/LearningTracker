// Data struct with ( Goal + duration + freeze amount )
import SwiftData


// to be able to loop on it in ForEach
enum DurationOptions: Int, CaseIterable, Codable {
    case week = 7
    case month = 30
    case year = 365

    var title: String {
        switch self {
        case .week: "Week"
        case .month: "Month"
        case .year: "Year"
        }
    }
}

@Model
final class Target {
    var goal: String = ""
    var duration: Int
    var streakCounter: Int = 0
    var freezeCounter: Int = 0
    var freezeAmount: Int
    
    init(goal: String, duration: Int) {
        self.goal = goal
        self.duration = duration
        self.freezeAmount = switch duration {
             case 7: 2
             case 30: 8
             case 365: 96
             default: 0
             }
        
    }
}
