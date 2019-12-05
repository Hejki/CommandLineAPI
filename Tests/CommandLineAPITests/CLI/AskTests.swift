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

final class AskTests: XCTestCase {
    private var ph: TestPromptHandler!

    override func setUp() {
        ph = TestPromptHandler()
    }

    func testAsk_simple() {
        ph.prepare("Y")

        let res = CLI.ask("Use it? ")
        XCTAssertEqual(self.ph.prints, ["Use it? "])
        XCTAssertEqual(res, "Y")
    }

    func testAsk_Int() {
        ph.prepare("34")

        let res = CLI.ask("? ", type: Int.self)
        XCTAssertEqual(self.ph.prints, ["? "])
        XCTAssertEqual(res, 34)
    }

    func testAsk_invalidType() {
        ph.prepare("a", "true")

        let res = CLI.ask("?", type: Bool.self)
        XCTAssertEqual(self.ph.prints, ["?", "Please enter a valid Bool.\n: "])
        XCTAssertEqual(res, true)
    }

    func testAsk_invalidBoolType() {
        ph.prepare("a", "false")

        let res = CLI.ask("?", type: Bool.self)
        XCTAssertEqual(self.ph.prints, ["?", "Please enter a valid Bool.\n: "])
        XCTAssertEqual(res, false)
    }

    func testAsk_validators() {
        ph.prepare("-3", "5.3", "1.1")

        let res: Double = CLI.ask("?", options:
            .validator("min\n: ") { $0 > 0 }, .validator("max: ") { $0 < 5 })

        XCTAssertEqual(self.ph.prints, ["?", "min\n: ", "max: "])
        XCTAssertEqual(res, 1.1)
    }

    func testAsk_confirmation() {
        ph.prepare("5.4", "n", "3.3", "y")

        let res = CLI.ask("?", type: Float.self, options: .confirm())

        XCTAssertEqual(self.ph.prints, ["?", "Are you sure? ", "?", "Are you sure? "])
        XCTAssertEqual(res, Float(3.3))
    }

    func testAsk_customConfirmation() {
        ph.prepare("5.4", "no", "3.3", "yes")

        let res = CLI.ask("?", type: Double.self, options: .confirm(block: { "Use \($0)? " }))

        XCTAssertEqual(self.ph.prints, ["?", "Use 5.4? ", "?", "Use 3.3? "])
        XCTAssertEqual(res, Double(3.3))
    }

    func testAsk_default() {
        ph.prepare("")

        let res = CLI.ask("?", options: .default("d"))
        XCTAssertEqual(self.ph.prints, ["?"])
        XCTAssertEqual(res, "d")
    }

    func testAsk_defaultAndConfirm() {
        ph.prepare("", "y")

        let res = CLI.ask("?", options: .default("d"), .confirm(message: "c"))
        XCTAssertEqual(self.ph.prints, ["?", "c"])
        XCTAssertEqual(res, "d")
    }

    func testAsk_notEmptyValidator() {
        ph.prepare("", "a")

        let res = CLI.ask("?", options: .notEmptyValidator("e"))
        XCTAssertEqual(self.ph.prints, ["?", "e"])
        XCTAssertEqual(res, "a")
    }

    func testAsk_rangeValidator() {
        ph.prepare("0", "5", "4")

        let res: Int = CLI.ask("?", options: .rangeValidator(1 ..< 5))
        XCTAssertEqual(self.ph.prints, ["?", "The entered value is not in range 1..<5!\n: ", "The entered value is not in range 1..<5!\n: "])
        XCTAssertEqual(res, 4)
    }

    func testPrintln() {
        CLI.print("p")
        CLI.println("println")
        CLI.print(error: "e")
        CLI.println(error: "err")

        XCTAssertEqual(self.ph.prints, ["p", "println\n", "ERR{e}", "ERR{err\n}"])
    }
}
