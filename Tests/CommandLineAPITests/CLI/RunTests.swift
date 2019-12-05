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

final class RunTests: XCTestCase {
    private var ph: TestPromptHandler!

    override func setUp() {
        ph = TestPromptHandler()
    }

    func testCurrentTaskRun() {
        XCTAssertEqual(try CLI.run("echo", "Hello", executor: .default), "Hello\n")
        XCTAssertEqual(try CLI.run("echo", "-n", "Hello"), "Hello")
        XCTAssertEqual(try CLI.run("echo -n Hello World"), "Hello World")
        XCTAssertEqual(self.ph.prints, [])
    }

    func testDummyExecutor() {
        XCTAssertEqual(try CLI.run("echo", "Hello", executor: .dummy()), "")
        XCTAssertEqual(try CLI.run("dummy", executor: .dummy(status: 0, stdout: "out")), "out")

        XCTAssertThrowsError(
            try CLI.run("d", executor: .dummy(status: 123, stdout: "o", stderr: "e")),
            "Expect error thrown.",
            expectError(123, "e", "o")
        )

        XCTAssertEqual(self.ph.prints, ["Executed: echo Hello\n", "Executed: dummy\n", "Executed: d\n"])
    }

    func testCWD() throws {
        try Path.temporary { dir in
            try dir.appending("a").touch()
            try dir.appending("b").touch()

            let r1 = try CLI.Command(["ls"], workingDirectory: dir.path).execute()
            let r2 = try CLI.Command(["ls", "-a"], workingDirectory: dir.path).execute()

            XCTAssertEqual(r1, "a\nb\n")
            XCTAssertEqual(r2, ".\n..\na\nb\n")
        }
    }

    func testEnv() throws {
        let res = try CLI.Command(
            ["printenv", "TEST_ENV_VAR"],
            environment: ["TEST_ENV_VAR": "varenv"]
        ).execute()

        XCTAssertEqual(res, "varenv\n")
    }

    func testRunVarargs() throws {
        let res = try CLI.run("echo", "-n", "b", executor: .interactive)

        XCTAssertEqual(res, "")
    }

    func testRun_pipe() throws {
        let result = try CLI.run("echo -n", "Hi! | base64")
        XCTAssertEqual(result, "SGkh\n")
    }

    func testRun_pipe2() throws {
        let result = try CLI.run("echo", "Hi!\nHello\ntest".quoted, "|", "grep H")
        XCTAssertEqual(result, "Hi!\nHello\n")
    }

    func testRun_pipeFail() throws {
        do {
            try CLI.run("cmdNotExist")
        } catch let error as CLI.CommandExecutionError {
            XCTAssertEqual(error.terminationStatus, 127)
            XCTAssertTrue(error.stderr.contains("command not found"))
            XCTAssertTrue(error.stderr.contains("cmdNotExist"))
            XCTAssertEqual(error.stdout, "")
        }
    }

    func testProcess_env() throws {
        CLI.processBuilder = CLI.Shell.env
        do {
            try CLI.run("swift", "--version")
        } catch let error as CLI.CommandExecutionError {
            XCTAssertEqual(error.terminationStatus, 127)
            XCTAssertTrue(error.stderr.contains("env"))
            XCTAssertTrue(error.stderr.contains("swift --version"))
            XCTAssertTrue(error.stderr.contains("No such file or directory"))
            XCTAssertEqual(error.stdout, "")
        }

        CLI.processBuilder = CLI.Shell.bash
        XCTAssertTrue(try CLI.run("swift --version").contains("Swift"))

        #if os(macOS)
        CLI.processBuilder = CLI.Shell.zsh
        XCTAssertTrue(try CLI.run("swift --version").contains("Swift"))
        #endif
    }

    func testRun_pipeInString() throws {
        try Path.temporary { tmp in
            try tmp.touch("ab")
            try tmp.touch("b")
            try tmp.touch("ba")

            let result = try CLI.Command(["ls | grep a | sort -r"], workingDirectory: tmp.path).execute()
            XCTAssertEqual(result, "ba\nab\n")
        }
    }

    private func expectError(_ status: Int, _ stderr: String, _ stdout: String) -> (Error) -> Void {
        return { error in
            if let err = error as? CLI.CommandExecutionError {
                XCTAssertEqual(err.terminationStatus, status)
                XCTAssertEqual(err.stderr, stderr)
                XCTAssertEqual(err.stdout, stdout)
            } else {
                XCTFail("Bad error thrown \(error)")
            }
        }
    }
}
