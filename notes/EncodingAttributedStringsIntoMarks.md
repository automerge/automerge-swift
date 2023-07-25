# Encoding Attributed Strings into Automerge Marks

Automerge 0.5.x series introduces an extended structure pattern within a document: Marks.
In Automerge, Marks can encode additional information about a single, or run, or characters within an Automerge `Text`` object, a convenient pattern for encoding rich text attributes - bold, italics, links, etc.

The swift type of `AttributedString` encodes seamless into an Automerge document, but in a fashion that's not terribly easy to use for cross-platform decoding.

The default encoding of `AttributedString` uses it's conformance to the `Codable` protocol, and is most easily understood with a quick encoding into JSON format.
As an example, I made a quick sample document in Markdown with a variety of markup:

```markdown
# An example markdown file

With some basic text in it.
**Some** of which is _formatted_.
And includes a [link to Automerge](https://automerge.org/).

Bullet items:

- one
- two
- three

Numbered List:

1. Alpha
2. Beta
3. Delta
```

The swift language and standard library includes support for configurable coders to support a variety of encoding configurations. Using a default encoder, the following snippet encodes the AttributedString (created from the Markdown) into JSON.

```swift
let richText = try AttributedString(markdown: data)
let enc = JSONEncoder()
let jsonEncodedRichText = try enc.encode(richText)
print(String(bytes: jsonEncodedRichText, encoding: .utf8))
```

Swift's attributed strings can support more capabilities than can be exposed in Markdown, with a variety of AttributeScopes provided through various Apple frameworks. 
These capabilities typically conform to the [AttributedStringKey](https://developer.apple.com/documentation/foundation/attributedstringkey) protocol, which is sort of a "base protocol" inherited by several other protocols.
The most relevant of these protocols are [DecodableAttributedStringKey](https://developer.apple.com/documentation/foundation/decodableattributedstringkey) and [EncodableAttributedStringKey](https://developer.apple.com/documentation/foundation/encodableattributedstringkey) which together define the various attributes that are supported for encoding and decoding with the default Codable implementations.

AttributedString uses a configuration based encoding and decoding, with the type [AttributeScopeCodableConfiguration](https://developer.apple.com/documentation/foundation/attributescopecodableconfiguration) as the configuration, that allows for custom/arbitrary attributes to be defined and encoded.
This configuration, and the codable implementations for AttributedString, provide for a consistent means of encoding various attributes provided by various Swift frameworks.
It also supports custom attributes that you can specify and read in from markdown using the markdown processor provided by AttributedString.
For an example of this attribute markup in markdown format, see the documentation for the [MarkdownDecodableAttributedStringKey](https://developer.apple.com/documentation/foundation/markdowndecodableattributedstringkey) protocol.

The built-in encoding mechanism stores Attributed Strings as a series of `runs`, the plain text of the content followed immediately by a reference to an `attributeTable`. 
The `attributeTable` is a list of objects that represents a unique set of presentation intents.
Each presentation intent may also reference addition value information that the decoder uses to pick the relevant intent.
For example, in the following example, `NSInlinePresentationIntent: 64` indicates strongly emphasized (bold), where `NSInlinePresentationIntent: 2` indicates emphasized (italic).
The full example of the markdown example encoded to JSON is shown below:

```json
{
    "runs": [
        "An example markdown file",
        0,
        "With some basic text in it.",
        1,
        " ",
        2,
        "Some",
        3,
        " of which is ",
        1,
        "formatted",
        4,
        ".",
        1,
        " ",
        2,
        "And includes a ",
        1,
        "link to Automerge",
        5,
        ".",
        1,
        "Bullet items:",
        6,
        "one",
        7,
        "two",
        8,
        "three",
        9,
        "Numbered List:",
        10,
        "Alpha",
        11,
        "Beta",
        12,
        "Delta",
        13
    ],
    "attributeTable": [
        {
            "NSPresentationIntent": {
                "components": [
                    {
                        "kind": [
                            "header",
                            1
                        ],
                        "identity": 1
                    }
                ]
            }
        },
        {
            "NSPresentationIntent": {
                "components": [
                    {
                        "kind": [
                            "paragraph"
                        ],
                        "identity": 2
                    }
                ]
            }
        },
        {
            "NSPresentationIntent": {
                "components": [
                    {
                        "kind": [
                            "paragraph"
                        ],
                        "identity": 2
                    }
                ]
            },
            "NSInlinePresentationIntent": 64
        },
        {
            "NSInlinePresentationIntent": 2,
            "NSPresentationIntent": {
                "components": [
                    {
                        "kind": [
                            "paragraph"
                        ],
                        "identity": 2
                    }
                ]
            }
        },
        {
            "NSPresentationIntent": {
                "components": [
                    {
                        "kind": [
                            "paragraph"
                        ],
                        "identity": 2
                    }
                ]
            },
            "NSInlinePresentationIntent": 1
        },
        {
            "NSPresentationIntent": {
                "components": [
                    {
                        "kind": [
                            "paragraph"
                        ],
                        "identity": 2
                    }
                ]
            },
            "NSLink": {
                "relative": "https:\\/\\/automerge.org\\/"
            }
        },
        {
            "NSPresentationIntent": {
                "components": [
                    {
                        "kind": [
                            "paragraph"
                        ],
                        "identity": 3
                    }
                ]
            }
        },
        {
            "NSPresentationIntent": {
                "components": [
                    {
                        "kind": [
                            "paragraph"
                        ],
                        "identity": 6
                    },
                    {
                        "kind": [
                            "listItem",
                            1
                        ],
                        "identity": 5
                    },
                    {
                        "kind": [
                            "unorderedList"
                        ],
                        "identity": 4
                    }
                ]
            }
        },
        {
            "NSPresentationIntent": {
                "components": [
                    {
                        "kind": [
                            "paragraph"
                        ],
                        "identity": 8
                    },
                    {
                        "kind": [
                            "listItem",
                            2
                        ],
                        "identity": 7
                    },
                    {
                        "kind": [
                            "unorderedList"
                        ],
                        "identity": 4
                    }
                ]
            }
        },
        {
            "NSPresentationIntent": {
                "components": [
                    {
                        "kind": [
                            "paragraph"
                        ],
                        "identity": 10
                    },
                    {
                        "kind": [
                            "listItem",
                            3
                        ],
                        "identity": 9
                    },
                    {
                        "kind": [
                            "unorderedList"
                        ],
                        "identity": 4
                    }
                ]
            }
        },
        {
            "NSPresentationIntent": {
                "components": [
                    {
                        "kind": [
                            "paragraph"
                        ],
                        "identity": 11
                    }
                ]
            }
        },
        {
            "NSPresentationIntent": {
                "components": [
                    {
                        "kind": [
                            "paragraph"
                        ],
                        "identity": 14
                    },
                    {
                        "kind": [
                            "listItem",
                            1
                        ],
                        "identity": 13
                    },
                    {
                        "kind": [
                            "orderedList"
                        ],
                        "identity": 12
                    }
                ]
            }
        },
        {
            "NSPresentationIntent": {
                "components": [
                    {
                        "kind": [
                            "paragraph"
                        ],
                        "identity": 16
                    },
                    {
                        "kind": [
                            "listItem",
                            2
                        ],
                        "identity": 15
                    },
                    {
                        "kind": [
                            "orderedList"
                        ],
                        "identity": 12
                    }
                ]
            }
        },
        {
            "NSPresentationIntent": {
                "components": [
                    {
                        "kind": [
                            "paragraph"
                        ],
                        "identity": 18
                    },
                    {
                        "kind": [
                            "listItem",
                            3
                        ],
                        "identity": 17
                    },
                    {
                        "kind": [
                            "orderedList"
                        ],
                        "identity": 12
                    }
                ]
            }
        }
    ]
}
```

## Encodable Attributes for Attributed Strings

Looking at the list of scopes that conform to the [DecodableAttributedStringKey](https://developer.apple.com/documentation/foundation/decodableattributedstringkey) provides a list of attributes (as of iOS 17) that `AttributedString` supports.

### Date Attributes

- [AttributeScopes.FoundationAttributes.DateFieldAttribute](https://developer.apple.com/documentation/foundation/attributescopes/foundationattributes/datefieldattribute)

### Language Attributes

- [AttributeScopes.FoundationAttributes.LanguageIdentifierAttribute](https://developer.apple.com/documentation/foundation/attributescopes/foundationattributes/languageidentifierattribute)

### URL Attributes

- [AttributeScopes.FoundationAttributes.ImageURLAttribute](https://developer.apple.com/documentation/foundation/attributescopes/foundationattributes/imageurlattribute)
- [AttributeScopes.FoundationAttributes.LinkAttribute](https://developer.apple.com/documentation/foundation/attributescopes/foundationattributes/linkattribute)

### Presentation Intent Attributes

- [AttributeScopes.FoundationAttributes.InlinePresentationIntentAttribute](https://developer.apple.com/documentation/foundation/attributescopes/foundationattributes/inlinepresentationintentattribute)
- [AttributeScopes.FoundationAttributes.PresentationIntentAttribute](https://developer.apple.com/documentation/foundation/attributescopes/foundationattributes/presentationintentattribute)

### Alternative Description Attributes

- [AttributeScopes.FoundationAttributes.AlternateDescriptionAttribute](https://developer.apple.com/documentation/foundation/attributescopes/foundationattributes/alternatedescriptionattribute)

### String Formatting Attributes

- [AttributeScopes.FoundationAttributes.ReplacementIndexAttribute](https://developer.apple.com/documentation/foundation/attributescopes/foundationattributes/replacementindexattribute)

### String Localization Attributes

- [AttributeScopes.FoundationAttributes.LocalizedStringArgumentAttributes.LocalizedDateArgumentAttribute](https://developer.apple.com/documentation/foundation/attributescopes/foundationattributes/localizedstringargumentattributes/localizeddateargumentattribute)
- [AttributeScopes.FoundationAttributes.LocalizedStringArgumentAttributes.LocalizedDateIntervalArgumentAttribute](https://developer.apple.com/documentation/foundation/attributescopes/foundationattributes/localizedstringargumentattributes/localizeddateintervalargumentattribute)
- [AttributeScopes.FoundationAttributes.LocalizedStringArgumentAttributes.LocalizedNumericArgumentAttribute](https://developer.apple.com/documentation/foundation/attributescopes/foundationattributes/localizedstringargumentattributes/localizednumericargumentattribute)
- [AttributeScopes.FoundationAttributes.LocalizedStringArgumentAttributes.LocalizedURLArgumentAttribute](https://developer.apple.com/documentation/foundation/attributescopes/foundationattributes/localizedstringargumentattributes/localizedurlargumentattribute)

### Grammar Agreement Attributes

- [AttributeScopes.FoundationAttributes.InflectionRuleAttribute](https://developer.apple.com/documentation/foundation/attributescopes/foundationattributes/inflectionruleattribute)
- [AttributeScopes.FoundationAttributes.AgreementArgumentAttribute](https://developer.apple.com/documentation/foundation/attributescopes/foundationattributes/agreementargumentattribute)
- [AttributeScopes.FoundationAttributes.AgreementConceptAttribute](https://developer.apple.com/documentation/foundation/attributescopes/foundationattributes/agreementconceptattribute)
- [AttributeScopes.FoundationAttributes.MorphologyAttribute](https://developer.apple.com/documentation/foundation/attributescopes/foundationattributes/morphologyattribute)
- [AttributeScopes.FoundationAttributes.ReferentConceptAttribute](https://developer.apple.com/documentation/foundation/attributescopes/foundationattributes/referentconceptattribute)
- [AttributeScopes.FoundationAttributes.InflectionAlternativeAttribute](https://developer.apple.com/documentation/foundation/attributescopes/foundationattributes/inflectionalternativeattribute)

### Number Formatting Attributes

- [AttributeScopes.FoundationAttributes.NumberFormatAttributes.NumberPartAttribute](https://developer.apple.com/documentation/foundation/attributescopes/foundationattributes/numberformatattributes/numberpartattribute)
- [AttributeScopes.FoundationAttributes.NumberFormatAttributes.SymbolAttribute](https://developer.apple.com/documentation/foundation/attributescopes/foundationattributes/numberformatattributes/symbolattribute)

### Person Name Component Attributes

- [AttributeScopes.FoundationAttributes.PersonNameComponentAttribute](https://developer.apple.com/documentation/foundation/attributescopes/foundationattributes/personnamecomponentattribute)

### Markdown Source Position Attributes

- [AttributeScopes.FoundationAttributes.MarkdownSourcePositionAttribute](https://developer.apple.com/documentation/foundation/attributescopes/foundationattributes/markdownsourcepositionattribute)

### Measurement Format Attributes

- [AttributeScopes.FoundationAttributes.MeasurementAttribute](https://developer.apple.com/documentation/foundation/attributescopes/foundationattributes/measurementattribute)
- [AttributeScopes.FoundationAttributes.ByteCountAttribute](https://developer.apple.com/documentation/foundation/attributescopes/foundationattributes/bytecountattribute)
- [AttributeScopes.FoundationAttributes.DurationFieldAttribute](https://developer.apple.com/documentation/foundation/attributescopes/foundationattributes/durationfieldattribute)

> Note: More attributes _may_ be supported, but aren't persistable using encoding. An example of such is an ephemeral attribute, such as syntax highlighting in a development editor.

There are also [UIKit](https://developer.apple.com/documentation/foundation/attributescopes/uikitattributes), [AppKit](https://developer.apple.com/documentation/foundation/attributescopes/appkitattributes), and [SwiftUI](https://developer.apple.com/documentation/foundation/attributescopes/swiftuiattributes) framework specific attribute scopes, which define additional framework specific markup such as:

### Color

- foreground color
- background color

### Font and Layout

- font
- tracking
- ligature (UIKit, AppKit)
- glyphinfo (AppKit)
- baseline offset
- kern

### Text Styling

- baselineOffset (AppKit)
- shadow (UIKit, AppKit)
- strikethrough Color (UIKit, AppKit)
- strikethrough Style (UIKit, AppKit)
- strokeColor (UIKit, AppKit)
- strokeWidth (UIKit, AppKit)
- textEffect (UIKit, AppKit)
- underlineColor (UIKit, AppKit)
- underlineStyle (UIKit, AppKit)
- obliqueness (UIKit, AppKit) (deprecated)

### Text Layout and Presentation

- markedClauseSegment (AppKit)
- paragraphStyle (UIKit, AppKit)
- superscript (AppKit)

### Text Interaction Attributes

- textItemTag (UIKit)

### Attachments and Expansions

- attachment (UIKit, AppKit)
- expanion (UIKit, AppKit) (deprecated)

### User Interface Attributes

- cursor (AppKit)
- toolTip (AppKit)
- textAlternative (AppKit)

### Accessibility

- accessibility (UIKit, AppKit)

## Implementation for Automerge-Swift

The AutomergeEncoder has support for special handling of a specific types, over-riding default Swift Codable implementations.
In order to support encoding AttributedString into Automerge's `Marks`, that capability expands to cover the type `AttribtedString`.
