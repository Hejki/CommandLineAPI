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
import Nimble
import XCTest

final class AskTests: XCTestCase {
    private var ph: TestPromptHandler!

    override func setUp() {
        ph = TestPromptHandler()
    }

    func testAsk_simple() {
        ph.prepare("Y")

        let res = CLI.ask("Use it? ")
        expect(self.ph.prints) == ["Use it? "]
        expect(res) == "Y"
    }

    func testAsk_Int() {
        ph.prepare("34")

        let res = CLI.ask("? ", type: Int.self)
        expect(self.ph.prints) == ["? "]
        expect(res) == 34
    }

    func testAsk_invalidType() {
        ph.prepare("a", "true")

        let res = CLI.ask("?", type: Bool.self)
        expect(self.ph.prints) == ["?", "Please enter a valid Bool.\n: "]
        expect(res) == true
    }

    func testAsk_invalidBoolType() {
        ph.prepare("a", "false")

        let res = CLI.ask("?", type: Bool.self)
        expect(self.ph.prints) == ["?", "Please enter a valid Bool.\n: "]
        expect(res) == false
    }

    func testAsk_validators() {
        ph.prepare("-3", "5.3", "1.1")

        let res: Double = CLI.ask("?", options:
            .validator("min") { $0 > 0 }, .validator("max") { $0 < 5 })

        expect(self.ph.prints) == ["?", "min\n: ", "max\n: "]
        expect(res) == 1.1
    }

    func testAsk_confirmation() {
        ph.prepare("5.4", "n", "3.3", "y")

        let res = CLI.ask("?", type: Float.self, options: .confirm())

        expect(self.ph.prints) == ["?", "Are you sure? ", "?", "Are you sure? "]
        expect(res) == Float(3.3)
    }

    func testAsk_customConfirmation() {
        ph.prepare("5.4", "no", "3.3", "yes")

        let res = CLI.ask("?", type: Double.self, options: .confirm(block: { "Use \($0)? " }))

        expect(self.ph.prints) == ["?", "Use 5.4? ", "?", "Use 3.3? "]
        expect(res) == Double(3.3)
    }

    func testAsk_default() {
        ph.prepare("")

        let res = CLI.ask("?", options: .default("d"))
        expect(self.ph.prints) == ["?"]
        expect(res) == "d"
    }

    func testAsk_defaultAndConfirm() {
        ph.prepare("", "y")

        let res = CLI.ask("?", options: .default("d"), .confirm(message: "c"))
        expect(self.ph.prints) == ["?", "c"]
        expect(res) == "d"
    }

    func testAsk_notEmptyValidator() {
        ph.prepare("", "a")

        let res = CLI.ask("?", options: .notEmptyValidator("e"))
        expect(self.ph.prints) == ["?", "e\n: "]
        expect(res) == "a"
    }

    func testAsk_rangeValidator() {
        ph.prepare("0", "5", "4")

        let res: Int = CLI.ask("?", options: .rangeValidator(1 ..< 5))
        expect(self.ph.prints) == ["?", "The entered value is not in range 1..<5!\n: ", "The entered value is not in range 1..<5!\n: "]
        expect(res) == 4
    }

    func testPrintln() {
        CLI.println("println")
        CLI.print(error: "e")
        CLI.println(error: "err")

        expect(self.ph.prints) == ["println\n", "ERR{e}", "ERR{err\n}"]
    }
}
