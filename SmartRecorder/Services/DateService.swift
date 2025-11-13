import Foundation

struct DateService {
    
    static func formattedToday() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = .current
        return formatter.string(from: Date())
    }
}
