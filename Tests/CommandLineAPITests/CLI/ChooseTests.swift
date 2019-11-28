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

final class ChooseTests: XCTestCase {
    private var ph: TestPromptHandler!

    override func setUp() {
        ph = TestPromptHandler()
    }

    func testChoose() {
        ph.prepare("2")

        let res = CLI.choose("ch: ", choices: ["a", "b"])
        expect(self.ph.prints) == ["1) a\n", "2) b\n", "ch: "]
        expect(res) == "b"
    }

    func testChoose_map() {
        ph.prepare("1")

        let res = CLI.choose("ch: ", choices: ["a": 21, "b": 54])
        expect(self.ph.prints) == ["1) a\n", "2) b\n", "ch: "]
        expect(res) == 21
    }

    func testChoose_badInput() {
        ph.prepare("a", "4", "0", "1")

        let res = CLI.choose("ch: ", choices: ["a", "b"])
        expect(self.ph.prints) == [
            "1) a\n", "2) b\n", "ch: ",
            "invalid option\nch: ",
            "invalid option\nch: ",
            "invalid option\nch: ",
        ]
        expect(res) == "a"
    }

    func testChoose_noChoices() {
        #if canImport(Darwin)
        expect { _ = CLI.choose("", choices: []) }.to(throwAssertion())
        expect { _ = CLI.choose("", choices: [:]) }.to(throwAssertion())
        #endif
    }
}
