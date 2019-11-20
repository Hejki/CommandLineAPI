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
        run(
            "echo", "Hello",
            executor: .default,
            status: 0,
            stdout: "Hello\n",
            stderr: ""
        )

        run(
            "echo", "-n", "Hello",
            executor: .default,
            status: 0,
            stdout: "Hello",
            stderr: ""
        )

        run(
            "echo -n Hello World",
            executor: .default,
            status: 0,
            stdout: "Hello World",
            stderr: ""
        )

        expect(self.ph.prints) == []
    }

    func testDummyExecutor() {
        run(
            "echo", "Hello",
            executor: .dummy(),
            status: 0,
            stdout: "",
            stderr: ""
        )

        run(
            "dummy",
            executor: .dummy(status: 123, stdout: "out"),
            status: 123,
            stdout: "out",
            stderr: ""
        )

        expect(self.ph.prints) == ["Executed: echo Hello\n", "Executed: dummy\n"]
    }

    func testCWD() throws {
        try Path.createTemporaryDirectory { dir in
            try dir.appending("a").touch()
            try dir.appending("b").touch()

            let r1 = CLI.Command(["ls"], workingDirectory: dir).execute()
            let r2 = CLI.Command(["ls", "-a"], workingDirectory: dir).execute()

            expect(r1.exitCode) == 0
            expect(r1.stdout) == "a\nb\n"
            expect(r2.stdout) == ".\n..\na\nb\n"
        }
    }

    func testEnv() {
        let res = CLI.Command(
            ["printenv", "TEST_ENV_VAR"],
            environment: ["TEST_ENV_VAR": "varenv"]
        ).execute()

        expect(res.exitCode) == 0
        expect(res.stdout) == "varenv\n"
        expect(res.stderr) == ""
    }

    func testRunVarargs() {
        let res = CLI.run("echo", "-n", "b", executor: .interactive)

        expect(res.exitCode) == 0
        expect(res.stdout) == ""
        expect(res.stderr) == ""
    }

    private func run(_ cmd: String, _ args: String..., executor: CLI.CommandExecutor,
                     status: Int, stdout: String, stderr: String) {

        let result = CLI.run(cmd, args: args, executor: executor)

        expect(result.exitCode) == status
        expect(result.stdout) == stdout
        expect(result.stderr) == stderr
    }

    func testRun_pipe() {
        var result = CLI.run("echo -n", "Hi!").pipe(to: "base64")
        expect(result.exitCode) == 0
        expect(result.stdout) == "SGkh\n"
        expect(result.command.arguments) == ["base64"]

        result = CLI.run("echo -n", args: ["Hi!"])
            .pipe(to: "base64")
            .pipe(to: "base64", args: ["-D"])
        expect(result.exitCode) == 0
        expect(result.stdout) == "Hi!"
        expect(result.command.arguments) == ["base64", "-D"]

        result = CLI.run("echo", "Hi!\nHello\ntest").pipe(to: "grep", "H")
        expect(result.exitCode) == 0
        expect(result.stdout) == "Hi!\nHello\n"
        expect(result.stderr) == ""
        expect(result.command.arguments) == ["grep", "H"]

        result = CLI.run("a", executor: .dummy(status: 0, stdout: "o", stderr: "e"))
            .pipe(to: "b")
            .pipe(to: "c")
        expect(result.exitCode) == 0
        expect(result.stdout) == "o"
        expect(result.stderr) == "e"
        expect(result.command.arguments) == ["c"]
        expect(self.ph.prints) == ["Executed: a\n", "Executed: b\n", "Executed: c\n"]

        result = CLI.run("echo -n Hi!") | "base64" | ["base64", "-D"]
        expect(result.exitCode) == 0
        expect(result.stdout) == "Hi!"
        expect(result.command.arguments) == ["base64", "-D"]
    }

    func testRun_pipeFail() {
        let result = CLI.run("cmdNotExist").pipe(to: "echo Hi")
        expect(result.exitCode) == 127
        expect(result.command.arguments) == ["cmdNotExist"]

        expect {
            _ = CLI.run("ls", executor: .interactive).pipe(to: "echo")
        }.to(throwAssertion())
    }

    func testEcho() {
        let result = CLI.echo("YmFuYW5h") | "base64 -D"

        expect(result.exitCode) == 0
        expect(result.stdout) == "banana"
        expect(result.command.arguments) == ["base64", "-D"]
    }
}
