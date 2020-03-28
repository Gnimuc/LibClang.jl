"""
A parsed comment.
"""
struct CXComment
    ASTNode::Ptr{Cvoid}
    TranslationUnit::CXTranslationUnit
end

"""
    clang_Cursor_getParsedComment(cursor)
Given a cursor that represents a documentable entity (e.g., declaration), return the
associated parsed comment as a [`CXComment_FullComment`](@ref) AST node.
"""
function clang_Cursor_getParsedComment(cursor)
    ccall((:clang_Cursor_getParsedComment, libclang), CXComment, (CXCursor,), cursor)
end

"""
Describes the type of the comment AST node ([`CXComment`](@ref)).  A comment node can be considered
block content (e. g., paragraph), inline content(plain text) or neither (the root AST node).
"""
@cenum CXCommentKind::UInt32 begin
    CXComment_Null = 0
    CXComment_Text = 1
    CXComment_InlineCommand = 2
    CXComment_HTMLStartTag = 3
    CXComment_HTMLEndTag = 4
    CXComment_Paragraph = 5
    CXComment_BlockCommand = 6
    CXComment_ParamCommand = 7
    CXComment_TParamCommand = 8
    CXComment_VerbatimBlockCommand = 9
    CXComment_VerbatimBlockLine = 10
    CXComment_VerbatimLine = 11
    CXComment_FullComment = 12
end

"""
The most appropriate rendering mode for an inline command, chosen on command semantics in Doxygen.
"""
@cenum CXCommentInlineCommandRenderKind::UInt32 begin
    CXCommentInlineCommandRenderKind_Normal = 0
    CXCommentInlineCommandRenderKind_Bold = 1
    CXCommentInlineCommandRenderKind_Monospaced = 2
    CXCommentInlineCommandRenderKind_Emphasized = 3
end

"""
Describes parameter passing direction for \\param or \\arg command.
"""
@cenum CXCommentParamPassDirection::UInt32 begin
    CXCommentParamPassDirection_In = 0
    CXCommentParamPassDirection_Out = 1
    CXCommentParamPassDirection_InOut = 2
end

"""
    clang_Comment_getKind(Comment)
Returns the type of the AST node. `Comment` is AST node of any kind.
"""
function clang_Comment_getKind(Comment)
    ccall((:clang_Comment_getKind, libclang), CXCommentKind, (CXComment,), Comment)
end

"""
    clang_Comment_getNumChildren(Comment)
Returns number of children of the AST node. `Comment` is AST node of any kind.
"""
function clang_Comment_getNumChildren(Comment)
    ccall((:clang_Comment_getNumChildren, libclang), UInt32, (CXComment,), Comment)
end

"""
    clang_Comment_getChild(Comment, ChildIdx)
Returns the specified child of the AST node.
## Arguments
- `Comment`: AST node of any kind
- `ChildIdx`: child index (zero-based)
"""
function clang_Comment_getChild(Comment, ChildIdx)
    ccall((:clang_Comment_getChild, libclang), CXComment, (CXComment, UInt32), Comment, ChildIdx)
end

"""
    clang_Comment_isWhitespace(Comment)
A [`CXComment_Paragraph`](@ref) node is considered whitespace if it contains only [`CXComment_Text`](@ref)
nodes that are empty or whitespace. Returns non-zero if `Comment` is whitespace.

Other AST nodes (except [`CXComment_Paragraph`](@ref) and [`CXComment_Text`](@ref)) are
never considered whitespace.
"""
function clang_Comment_isWhitespace(Comment)
    ccall((:clang_Comment_isWhitespace, libclang), UInt32, (CXComment,), Comment)
end

"""
    clang_InlineContentComment_hasTrailingNewline(Comment)
Returns non-zero if `Comment` is inline content and has a newline immediately following it
in the comment text. Newlines between paragraphs do not count.
"""
function clang_InlineContentComment_hasTrailingNewline(Comment)
    ccall((:clang_InlineContentComment_hasTrailingNewline, libclang), UInt32, (CXComment,), Comment)
end

"""
    clang_TextComment_getText(Comment)
Returns text contained in the AST node. `Comment` is a [`CXComment_Text`](@ref) AST node.
"""
function clang_TextComment_getText(Comment)
    ccall((:clang_TextComment_getText, libclang), CXString, (CXComment,), Comment)
end

"""
    clang_InlineCommandComment_getCommandName(Comment)
Returns name of the inline command. `Comment` is a [`CXComment_InlineCommand`](@ref) AST node.
"""
function clang_InlineCommandComment_getCommandName(Comment)
    ccall((:clang_InlineCommandComment_getCommandName, libclang), CXString, (CXComment,), Comment)
end

"""
    clang_InlineCommandComment_getRenderKind(Comment)
Returns the most appropriate rendering mode, chosen on command semantics in Doxygen.
`Comment` is a [`CXComment_InlineCommand`](@ref) AST node.
"""
function clang_InlineCommandComment_getRenderKind(Comment)
    ccall((:clang_InlineCommandComment_getRenderKind, libclang), CXCommentInlineCommandRenderKind, (CXComment,), Comment)
end

"""
    clang_InlineCommandComment_getNumArgs(Comment)
Returns number of command arguments. `Comment` is a [`CXComment_InlineCommand`](@ref) AST node.
"""
function clang_InlineCommandComment_getNumArgs(Comment)
    ccall((:clang_InlineCommandComment_getNumArgs, libclang), UInt32, (CXComment,), Comment)
end

"""
    clang_InlineCommandComment_getArgText(Comment, ArgIdx)
Returns text of the specified argument.

## Arguments
- `Comment`: a [`CXComment_InlineCommand`](@ref) AST node
- `ArgIdx`: argument index (zero-based)
"""
function clang_InlineCommandComment_getArgText(Comment, ArgIdx)
    ccall((:clang_InlineCommandComment_getArgText, libclang), CXString, (CXComment, UInt32), Comment, ArgIdx)
end

"""
    clang_HTMLTagComment_getTagName(Comment)
Returns HTML tag name.

`Comment` is a [`CXComment_HTMLStartTag`](@ref) or [`CXComment_HTMLEndTag`](@ref) AST node.
"""
function clang_HTMLTagComment_getTagName(Comment)
    ccall((:clang_HTMLTagComment_getTagName, libclang), CXString, (CXComment,), Comment)
end

"""
    clang_HTMLStartTagComment_isSelfClosing(Comment)
Returns non-zero if tag is self-closing (for example, &lt;br /&gt;).

`Comment` a [`CXComment_HTMLStartTag`](@ref) AST node.
"""
function clang_HTMLStartTagComment_isSelfClosing(Comment)
    ccall((:clang_HTMLStartTagComment_isSelfClosing, libclang), UInt32, (CXComment,), Comment)
end

"""
    clang_HTMLStartTag_getNumAttrs(Comment)
Returns number of attributes (name-value pairs) attached to the start tag.

`Comment` a [`CXComment_HTMLStartTag`](@ref) AST node.
"""
function clang_HTMLStartTag_getNumAttrs(Comment)
    ccall((:clang_HTMLStartTag_getNumAttrs, libclang), UInt32, (CXComment,), Comment)
end

"""
    clang_HTMLStartTag_getAttrName(Comment, AttrIdx)
Returns name of the specified attribute.

## Arguments
- `Comment`: a [`CXComment_HTMLStartTag`](@ref) AST node
- `AttrIdx`: attribute index (zero-based)
"""
function clang_HTMLStartTag_getAttrName(Comment, AttrIdx)
    ccall((:clang_HTMLStartTag_getAttrName, libclang), CXString, (CXComment, UInt32), Comment, AttrIdx)
end

"""
    clang_HTMLStartTag_getAttrValue(Comment, AttrIdx)
Returns value of the specified attribute.

## Arguments
- `Comment`: a [`CXComment_HTMLStartTag`](@ref) AST node
- `AttrIdx`: attribute index (zero-based)
"""
function clang_HTMLStartTag_getAttrValue(Comment, AttrIdx)
    ccall((:clang_HTMLStartTag_getAttrValue, libclang), CXString, (CXComment, UInt32), Comment, AttrIdx)
end

"""
    clang_BlockCommandComment_getCommandName(Comment)
Returns name of the block command. `Comment` is a [`CXComment_BlockCommand`](@ref) AST node.
"""
function clang_BlockCommandComment_getCommandName(Comment)
    ccall((:clang_BlockCommandComment_getCommandName, libclang), CXString, (CXComment,), Comment)
end

"""
    clang_BlockCommandComment_getNumArgs(Comment)
Returns number of word-like arguments. `Comment` a [`CXComment_BlockCommand`](@ref) AST node.
"""
function clang_BlockCommandComment_getNumArgs(Comment)
    ccall((:clang_BlockCommandComment_getNumArgs, libclang), UInt32, (CXComment,), Comment)
end

"""
    clang_BlockCommandComment_getArgText(Comment, ArgIdx)
Returns text of the specified word-like argument.

## Arguments
- `Comment`: a [`CXComment_BlockCommand`](@ref) AST node
- `AttrIdx`: attribute index (zero-based)
"""
function clang_BlockCommandComment_getArgText(Comment, ArgIdx)
    ccall((:clang_BlockCommandComment_getArgText, libclang), CXString, (CXComment, UInt32), Comment, ArgIdx)
end

"""
    clang_BlockCommandComment_getParagraph(Comment)
Returns paragraph argument of the block command. `Comment` is a [`CXComment_BlockCommand`](@ref) or
[`CXComment_VerbatimBlockCommand`](@ref) AST node.
"""
function clang_BlockCommandComment_getParagraph(Comment)
    ccall((:clang_BlockCommandComment_getParagraph, libclang), CXComment, (CXComment,), Comment)
end

"""
    clang_ParamCommandComment_getParamName(Comment)
Returns parameter name. `Comment` is a [`CXComment_ParamCommand`](@ref) AST node.
"""
function clang_ParamCommandComment_getParamName(Comment)
    ccall((:clang_ParamCommandComment_getParamName, libclang), CXString, (CXComment,), Comment)
end

"""
    clang_ParamCommandComment_isParamIndexValid(Comment)
Returns non-zero if the parameter that this AST node represents was found in the function
prototype and [`clang_ParamCommandComment_getParamIndex`](@ref) function will return a
meaningful value. `Comment` is a [`CXComment_ParamCommand`](@ref) AST node.
"""
function clang_ParamCommandComment_isParamIndexValid(Comment)
    ccall((:clang_ParamCommandComment_isParamIndexValid, libclang), UInt32, (CXComment,), Comment)
end

"""
    clang_ParamCommandComment_getParamIndex(Comment)
Returns zero-based parameter index in function prototype.
`Comment` is a [`CXComment_ParamCommand`](@ref) AST node.
"""
function clang_ParamCommandComment_getParamIndex(Comment)
    ccall((:clang_ParamCommandComment_getParamIndex, libclang), UInt32, (CXComment,), Comment)
end

"""
    clang_ParamCommandComment_isDirectionExplicit(Comment)
Returns non-zero if parameter passing direction was specified explicitly in the comment.
`Comment` is a [`CXComment_ParamCommand`](@ref) AST node.
"""
function clang_ParamCommandComment_isDirectionExplicit(Comment)
    ccall((:clang_ParamCommandComment_isDirectionExplicit, libclang), UInt32, (CXComment,), Comment)
end

"""
    clang_ParamCommandComment_getDirection(Comment)
Returns parameter passing direction. `Comment` is a [`CXComment_ParamCommand`](@ref) AST node.
"""
function clang_ParamCommandComment_getDirection(Comment)
    ccall((:clang_ParamCommandComment_getDirection, libclang), CXCommentParamPassDirection, (CXComment,), Comment)
end

"""
    clang_TParamCommandComment_getParamName(Comment)
Returns template parameter name. `Comment` is a [`CXComment_TParamCommand`](@ref) AST node.
"""
function clang_TParamCommandComment_getParamName(Comment)
    ccall((:clang_TParamCommandComment_getParamName, libclang), CXString, (CXComment,), Comment)
end

"""
    clang_TParamCommandComment_isParamPositionValid(Comment)
Returns non-zero if the parameter that this AST node represents was found in the template
parameter list and [`clang_TParamCommandComment_getDepth`](@ref) and [`clang_TParamCommandComment_getIndex`](@ref)
functions will return a meaningful value. `Comment` is a [`CXComment_TParamCommand`](@ref) AST node.
"""
function clang_TParamCommandComment_isParamPositionValid(Comment)
    ccall((:clang_TParamCommandComment_isParamPositionValid, libclang), UInt32, (CXComment,), Comment)
end

"""
    clang_TParamCommandComment_getDepth(Comment)
Returns zero-based nesting depth of this parameter in the template parameter list.
`Comment` is a [`CXComment_TParamCommand`](@ref) AST node.
For example,
```
\verbatim
    template<typename C, template<typename T> class TT>
    void test(TT<int> aaa);
\endverbatim
for C and TT nesting depth is 0,
for T nesting depth is 1.
```
"""
function clang_TParamCommandComment_getDepth(Comment)
    ccall((:clang_TParamCommandComment_getDepth, libclang), UInt32, (CXComment,), Comment)
end

"""
    clang_TParamCommandComment_getIndex(Comment, Depth)
Returns zero-based parameter index in the template parameter list at a given nesting depth.
`Comment` is a [`CXComment_TParamCommand`](@ref) AST node.
For example,
```
\verbatim
    template<typename C, template<typename T> class TT>
    void test(TT<int> aaa);
\endverbatim
for C and TT nesting depth is 0, so we can ask for index at depth 0:
at depth 0 C's index is 0, TT's index is 1.

For T nesting depth is 1, so we can ask for index at depth 0 and 1:
at depth 0 T's index is 1 (same as TT's),
at depth 1 T's index is 0.
```
"""
function clang_TParamCommandComment_getIndex(Comment, Depth)
    ccall((:clang_TParamCommandComment_getIndex, libclang), UInt32, (CXComment, UInt32), Comment, Depth)
end

"""
    clang_VerbatimBlockLineComment_getText(Comment)
Returns text contained in the AST node. `Comment` is a [`CXComment_VerbatimBlockLine`](@ref) AST node.
"""
function clang_VerbatimBlockLineComment_getText(Comment)
    ccall((:clang_VerbatimBlockLineComment_getText, libclang), CXString, (CXComment,), Comment)
end

"""
    clang_VerbatimLineComment_getText(Comment)
Returns text contained in the AST node. `Comment` is a [`CXComment_VerbatimLine`](@ref) AST node.
"""
function clang_VerbatimLineComment_getText(Comment)
    ccall((:clang_VerbatimLineComment_getText, libclang), CXString, (CXComment,), Comment)
end

"""
    clang_HTMLTagComment_getAsString(Comment)
Convert an HTML tag AST node to string. Returns string containing an HTML tag. `Comment` is a
[`CXComment_HTMLStartTag`](@ref) or [`CXComment_HTMLEndTag`](@ref) AST node.
"""
function clang_HTMLTagComment_getAsString(Comment)
    ccall((:clang_HTMLTagComment_getAsString, libclang), CXString, (CXComment,), Comment)
end

"""
    clang_FullComment_getAsHTML(Comment)
Convert a given full parsed comment to an HTML fragment. Returns string containing an HTML fragment.
Specific details of HTML layout are subject to change. Don't try to parse this HTML back into
an AST, use other APIs instead. `Comment` is a [`CXComment_FullComment`](@ref) AST node.
"""
function clang_FullComment_getAsHTML(Comment)
    ccall((:clang_FullComment_getAsHTML, libclang), CXString, (CXComment,), Comment)
end

"""
    clang_FullComment_getAsXML(Comment)
Convert a given full parsed comment to an XML document. Returns string containing an XML
document. A Relax NG schema for the XML can be found in comment-xml-schema.rng file inside
clang source tree. `Comment` is a [`CXComment_FullComment`](@ref) AST node.
"""
function clang_FullComment_getAsXML(Comment)
    ccall((:clang_FullComment_getAsXML, libclang), CXString, (CXComment,), Comment)
end
