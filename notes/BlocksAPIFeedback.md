# Blocks API Feedback

I haven't fully worked through exposing the Blocks API PR branch to Swift, as I'm struggling a bit with the Rust.
I've read through the javascript API, and particularly the tests, to try and understand what the API surface is that's exposed.

## What I think I'm seeing

There's a new "block" element, represented by a list of 1 or more strings, with the list making up a tiering of the blocks that are being represented.
The API to manipulate those blocks is split_block() and join_block(), with the results of making those calls exposed in viewing the patches applied, or the spans returned, from a Text object. 
The markers which represent a change (split or join) in block formatting are included within the sequence that holds the text content.

## Feedback

Because of this structure, what I've gathered of the blocks API seems to expose more details of how the data is stored up through the API than it needs to, and the separation of `blocks` from `marks` makes it a real question as to which you'd use to encode information. 
What I see is `blocks` is strictly hierarchical ranges -  blocks don't overlap, where marks do allow you to overlap.

The separate APIs can be made to work, but I think how they're stored should be completely encapsulated by the end-user API, by which I mean the Rust/WASM border.

To do the conversions with this proposed API, I'll have to be looking at both marks and blocks on a Text object with rich-text attributes, and even there I'll be limited or have to do some creative gyrations to accomodate storing some presentation attributes where Swift would be wanting to retrieve several parameters (such as the font example, above).

I think the API would be better if the exposed API surface was unified into a single thing - marks which can be iterated using `text.spans()`, and having the returned data from a mark be a list of ordered attributes, each of which is represented by a map - string key to ScalarValue attribute. 
The ordering being the layering of the blocks and how they're to be applied.

In my ideal world (to accomodate more complex "font" attribute representations) that ScalarValue attribute would be replaced with a dictionary of key -> parameter for mark, so I could more easily handle `family: Serif, name: Georgia, size: 32`.

Likewise changing attributes is typically applying (or toggling, or removing) an attribute across a range of text indicies, which matches pretty nicely with the current `spliceText()` function, except where it takes a single value for a mark, I'd prefer to see an ordered list of attributes that allowed us to represent the blocks there as well.

Using split_block and join_block to represent the blocks are markers of where it changes within the sequence of characters looks great to me - and I think it would be better if that were merged with the "mark" concept and encapsulated behind `spliceText()` to insert/update and `spans()` to read it out.

The other API that I'd need at the Swift level for usefulness - specifically for editing a text string and managing display representation - is to be able to look up (or query) the attributes that are associated with a specific Character index within a string. 
While not completely accurate to a single glyph.

That information can be retrieved from the `spans()` concept above, but since I think it would be generally useful, it might be worthwhile to have a speedier lookup into whatever underlying data structures exist tracking blocks and marks so that it's closer to an O(1) complexity function rather than a O(n) (or worse) complexity function. 
(Use case: when I add a character in a rich text display, I want to know what additional presentation styles may apply, and which I might need to include  - or not - in further characters being either added before or after the current character.)

### Example

An example that illustrates this:

```markdown
# Example

My List

- one
- two with a [link](https://automerge.org)
- three
  - four
```

`richtext.spans()` would return something like:

 "Example" -> ["h1"]
 "My List" -> ["p"]
 "one" -> ["p", "ul", "li"]
 "two with a " -> ["p", "ul", "li"]
 "link" -> ["p", "ul", "li", "link -> https://automerge.org"]
 "three" -> ["p", "ul", "li"]
 "four" -> ["p", "ul", "ul", "li"]

## Swift background

For the Swift language bindings, I have the benefit/drawback of having a predefined model for representing rich text. 
The API for creating a rich text string establishes a string and a container to hold attributes about that string segment.
The attributes are represented by a key and one or more values, akin to what the current Automerge marks api representing a mark as [String:ScalarValue].
The Swift API doesn't distinguish blocks from marks, and freely intermixes them.
Block-type markers are represented by another kind of Mark, and are returned in the same same structure.
When you request spans back from a AttributedString (called `runs`), it returns an array of segments, each of which has the same set of attributes applied.

As an example, the classic `<p>` block is represented in Swift as "NSPresentationIntent #2", and the inline `<b>` (stronly emphasized) is represented as "NSInlinePresentationIntent #64". 
Some presentation intents (for example `link`) include additional data - in the case of link, it's the URL. 
Others include multiple bits of content. For example, `font` can include family name, styling, and size.

I've written up notes about this in greater detail, including how Swift encodes the data for transfer in [Encoding Attributed Strings Into Marks](https://github.com/automerge/automerge-swift/blob/main/notes/EncodingAttributedStringsIntoMarks.md) (I wrote it pre-blocks API).
