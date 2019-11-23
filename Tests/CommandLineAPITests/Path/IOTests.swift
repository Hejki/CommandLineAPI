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

final class IOTests: XCTestCase {

    func testText() throws {
        try Path.temporary { dir in
            let file = dir.appending("data.txt")

            try file.write(text: "test\ntext")
            expect(try String(contentsOf: file)) == "test\ntext"

            try file.write(text: "append", append: true)
            expect(try String(contentsOf: file)) == "test\ntextappend"

            try file.write(text: "a")
            expect(try String(contentsOf: file)) == "a"
        }
    }

    func testData() throws {
        try Path.temporary { dir in
            let file = dir.appending("data")
            let file2 = dir.appending("data2")
            let data = Data(base64Encoded: "YQ==")!

            try data.write(to: file, append: true, atomically: true)
            expect(try String(contentsOf: file)) == "a"

            try file2.write(data: data, append: true)
            expect(try String(contentsOf: file2)) == "a"

            try file.write(data: data, append: true)
            expect(try String(contentsOf: file)) == "aa"

            try file.write(data: data)
            expect(try Data(contentsOf: file)) == data
        }
    }
}
