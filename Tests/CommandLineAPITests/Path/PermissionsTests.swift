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

final class PermissionsTests: XCTestCase {

    let permissions: [(o: Int, s: String, p: Path.Permissions)] = [
        (0o000, "---------", []),
        (0o001, "--------x", [.othersExecute]),
        (0o002, "-------w-", [.othersWrite]),
        (0o003, "-------wx", [.othersExecute, .othersWrite]),
        (0o004, "------r--", [.othersRead]),
        (0o005, "------r-x", [.othersRead, .othersExecute]),
        (0o006, "------rw-", [.othersRead, .othersWrite]),
        (0o007, "------rwx", [.othersRead, .othersWrite, .othersExecute]),
        (0o010, "-----x---", [.groupExecute]),
        (0o020, "----w----", [.groupWrite]),
        (0o030, "----wx---", [.groupExecute, .groupWrite]),
        (0o040, "---r-----", [.groupRead]),
        (0o050, "---r-x---", [.groupRead, .groupExecute]),
        (0o060, "---rw----", [.groupRead, .groupWrite]),
        (0o070, "---rwx---", [.groupRead, .groupWrite, .groupExecute]),
        (0o100, "--x------", [.userExecute]),
        (0o200, "-w-------", [.userWrite]),
        (0o300, "-wx------", [.userExecute, .userWrite]),
        (0o400, "r--------", [.userRead]),
        (0o500, "r-x------", [.userRead, .userExecute]),
        (0o600, "rw-------", [.userRead, .userWrite]),
        (0o700, "rwx------", [.userRead, .userWrite, .userExecute]),
        (0o600, "rw-------", .userRW),
        (0o700, "rwx------", .userRWX),
        (0o644, "rw-r--r--", .userRW_allR),
        (0o711, "rwx--x--x", .userRWX_allX),
        (0o755, "rwxr-xr-x", .userRWX_allRX),
    ]

    func testPermissions() {
        for map in permissions {
            expect(map.o) == map.p.rawValue
            expect(String(map.o, radix: 8)) == map.p.octalString
            expect(map.s) == map.p.description
        }

        var perm = Path.Permissions.userRWX
        perm.remove(.userWrite)
        perm.insert(.groupRead)
        expect(perm.rawValue) == 0o540
        expect(perm.octalString) == "540"
        expect(perm.description) == "r-xr-----"
    }
}
