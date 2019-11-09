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
import Foundation
import Nimble

class TemporaryDirectory {
    let url: URL
    var path: Path { try! Path(url: url) }

    init() throws {
        let appropriate: URL
        if #available(OSX 10.12, *) {
            appropriate = FileManager.default.temporaryDirectory
        } else {
            appropriate = URL(fileURLWithPath: NSTemporaryDirectory())
        }

        url = try FileManager.default.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: appropriate, create: true)
    }

    deinit {
        try? path.delete()
    }
}

extension Path {

    static func createTemporaryDirectory<T>(_ body: (Path) throws -> T) throws -> T {
        let tmp = try TemporaryDirectory()
        return try body(tmp.path)
    }
}

class TestPromptHandler: PromptHandler {
    var prints: [String] = []
    var stringsForRead: [String] = []

    init() {
        CLI.prompt = self
    }

    func prepare(_ strings: String...) {
        stringsForRead = strings
    }

    func print(_ string: String) {
        prints.append(string)
    }

    func print(error string: String) {
        prints.append("ERR{\(string)}")
    }

    func read() -> String {
        return stringsForRead.removeFirst()
    }
}