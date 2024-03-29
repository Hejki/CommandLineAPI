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

final class PathOtherTests: XCTestCase {

    func testEqualAndHash() throws {
        try Path.temporary { dir in
            let a = try dir.createDirectory("a")
            let b = try Path(url: a.url)

            XCTAssertEqual(a, b)
            XCTAssertEqual(b, a)
            XCTAssertNotEqual(a, dir)
            XCTAssertEqual(a.hashValue, b.hashValue)
        }
    }

    func testComparable() {
        XCTAssertLessThan(Path.current.appending("a"), Path.current.appending("b"))
        XCTAssertGreaterThan(Path.current.appending("a/b"), Path.current.appending("a/a"))
    }

    func testBundle() throws {
        try Path.temporary { dir -> Void in
            guard let bundle = Bundle(path: dir.path) else {
                XCTFail("Couldn't make bundle for \(dir.path)")
                return
            }

            let filePath = try dir.touch("file.txt")
            let resPath: Path? = bundle.path(forResource: "file", withExtension: "txt")
            let nilPath: Path? = bundle.path(forResource: "nonexist", withExtension: "txt")

            XCTAssertEqual(bundle.path, dir)
            XCTAssertEqual(resPath, filePath)
            XCTAssertNil(nilPath)
        }
    }

    func testErrorDecriptions() throws {
        let e: [Path.Error] = [
            .cannotResolvePath("path"),
            .invalidURLScheme("http"),
            .invalidArgumentValue(arg: "arg", "description"),
        ]
        let msg = [
            "Cannot resolve path: 'path'",
            "URL scheme: 'http' is not supported. Only 'file' can be used.",
            "Invalid argument: 'arg' value. description",
        ]

        for (e, msg) in zip(e, msg) {
            XCTAssertEqual(e.localizedDescription, msg)
        }
    }

    func testEncodable() throws {
        let encoder = JSONEncoder()
        let obj = CodableStruct(path: Path.root.appending("/mypath/file.txt"))

        encoder.outputFormatting = [.prettyPrinted]

        let encoded = try encoder.encode(obj)
        XCTAssertEqual(String(data: encoded, encoding: .utf8), """
        {
          "path" : "\\/mypath\\/file.txt"
        }
        """)
    }

    func testCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let obj = CodableStruct(path: Path.root.appending("/mypath/file.txt"))

        let encoded = try encoder.encode(obj)
        let decoded = try decoder.decode(CodableStruct.self, from: encoded)
        XCTAssertEqual(decoded, obj)
    }

    func testDecodable() throws {
        let decoder = JSONDecoder()
        let json = "{\"path\":\"/mypath/file.txt\"}".data(using: .utf8)!

        let decoded = try decoder.decode(CodableStruct.self, from: json)
        XCTAssertEqual(decoded.path, Path.root.appending("mypath/file.txt"))
    }

    struct CodableStruct: Codable, Equatable {
        let path: Path
    }
}
