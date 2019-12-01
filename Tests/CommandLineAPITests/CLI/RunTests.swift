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

final class RunTests: XCTestCase {
    private var ph: TestPromptHandler!

    override func setUp() {
        ph = TestPromptHandler()
    }

    func testCurrentTaskRun() {
        expect(try CLI.run("echo", "Hello", executor: .default)) == "Hello\n"
        expect(try CLI.run("echo", "-n", "Hello")) == "Hello"
        expect(try CLI.run("echo -n Hello World")) == "Hello World"
        expect(self.ph.prints) == []
    }

    func testDummyExecutor() {
        expect(try CLI.run("echo", "Hello", executor: .dummy())) == ""
        expect(try CLI.run("dummy", executor: .dummy(status: 0, stdout: "out"))) == "out"

        expect(try CLI.run("d", executor: .dummy(status: 123, stdout: "o", stderr: "e")))
            .to(throwError(CLI.CommandExecutionError(terminationStatus: 123, stderr: "e", stdout: "o")))

        expect(self.ph.prints) == ["Executed: echo Hello\n", "Executed: dummy\n", "Executed: d\n"]
    }

    func testCWD() throws {
        try Path.temporary { dir in
            try dir.appending("a").touch()
            try dir.appending("b").touch()

            let r1 = try CLI.Command(["ls"], workingDirectory: dir.path).execute()
            let r2 = try CLI.Command(["ls", "-a"], workingDirectory: dir.path).execute()

            expect(r1) == "a\nb\n"
            expect(r2) == ".\n..\na\nb\n"
        }
    }

    func testEnv() throws {
        let res = try CLI.Command(
            ["printenv", "TEST_ENV_VAR"],
            environment: ["TEST_ENV_VAR": "varenv"]
        ).execute()

        expect(res) == "varenv\n"
    }

    func testRunVarargs() throws {
        let res = try CLI.run("echo", "-n", "b", executor: .interactive)

        expect(res) == ""
    }

    func testRun_pipe() throws {
        let result = try CLI.run("echo -n", "Hi! | base64")
        expect(result) == "SGkh\n"
    }

    func testRun_pipe2() throws {
        let result = try CLI.run("echo", "Hi!\nHello\ntest".quoted, "|", "grep H")
        expect(result) == "Hi!\nHello\n"
    }

    func testRun_pipeFail() throws {
        expect(try CLI.run("cmdNotExist")).to(
            throwError(CLI.CommandExecutionError(terminationStatus: 127, stderr: "", stdout: "")))
    }

    func testProcess_env() throws {
        CLI.processBuilder = CLI.Shell.env
        do {
            try CLI.run("swift", "--version")
        } catch let error as CLI.CommandExecutionError {
            expect(error.terminationStatus) == 127
            expect(error.stderr).to(contain("env", "swift --version", "No such file or directory"))
            expect(error.stdout) == ""
        }

        CLI.processBuilder = CLI.Shell.bash
        expect(try CLI.run("swift --version")).to(contain("Swift"))

        #if os(macOS)
        CLI.processBuilder = CLI.Shell.zsh
        expect(try CLI.run("swift --version")).to(contain("Swift"))
        #endif
    }

    func testRun_pipeInString() throws {
        try Path.temporary { tmp in
            try tmp.touch("ab")
            try tmp.touch("b")
            try tmp.touch("ba")

            let result = try CLI.Command(["ls | grep a | sort -r"], workingDirectory: tmp.path).execute()
            expect(result) == "ba\nab\n"
        }
    }
}
