/*
 *  CommandLineAPI
 *
 *  Copyright (c) 2019 Hejki. Licensed under the MIT license, as follows:
 *
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the  Software), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in all
 *  copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED  AS IS, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *  SOFTWARE.
 */

@testable import CommandLineAPI
import XCTest

final class StringStyleTests: XCTestCase {
    typealias Style = CLI.StringStyle

    func testEnrich() {
        XCTAssertEqual(Style.fgRed.enrich("a"), "\u{001B}[31ma\u{001B}[0m")

        let a = "a"
        XCTAssertEqual("\(a, style: .bgGreen)\("b", style: .inverse)", "\u{001B}[42ma\u{001B}[0m\u{001B}[7mb\u{001B}[0m")
    }

    func testArrayStyles() {
        var styles: [Style] = [.bgYellow, .fgWhite, .bold, .italic]

        XCTAssertEqual(styles.enrich("str"), """
        \u{001B}[43m\u{001B}[37m\u{001B}[1m\u{001B}[3mstr\u{001B}[0m
        """)
        XCTAssertEqual("\("str", style: .inverse, .bgWhite)", """
        \u{001B}[7m\u{001B}[47mstr\u{001B}[0m
        """)

        styles = []
        XCTAssertEqual(styles.enrich("a"), "a")
    }

    func testStringProtocolStyled() {
        XCTAssertEqual("t".styled(.bgMagenta), "\u{001B}[45mt\u{001B}[0m")
        XCTAssertEqual("t".styled(.fgYellow, .strikethrough), "\u{001B}[33m\u{001B}[9mt\u{001B}[0m")
    }

    func testInterpolation() {
        let i = 12
        let b = false
        let s = S()

        XCTAssertEqual("\(i, style: .italic)", "\u{001B}[3m12\u{001B}[0m")
        XCTAssertEqual("\(b, style: .fgMagenta)", "\u{001B}[35mfalse\u{001B}[0m")
        XCTAssertEqual("\(s, style: .bgCyan)", "\u{001B}[46ms\u{001B}[0m")
    }

    func testBright() {
        XCTAssertEqual("t".styled(.bright(.bgBlack)), "\u{001B}[40;1mt\u{001B}[0m")
        XCTAssertEqual("t".styled(.bright(.fgBlack)), "\u{001B}[30;1mt\u{001B}[0m")
    }

    func testCustomColor() {
        XCTAssertEqual("t".styled(.fg(0)), "\u{001B}[38;5;0mt\u{001B}[0m")
        XCTAssertEqual("t".styled(.fg(255)), "\u{001B}[38;5;255mt\u{001B}[0m")
        XCTAssertEqual("t".styled(.fg(r: 0, g: 92, b: 255)), "\u{001B}[38;2;0;92;255mt\u{001B}[0m")

        XCTAssertEqual("t".styled(.bg(0)), "\u{001B}[48;5;0mt\u{001B}[0m")
        XCTAssertEqual("t".styled(.bg(255)), "\u{001B}[48;5;255mt\u{001B}[0m")
        XCTAssertEqual("t".styled(.bg(r: 0, g: 64, b: 255)), "\u{001B}[48;2;0;64;255mt\u{001B}[0m")
    }

    func testDisableStyles() {
        CLI.enableStringStyles = false
        defer {
            CLI.enableStringStyles = true
        }

        XCTAssertEqual(Style.bgWhite.enrich("e"), "e")
        XCTAssertEqual("t".styled(.fgRed), "t")
        XCTAssertEqual("\(12, style: .italic)", "12")

        let styles: [Style] = [.bgYellow, .fgWhite, .bold, .italic]
        XCTAssertEqual(styles.enrich("32"), "32")
    }

    private struct S: CustomStringConvertible {
        var description: String {
            "s"
        }
    }
}
