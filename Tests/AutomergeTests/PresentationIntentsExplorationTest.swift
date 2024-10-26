#if os(iOS) || os(macOS) || os(tvOS) || os(watchOS)
import Foundation
import SwiftUI
import XCTest

#if swift(>=5.9)
@available(macOS 12, iOS 15, *)
class PresentationIntentsExplorationTest: XCTestCase {
    func testDescribeExistingBlockPresentationIntents() throws {
        let foundation_presentation_types = [
            PresentationIntent.Kind.blockQuote,
            PresentationIntent.Kind.codeBlock(languageHint: "swift"),
            PresentationIntent.Kind.header(level: 1),
            PresentationIntent.Kind.listItem(ordinal: 1),
            PresentationIntent.Kind.orderedList,
            PresentationIntent.Kind.paragraph,
            PresentationIntent.Kind.table(
                columns:
                [
                    PresentationIntent.TableColumn(alignment: .left),
                    PresentationIntent.TableColumn(alignment: .center),
                    PresentationIntent.TableColumn(alignment: .right),
                ]
            ),
            PresentationIntent.Kind.tableCell(columnIndex: 1),
            PresentationIntent.Kind.tableHeaderRow,
            PresentationIntent.Kind.tableRow(rowIndex: 1),
            PresentationIntent.Kind.thematicBreak,
            PresentationIntent.Kind.unorderedList,
        ]
        let encoder = JSONEncoder()
        for type in foundation_presentation_types {
            let encoded = try encoder.encode(type)
            print("type: \(type.debugDescription) JSONencoded: \(String(data: encoded, encoding: .utf8) ?? "??")")
        }

        /*
         type: codeBlock 'swift' JSONencoded: ["codeBlock","swift"]
         type: header 1 JSONencoded: ["header",1]
         type: listItem 1 JSONencoded: ["listItem",1]
         type: orderedList JSONencoded: ["orderedList"]
         type: paragraph JSONencoded: ["paragraph"]
         type: table [Foundation.PresentationIntent.TableColumn(alignment: Foundation.PresentationIntent.TableColumn.Alignment.left), Foundation.PresentationIntent.TableColumn(alignment: Foundation.PresentationIntent.TableColumn.Alignment.center), Foundation.PresentationIntent.TableColumn(alignment: Foundation.PresentationIntent.TableColumn.Alignment.right)] JSONencoded: ["table",[{"alignment":0},{"alignment":1},{"alignment":2}]]
         type: tableCell 1 JSONencoded: ["tableCell",1]
         type: tableHeaderRow JSONencoded: ["tableHeaderRow"]
         type: tableRow 1 JSONencoded: ["tableRow",1]
         type: thematicBreak JSONencoded: ["thematicBreak"]
         type: unorderedList JSONencoded: ["unorderedList"]
         */
    }

    func testDescribeExistingInlinePresentationIntents() throws {
        let inline_intents = [
            "blockHTML":
                InlinePresentationIntent.blockHTML,
            "code": InlinePresentationIntent.code,
            "emphasized": InlinePresentationIntent.emphasized,
            "inlineHTML": InlinePresentationIntent.inlineHTML,
            "lineBreak": InlinePresentationIntent.lineBreak,
            "softBreak": InlinePresentationIntent.softBreak,
            "strikethrough": InlinePresentationIntent.strikethrough,
            "stronglyEmphasized": InlinePresentationIntent.stronglyEmphasized,
        ]
        print("Inline Presentation Types")
        print("Types are represented as an OptionSet (meaning any or none of them encoded into a single value).")
        for (name, type) in inline_intents {
            print("type: \(name) rawValue: \(type.rawValue)")
        }

        /*
         type: strikethrough rawValue: 32
         type: stronglyEmphasized rawValue: 2
         type: softBreak rawValue: 64
         type: lineBreak rawValue: 128
         type: emphasized rawValue: 1
         type: blockHTML rawValue: 512
         type: inlineHTML rawValue: 256
         type: code rawValue: 4
         */
    }

    func testDescribeExistingSwiftUIAttributes() throws {
        // each type of attribute that conforms to CodableAttributedStringKey (which is most of the built-in ones)
        // includes a .name property on the attribute, as well as a Value type

        print("SwiftUI Presentation Attributes")
        print("attributes are individual (not an optionset) encoded as structs with values")
        print(
            "FontAttribute: \(AttributeScopes.SwiftUIAttributes.FontAttribute.name), data: \(String(describing: AttributeScopes.SwiftUIAttributes.FontAttribute.Value.self))"
        )

        print(
            "ForegroundColorAttribute: \(AttributeScopes.SwiftUIAttributes.ForegroundColorAttribute.name), data: \(String(describing: AttributeScopes.SwiftUIAttributes.ForegroundColorAttribute.Value.self))"
        )

        print(
            "BackgroundColorAttributes: \(AttributeScopes.SwiftUIAttributes.BackgroundColorAttribute.name), data: \(String(describing: AttributeScopes.SwiftUIAttributes.BackgroundColorAttribute.Value.self))"
        )

        print(
            "StrikethroughStyleAttribute: \(AttributeScopes.SwiftUIAttributes.StrikethroughStyleAttribute.name), data: \(String(describing: AttributeScopes.SwiftUIAttributes.StrikethroughStyleAttribute.Value.self))"
        )

        print(
            "UnderlineStyleAttribute: \(AttributeScopes.SwiftUIAttributes.UnderlineStyleAttribute.name), data: \(String(describing: AttributeScopes.SwiftUIAttributes.UnderlineStyleAttribute.Value.self))"
        )

        print(
            "KerningAttribute: \(AttributeScopes.SwiftUIAttributes.KerningAttribute.name), data: \(String(describing: AttributeScopes.SwiftUIAttributes.KerningAttribute.Value.self))"
        )

        print(
            "TrackingAttribute: \(AttributeScopes.SwiftUIAttributes.TrackingAttribute.name), data: \(String(describing: AttributeScopes.SwiftUIAttributes.TrackingAttribute.Value.self))"
        )

        print(
            "BaselineOffsetAttribute: \(AttributeScopes.SwiftUIAttributes.BaselineOffsetAttribute.name), data: \(String(describing: AttributeScopes.SwiftUIAttributes.BaselineOffsetAttribute.Value.self))"
        )

        print(
            "KerningAttribute: \(AttributeScopes.SwiftUIAttributes.KerningAttribute.name), data: \(String(describing: AttributeScopes.SwiftUIAttributes.KerningAttribute.Value.self))"
        )

        print(
            "KerningAttribute: \(AttributeScopes.SwiftUIAttributes.KerningAttribute.name), data: \(String(describing: AttributeScopes.SwiftUIAttributes.KerningAttribute.Value.self))"
        )

        // Note: Text.LineStyle, Color, and Font are not publicly "codable"

        // runtime to check prevent Xcode from hitting this section of the test in earlier OS versions
        if #available(macOS 14, iOS 17, *) {
            let encoder = JSONEncoder()

            // ForegroundColor
            var colorExample = AttributedString("color example")
            var container = AttributeContainer()
            container[AttributeScopes.SwiftUIAttributes.ForegroundColorAttribute.self] = .red
            colorExample.mergeAttributes(container, mergePolicy: .keepNew)

            var encoded = try encoder.encode(
                colorExample,
                configuration: SwiftUI.AttributeScopes.SwiftUIAttributes.encodingConfiguration
            )
            print("instance: \(colorExample) JSONEncoded: \(String(data: encoded, encoding: .utf8) ?? "??")")

            // BackgroundColor
            var backgroundColorExample = AttributedString("background color example")
            backgroundColorExample.backgroundColor = .green
            encoded = try encoder.encode(
                backgroundColorExample,
                configuration: SwiftUI.AttributeScopes.SwiftUIAttributes.encodingConfiguration
            )
            print("instance: \(backgroundColorExample) JSONEncoded: \(String(data: encoded, encoding: .utf8) ?? "??")")

            // UnderlineStyle
            var underlineExample = AttributedString("underline example")
            underlineExample.underlineStyle = .patternDashDotDot
            underlineExample.underlineColor = .blue
            encoded = try encoder.encode(
                underlineExample,
                configuration: SwiftUI.AttributeScopes.SwiftUIAttributes.encodingConfiguration
            )
            print("instance: \(underlineExample) JSONEncoded: \(String(data: encoded, encoding: .utf8) ?? "??")")

            // Font
            var fontExample = AttributedString("font example")
            fontExample.font = Font(CTFont(.system, size: 24))
            encoded = try encoder.encode(
                fontExample,
                configuration: SwiftUI.AttributeScopes.SwiftUIAttributes.encodingConfiguration
            )
            print("instance: \(fontExample) JSONEncoded: \(String(data: encoded, encoding: .utf8) ?? "??")")

            /*
             FontAttribute: SwiftUI.Font, data: Font
             ForegroundColorAttribute: SwiftUI.ForegroundColor, data: Color
             BackgroundColorAttributes: SwiftUI.BackgroundColor, data: Color
             StrikethroughStyleAttribute: SwiftUI.StrikethroughStyle, data: LineStyle
             UnderlineStyleAttribute: SwiftUI.UnderlineStyle, data: LineStyle
             KerningAttribute: SwiftUI.Kern, data: CGFloat
             TrackingAttribute: SwiftUI.Tracking, data: CGFloat
             BaselineOffsetAttribute: SwiftUI.BaselineOffset, data: CGFloat
             KerningAttribute: SwiftUI.Kern, data: CGFloat
             KerningAttribute: SwiftUI.Kern, data: CGFloat

             instance: color example {
             SwiftUI.ForegroundColor = red
             } JSONEncoded: ["color example",{}]

             instance: background color example {
             SwiftUI.BackgroundColor = green
             } JSONEncoded: ["background color example",{}]

             instance: underline example {
             NSUnderlineColor = UIExtendedSRGBColorSpace 0 0 1 1
             NSUnderline = NSUnderlineStyle(rawValue: 1024)
             } JSONEncoded: ["underline example",{}]

             instance: font example {
             SwiftUI.Font = Font(provider: SwiftUI.(unknown context at $1122b9930).FontBox<SwiftUI.Font.(unknown context at $1123125e0).PlatformFontProvider>)
             } JSONEncoded: ["font example",{}]
             */
        }
    }
}
#endif
#endif
