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

final class StringStyleTests: XCTestCase {
    typealias Style = CLI.StringStyle

    func testEnrich() {
        expect(Style.fgRed.enrich("a")) == "\u{001B}[31ma\u{001B}[0m"

        let a = "a"
        expect("\(a, style: .bgGreen)\("b", style: .inverse)") == "\u{001B}[42ma\u{001B}[0m\u{001B}[7mb\u{001B}[0m"
    }

    func testArrayStyles() {
        var styles: [Style] = [.bgYellow, .fgWhite, .bold, .italic]

        expect(styles.enrich("str")) == """
        \u{001B}[43m\u{001B}[37m\u{001B}[1m\u{001B}[3mstr\u{001B}[0m
        """
        expect("\("str", style: .inverse, .bgWhite)") == """
        \u{001B}[7m\u{001B}[47mstr\u{001B}[0m
        """

        styles = []
        expect(styles.enrich("a")) == "a"
    }

    func testStringProtocolStyled() {
        expect("t".styled(.bgMagenta)) == "\u{001B}[45mt\u{001B}[0m"
        expect("t".styled(.fgYellow, .strikethrough)) == "\u{001B}[33m\u{001B}[9mt\u{001B}[0m"
    }

    func testInterpolation() {
        let i = 12
        let b = false
        let s = S()

        expect("\(i, style: .italic)") == "\u{001B}[3m12\u{001B}[0m"
        expect("\(b, style: .fgMagenta)") == "\u{001B}[35mfalse\u{001B}[0m"
        expect("\(s, style: .bgCyan)") == "\u{001B}[46ms\u{001B}[0m"
    }

    func testBright() {
        expect("t".styled(.bright(.bgBlack))) == "\u{001B}[40;1mt\u{001B}[0m"
        expect("t".styled(.bright(.fgBlack))) == "\u{001B}[30;1mt\u{001B}[0m"
        expect { _ = Style.bright(.strikethrough) }.to(throwAssertion())
        expect { _ = Style.bright(.fg(0)) }.to(throwAssertion())
    }

    func testCustomColor() {
        expect("t".styled(.fg(0))) == "\u{001B}[38;5;0mt\u{001B}[0m"
        expect("t".styled(.fg(255))) == "\u{001B}[38;5;255mt\u{001B}[0m"
        expect("t".styled(.fg(r: 0, g: 92, b: 255))) == "\u{001B}[38;2;0;92;255mt\u{001B}[0m"
        expect { _ = Style.fg(-1) }.to(throwAssertion())
        expect { _ = Style.fg(256) }.to(throwAssertion())

        expect("t".styled(.bg(0))) == "\u{001B}[48;5;0mt\u{001B}[0m"
        expect("t".styled(.bg(255))) == "\u{001B}[48;5;255mt\u{001B}[0m"
        expect("t".styled(.bg(r: 0, g: 64, b: 255))) == "\u{001B}[48;2;0;64;255mt\u{001B}[0m"
        expect { _ = Style.bg(-1) }.to(throwAssertion())
        expect { _ = Style.bg(256) }.to(throwAssertion())

        for i in [-1, 256] {
            expect { _ = Style.fg(r: i, g: 0, b: 0) }.to(throwAssertion())
            expect { _ = Style.fg(r: 0, g: i, b: 0) }.to(throwAssertion())
            expect { _ = Style.fg(r: 0, g: 0, b: i) }.to(throwAssertion())
            expect { _ = Style.bg(r: i, g: 0, b: 0) }.to(throwAssertion())
            expect { _ = Style.bg(r: 0, g: i, b: 0) }.to(throwAssertion())
            expect { _ = Style.bg(r: 0, g: 0, b: i) }.to(throwAssertion())
        }
    }

    private struct S: CustomStringConvertible {
        var description: String {
            "s"
        }
    }
}
