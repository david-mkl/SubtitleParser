import XCTest
@testable import SubtitleParser

final class SubtitleParserTests: XCTestCase {
    func testValidSRT() throws {
        let parser = SRTParser()
        let srtStr = "1\n00:01:01,111 --> 00:01:02,000\nCaption 1\n  \n2\n00:01:02,000 --> 00:01:03,000\nCaption 2 Line 1\nCaption 2 Line 2\n\n"
        let subs = try parser.parse(from: srtStr)
        
        let sub1 = subs[0]
        let sub2 = subs[1]
        
        XCTAssertEqual(subs.count, 2)
        
        XCTAssertEqual(sub1.index, 1)
        XCTAssertEqual(sub1.start.h, 0)
        XCTAssertEqual(sub1.start.m, 1)
        XCTAssertEqual(sub1.start.s, 1)
        XCTAssertEqual(sub1.start.ms, 111)
        XCTAssertEqual(sub1.end.h, 0)
        XCTAssertEqual(sub1.end.m, 1)
        XCTAssertEqual(sub1.end.s, 2)
        XCTAssertEqual(sub1.end.ms, 0)
        XCTAssertEqual(sub1.caption, "Caption 1")
        
        XCTAssertEqual(sub2.index, 2)
        XCTAssertEqual(sub2.start.h, 0)
        XCTAssertEqual(sub2.start.m, 1)
        XCTAssertEqual(sub2.start.s, 2)
        XCTAssertEqual(sub2.start.ms, 000)
        XCTAssertEqual(sub2.end.h, 0)
        XCTAssertEqual(sub2.end.m, 1)
        XCTAssertEqual(sub2.end.s, 3)
        XCTAssertEqual(sub2.end.ms, 0)
        XCTAssertEqual(sub2.caption, "Caption 2 Line 1\nCaption 2 Line 2")
    }
    
    func testInvalidIndex() throws {
        let parser = SRTParser()
        let srtStr = "foo\n00:01:01,111 --> 00:01:02,000\nCaption 1"
        var thrown: Error?
        
        XCTAssertThrowsError(try parser.parse(from: srtStr)) {
            thrown = $0
        }
        
        XCTAssertTrue(thrown is SRTParseError, "Unexpected error type: \(type(of: thrown))")
        
        let thrownSRTError = thrown as! SRTParseError
        XCTAssertEqual(thrownSRTError.lineNumber, 1)
        XCTAssertEqual(thrownSRTError.reason, "Failed to parse index as an integer")
    }
    
    func testInvalidTimestampFormat() throws {
        let parser = SRTParser()
        let srtStr = "1\n00:01:01,111 -> 00:01:02,000\nCaption 1"
        var thrown: Error?
        
        XCTAssertThrowsError(try parser.parse(from: srtStr)) {
            thrown = $0
        }
        
        XCTAssertTrue(thrown is SRTParseError, "Unexpected error type: \(type(of: thrown))")
        
        let thrownSRTError = thrown as! SRTParseError
        XCTAssertEqual(thrownSRTError.lineNumber, 2)
        XCTAssertEqual(thrownSRTError.reason, "Failed to parse start and end timestamps")
    }
    
    func testInvalidFormatInStartTimestamp() throws {
        let parser = SRTParser()
        let srtStr = "1\n00:00:01:111 --> 00:01:02,000\nCaption 1"
        var thrown: Error?
        
        XCTAssertThrowsError(try parser.parse(from: srtStr)) {
            thrown = $0
        }
        
        XCTAssertTrue(thrown is SRTParseError, "Unexpected error type: \(type(of: thrown))")
        
        let thrownSRTError = thrown as! SRTParseError
        XCTAssertEqual(thrownSRTError.lineNumber, 2)
        XCTAssertEqual(thrownSRTError.reason, "Failed to parse timestamp. Should be formatted like HH:MM:SS,sss")
    }
    
    func testInvalidValueTypeInStartTimestamp() throws {
        let parser = SRTParser()
        let srtStr = "1\n00:aa:01,111 --> 00:01:02,000\nCaption 1"
        var thrown: Error?
        
        XCTAssertThrowsError(try parser.parse(from: srtStr)) {
            thrown = $0
        }
        
        XCTAssertTrue(thrown is SRTParseError, "Unexpected error type: \(type(of: thrown))")
        
        let thrownSRTError = thrown as! SRTParseError
        XCTAssertEqual(thrownSRTError.lineNumber, 2)
        XCTAssertEqual(thrownSRTError.reason, "Minutes should be integer between 0 - 59")
    }
    
    func testInvalidHourRangeInStartTimestamp() throws {
        let parser = SRTParser()
        let srtStr = "1\n60:01:01,000 --> 00:01:02,000\nCaption 1"
        var thrown: Error?
        
        XCTAssertThrowsError(try parser.parse(from: srtStr)) {
            thrown = $0
        }
        
        XCTAssertTrue(thrown is SRTParseError, "Unexpected error type: \(type(of: thrown))")
        
        let thrownSRTError = thrown as! SRTParseError
        XCTAssertEqual(thrownSRTError.lineNumber, 2)
        XCTAssertEqual(thrownSRTError.reason, "Hours should be integer between 0 - 59")
    }
    
    func testInvalidMinutesRangeInStartTimestamp() throws {
        let parser = SRTParser()
        let srtStr = "1\n59:60:01,000 --> 00:01:02,000\nCaption 1"
        var thrown: Error?
        
        XCTAssertThrowsError(try parser.parse(from: srtStr)) {
            thrown = $0
        }
        
        XCTAssertTrue(thrown is SRTParseError, "Unexpected error type: \(type(of: thrown))")
        
        let thrownSRTError = thrown as! SRTParseError
        XCTAssertEqual(thrownSRTError.lineNumber, 2)
        XCTAssertEqual(thrownSRTError.reason, "Minutes should be integer between 0 - 59")
    }
    
    func testInvalidSecondsRangeInStartTimestamp() throws {
        let parser = SRTParser()
        let srtStr = "1\n59:59:60,000 --> 00:01:02,000\nCaption 1"
        var thrown: Error?
        
        XCTAssertThrowsError(try parser.parse(from: srtStr)) {
            thrown = $0
        }
        
        XCTAssertTrue(thrown is SRTParseError, "Unexpected error type: \(type(of: thrown))")
        
        let thrownSRTError = thrown as! SRTParseError
        XCTAssertEqual(thrownSRTError.lineNumber, 2)
        XCTAssertEqual(thrownSRTError.reason, "Seconds should be integer between 0 - 59")
    }
    
    func testInvalidMillisecondRangeInStartTimestamp() throws {
        let parser = SRTParser()
        let srtStr = "1\n00:01:01,1111 --> 00:01:02,000\nCaption 1"
        var thrown: Error?
        
        XCTAssertThrowsError(try parser.parse(from: srtStr)) {
            thrown = $0
        }
        
        XCTAssertTrue(thrown is SRTParseError, "Unexpected error type: \(type(of: thrown))")
        
        let thrownSRTError = thrown as! SRTParseError
        XCTAssertEqual(thrownSRTError.lineNumber, 2)
        XCTAssertEqual(thrownSRTError.reason, "Milliseconds should be integer between 0 - 999")
    }
    
    func testSubsToString() throws {
        let subs: [Subtitle] = [
            Subtitle(index: 1, start: Timestamp(h: 0, m: 1, s: 1, ms: 100), end: Timestamp(h: 0, m: 2, s: 2, ms: 200), caption: "Caption 1"),
            Subtitle(index: 2, start: Timestamp(h: 0, m: 3, s: 3, ms: 300), end: Timestamp(h: 0, m: 4, s: 4, ms: 400), caption: "Caption 2 Line 1\nCaption 2 Line 2"),
        ]
        
        let parser = SRTParser()
        let srtStr = parser.parse(from: subs)
        
        XCTAssertEqual(srtStr, "1\n00:01:01,100 --> 00:02:02,200\nCaption 1\n\n2\n00:03:03,300 --> 00:04:04,400\nCaption 2 Line 1\nCaption 2 Line 2\n")
    }
}
