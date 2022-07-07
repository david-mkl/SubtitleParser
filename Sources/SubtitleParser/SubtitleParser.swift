import Foundation

/// A timestamp contains the hours, minutes, seconds, and milliseconds
/// for when a subtitle will be displayed
public struct Timestamp : CustomStringConvertible, Hashable {
    public let h: Int
    public let m: Int
    public let s: Int
    public let ms: Int
    
    public var description: String { get {
        let hStr = String(h).leftPadding(toLength: 2, withPad: "0")
        let mStr = String(m).leftPadding(toLength: 2, withPad: "0")
        let sStr = String(s).leftPadding(toLength: 2, withPad: "0")
        let msStr = String(ms).leftPadding(toLength: 3, withPad: "0")
        
        return "\(hStr):\(mStr):\(sStr),\(msStr)"
    }}
}

/// Represents a subtitle from a srt file
/// Contains an index indicating the order in which
/// the subtitles are to be shown, start and end timestamps for when
/// the subtitle is shown on the screen, and the actual caption content
public struct Subtitle : CustomStringConvertible, Hashable, Identifiable {
    public let id = UUID()
    public let index: Int
    public let start: Timestamp
    public let end: Timestamp
    public var caption: String
    
    public var description: String { get {
        return [
            String(index),
            "\(start.description) --> \(end.description)",
            caption,
            "", // Newline to separate from next sub
        ].joined(separator: "\n")
    }}
}

/// Error indicating the the srt file is not valid
public struct SRTParseError : Error, Equatable {
    let lineNumber: Int
    let reason: String
    
    func description() -> String {
        return "Failed to parse srt on line \(lineNumber): \(reason)"
    }
}

/// Reads a srt string into data structures
public struct SRTParser {
    public init() {
    }
    
    /// Converts a string from a .srt file into an array of Subtitle structs representing each subtitle
    public func parse(from text: String) throws -> [Subtitle] {
        var lineNumber = 1
        var subs: [Subtitle] = []
        
        for line in normalize(from: text).components(separatedBy: "\n\n") {
            // After normalization, there could be an empty final line in the file. If so, skip it
            if line == "" {
                continue
            }
            let (sub, lines) = try parseSubtitle(sub: line, line: lineNumber)
            subs.append(sub)
            lineNumber += lines
        }
                
        return subs
    }
    
    /// Converts subtitles back to a string
    public func parse(from subs: [Subtitle]) -> String {
        return subs.map { $0.description }.joined(separator: "\n")
    }
    
    /// This trims every line and rejoins with newlines.
    /// SRT captions are separated by an empty line, so the groups can be slipt by 2 newline characters. However,
    /// we don't know that the empty lines dont' contain whitespace. This normalizes the string to catch this edge case.
    private func normalize(from text: String) -> String {
        return text.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }.joined(separator: "\n")
    }
    
    private func parseSubtitle(sub: String, line: Int) throws -> (Subtitle, Int) {
        let subLines = sub.components(separatedBy: .newlines)
        
        guard let index = Int(subLines[0]) else {
            throw SRTParseError(lineNumber: line, reason: "Failed to parse index as an integer")
        }
        
        let (startTs, endTs) = try parseTimestamps(from: subLines[1], line: line + 1)
        let caption = subLines[2...].joined(separator: "\n")
        
        // 2 for the index and timestamps, plus the length of the caption, and 1 for the newline
        let nextLineNum = 2 + caption.count + 1
        
        return (Subtitle(index: index, start: startTs, end: endTs, caption: caption), nextLineNum)
    }
    
    private func parseTimestamps(from str: String, line: Int) throws -> (Timestamp, Timestamp) {
        let timestamps = str.components(separatedBy: " --> ")
              
        if timestamps.count != 2 {
            throw SRTParseError(lineNumber: line, reason: "Failed to parse start and end timestamps")
        }
        
        return (try parseTimestamp(from: timestamps[0], line: line), try parseTimestamp(from: timestamps[1], line: line))
    }
    
    /// Parses a string in the form of HH:SS:MM,sss to a Timestamp struct of hours, minutes, seconds, and milliseconds.
    /// Checks that each time value is valid. Hours, minutes, and seconds must be bewteen 0 - 59, while milliseconds must be between 0 - 999
    private func parseTimestamp(from str: String, line: Int) throws -> Timestamp {
        let timeMs = str.components(separatedBy: ",")
        if timeMs.count != 2 {
            throw SRTParseError(lineNumber: line, reason: "Failed to parse timestamp. Should be formatted like HH:MM:SS,sss")
        }
        
        let hms = timeMs[0].components(separatedBy: ":")
        if hms.count != 3 {
            throw SRTParseError(lineNumber: line, reason: "Failed to parse timestamp. Should be formatted like HH:MM:SS,sss")
        }
        
        let zeroToSixty = 0..<60
        let zeroToThousand = 0..<1000
        
        guard let h = Int(hms[0]), zeroToSixty ~= h else {
            throw SRTParseError(lineNumber: line, reason: "Hours should be integer between 0 - 59")
        }
                
        guard let m = Int(hms[1]), zeroToSixty ~= m else {
            throw SRTParseError(lineNumber: line, reason: "Minutes should be integer between 0 - 59")
        }
        
        guard let s = Int(hms[2]), zeroToSixty ~= s else {
            throw SRTParseError(lineNumber: line, reason: "Seconds should be integer between 0 - 59")
        }
              
        guard let ms = Int(timeMs[1]), zeroToThousand ~= ms else {
            throw SRTParseError(lineNumber: line, reason: "Milliseconds should be integer between 0 - 999")
        }

        return Timestamp(h: h, m: m, s: s, ms: ms)
    }
}
