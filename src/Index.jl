"""
The version constants for the libclang API.
[`CINDEX_VERSION_MINOR`](@ref) should increase when there are API additions.
[`CINDEX_VERSION_MAJOR`](@ref) is intended for "major" source/ABI breaking changes.

The policy about the libclang API was always to keep it source and ABI
compatible, thus [`CINDEX_VERSION_MAJOR`](@ref) is expected to remain stable.
"""
const CINDEX_VERSION_MAJOR = 0


"""
The version constants for the libclang API.
[`CINDEX_VERSION_MINOR`](@ref) should increase when there are API additions.
[`CINDEX_VERSION_MAJOR`](@ref) is intended for "major" source/ABI breaking changes.

The policy about the libclang API was always to keep it source and ABI
compatible, thus [`CINDEX_VERSION_MAJOR`](@ref) is expected to remain stable.
"""
const CINDEX_VERSION_MINOR = 50

CINDEX_VERSION_ENCODE(major, minor) =  major * 10000 + minor  * 1
const CINDEX_VERSION = CINDEX_VERSION_ENCODE(CINDEX_VERSION_MAJOR, CINDEX_VERSION_MINOR)

CINDEX_VERSION_STRINGIZE_(major, minor) = "$major" * "." * "$minor"
CINDEX_VERSION_STRINGIZE(major, minor) = CINDEX_VERSION_STRINGIZE_(major, minor)
const CINDEX_VERSION_STRING = CINDEX_VERSION_STRINGIZE(CINDEX_VERSION_MAJOR, CINDEX_VERSION_MINOR)

## libclang: C Interface to Clang
# The C Interface to Clang provides a relatively small API that exposes facilities for parsing
# source code into an abstract syntax tree (AST), loading already-parsed ASTs, traversing the
# AST, associating physical source locations with elements within the AST, and other facilities
# that support Clang-based development tools.
#
# This C interface to Clang will never provide all of the information representation stored
# in Clang's C++ AST, nor should it: the intent is to maintain an API that is relatively
# stable from one release to the next, providing only the basic functionality needed to support
# development tools.
#
# To avoid namespace pollution, data types are prefixed with "CX" and functions are prefixed with "clang_".

"""
An "index" that consists of a set of translation units that would typically be linked together
into an executable or library.
"""
const CXIndex = Ptr{Cvoid}

"""
An opaque type representing target information for a given translation unit.
"""
const CXTargetInfo = Ptr{Cvoid}

"""
A single translation unit, which resides in an index.
"""
const CXTranslationUnit = Ptr{Cvoid}

"""
Opaque pointer representing client data that will be passed through to various callbacks and visitors.
"""
const CXClientData = Ptr{Cvoid}


"""
Provides the contents of a file that has not yet been saved to disk.

Each [`CXUnsavedFile`](@ref) instance provides the name of a file on the system along with
the current contents of that file that have not yet been saved to disk.
"""
struct CXUnsavedFile
    Filename::Cstring
    Contents::Cstring
    Length::Culong
end

"""
Describes the availability of a particular entity, which indicates whether the use of this
entity will result in a warning or error due to it being deprecated or unavailable.
- `CXAvailability_Available`: the entity is available.
- `CXAvailability_Deprecated`: the entity is available, but has been deprecated (and its use is not recommended).
- `CXAvailability_NotAvailable`: the entity is not available; any use of it will be an error.
- `CXAvailability_NotAccessible`: the entity is available, but not accessible; any use of it will be an error.
"""
@cenum CXAvailabilityKind::UInt32 begin
    CXAvailability_Available = 0
    CXAvailability_Deprecated = 1
    CXAvailability_NotAvailable = 2
    CXAvailability_NotAccessible = 3
end

"""
    CXVersion
Describes a version number of the form major.minor.subminor.
- `Major`: the major version number, e.g., the '10' in '10.7.3'. A negative value indicates that there is no version number at all.
- `Minor`: the minor version number, e.g., the '7' in '10.7.3'. This value will be negative if no minor version number was provided, e.g., for version '10'.
- `Subminor`: the subminor version number, e.g., the '3' in '10.7.3'. This value will be negative if no minor or subminor version number was provided, e.g., in version '10' or '10.7'.
"""
struct CXVersion
    Major::Cint
    Minor::Cint
    Subminor::Cint
end

"""
Describes the exception specification of a cursor.
A negative value indicates that the cursor is not a function declaration.
"""
@cenum CXCursor_ExceptionSpecificationKind::UInt32 begin
    CXCursor_ExceptionSpecificationKind_None = 0
    CXCursor_ExceptionSpecificationKind_DynamicNone = 1
    CXCursor_ExceptionSpecificationKind_Dynamic = 2
    CXCursor_ExceptionSpecificationKind_MSAny = 3
    CXCursor_ExceptionSpecificationKind_BasicNoexcept = 4
    CXCursor_ExceptionSpecificationKind_ComputedNoexcept = 5
    CXCursor_ExceptionSpecificationKind_Unevaluated = 6
    CXCursor_ExceptionSpecificationKind_Uninstantiated = 7
    CXCursor_ExceptionSpecificationKind_Unparsed = 8
end

"""
    clang_createIndex(excludeDeclarationsFromPCH, displayDiagnostics)
Provides a shared context for creating translation units.

It provides two options:
- `excludeDeclarationsFromPCH`: When non-zero, allows enumeration of "local" declarations
(when loading any new translation units). A "local" declaration is one that belongs in the
translation unit itself and not in a precompiled header that was used by the translation unit.
If zero, all declarations will be enumerated.

Here is an example:
```c
// excludeDeclsFromPCH = 1, displayDiagnostics=1
Idx = clang_createIndex(1, 1);

// IndexTest.pch was produced with the following command:
// "clang -x c IndexTest.h -emit-ast -o IndexTest.pch"
TU = clang_createTranslationUnit(Idx, "IndexTest.pch");

// This will load all the symbols from 'IndexTest.pch'
clang_visitChildren(clang_getTranslationUnitCursor(TU), TranslationUnitVisitor, 0);
clang_disposeTranslationUnit(TU);

// This will load all the symbols from 'IndexTest.c', excluding symbols
// from 'IndexTest.pch'.
char *args[] = { "-Xclang", "-include-pch=IndexTest.pch" };
TU = clang_createTranslationUnitFromSourceFile(Idx, "IndexTest.c", 2, args, 0, 0);
clang_visitChildren(clang_getTranslationUnitCursor(TU), TranslationUnitVisitor, 0);
clang_disposeTranslationUnit(TU);
```

This process of creating the 'pch', loading it separately, and using it (via -include-pch)
allows 'excludeDeclsFromPCH' to remove redundant callbacks(which gives the indexer the same
performance benefit as the compiler).
"""
function clang_createIndex(excludeDeclarationsFromPCH, displayDiagnostics)
    ccall((:clang_createIndex, libclang), CXIndex, (Cint, Cint), excludeDeclarationsFromPCH, displayDiagnostics)
end

"""
    clang_disposeIndex(index)
Destroy the given index.

The index must not be destroyed until all of the translation units created within that index
have been destroyed.
"""
function clang_disposeIndex(index)
    ccall((:clang_disposeIndex, libclang), Cvoid, (CXIndex,), index)
end

"""
Global Option Flags
- `CXGlobalOpt_None`: used to indicate that no special CXIndex options are needed.
- `CXGlobalOpt_ThreadBackgroundPriorityForIndexing`: used to indicate that threads that libclang creates for indexing purposes should use background priority. Affects [`clang_indexSourceFile`](@ref), [`clang_indexTranslationUnit`](@ref), [`clang_parseTranslationUnit`](@ref), [`clang_saveTranslationUnit`](@ref).
- `CXGlobalOpt_ThreadBackgroundPriorityForEditing`: used to indicate that threads that libclang creates for editing purposes should use background priority. Affects [`clang_reparseTranslationUnit`](@ref), [`clang_codeCompleteAt`](@ref), [`clang_annotateTokens`](@ref)
- `CXGlobalOpt_ThreadBackgroundPriorityForAll`: used to indicate that all threads that libclang creates should use background priority.
"""
@cenum CXGlobalOptFlags::UInt32 begin
    CXGlobalOpt_None = 0
    CXGlobalOpt_ThreadBackgroundPriorityForIndexing = 1
    CXGlobalOpt_ThreadBackgroundPriorityForEditing = 2
    CXGlobalOpt_ThreadBackgroundPriorityForAll = 3
end

"""
    clang_CXIndex_setGlobalOptions(idx, options)
Sets general options associated with a [`CXIndex`](@ref).

For example:
```c
CXIndex idx = ...;
clang_CXIndex_setGlobalOptions(idx, clang_CXIndex_getGlobalOptions(idx) | CXGlobalOpt_ThreadBackgroundPriorityForIndexing);
```

`options` is a bitmask of options, a bitwise OR of `CXGlobalOpt_XXX` flags.
"""
function clang_CXIndex_setGlobalOptions(idx, options)
    ccall((:clang_CXIndex_setGlobalOptions, libclang), Cvoid, (CXIndex, UInt32), idx, options)
end

"""
    clang_CXIndex_getGlobalOptions(idx)
Gets the general options associated with a [`CXIndex`](@ref).
Returns A bitmask of options, a bitwise OR of `CXGlobalOpt_XXX` flags that are associated
with the given [`CXIndex`](@ref) object.
"""
function clang_CXIndex_getGlobalOptions(idx)
    ccall((:clang_CXIndex_getGlobalOptions, libclang), UInt32, (CXIndex,), idx)
end

"""
    clang_CXIndex_setInvocationEmissionPathOption(idx, Path)
Sets the invocation emission path option in a [`CXIndex`](@ref).

The invocation emission path specifies a path which will contain log files for certain
libclang invocations. A null value (default) implies that libclang invocations are not logged.
"""
function clang_CXIndex_setInvocationEmissionPathOption(idx, Path)
    ccall((:clang_CXIndex_setInvocationEmissionPathOption, libclang), Cvoid, (CXIndex, Cstring), idx, Path)
end

## CINDEX_FILES File manipulation routines

"""
A particular source file that is part of a translation unit.
"""
const CXFile = Ptr{Cvoid}

"""
    clang_getFileName(SFile)
Retrieve the complete file and path name of the given file.
"""
function clang_getFileName(SFile)
    ccall((:clang_getFileName, libclang), CXString, (CXFile,), SFile)
end

"""
    clang_getFileTime(SFile)
Retrieve the last modification time of the given file.
"""
function clang_getFileTime(SFile)
    ccall((:clang_getFileTime, libclang), Ctime_t, (CXFile,), SFile)
end

"""
Uniquely identifies a CXFile, that refers to the same underlying file, across an indexing session.
"""
struct CXFileUniqueID
    data::NTuple{3, Culonglong}
end

"""
    clang_getFileUniqueID(file, outID)
Retrieve the unique ID for the given `file`.
Returns If there was a failure getting the unique ID, returns non-zero, otherwise returns 0.

## Arguments
- `file`: the file to get the ID for
- `outID`: stores the returned [`CXFileUniqueID`](@ref)
"""
function clang_getFileUniqueID(file, outID)
    ccall((:clang_getFileUniqueID, libclang), Cint, (CXFile, Ptr{CXFileUniqueID}), file, outID)
end

"""
    clang_isFileMultipleIncludeGuarded(tu, file)
Determine whether the given header is guarded against multiple inclusions, either with the conventional
`#ifndef` `#define` `#endif` macro guards or with `#pragma` once.
"""
function clang_isFileMultipleIncludeGuarded(tu, file)
    ccall((:clang_isFileMultipleIncludeGuarded, libclang), UInt32, (CXTranslationUnit, CXFile), tu, file)
end

"""
    clang_getFile(tu, file_name)
Retrieve a file handle within the given translation unit.
Returns the file handle for the named file in the translation unit `tu`, or a NULL file
handle if the file was not a part of this translation unit.

## Arguments
- `tu`: the translation unit
- `file_name`: the name of the file
"""
function clang_getFile(tu, file_name)
    ccall((:clang_getFile, libclang), CXFile, (CXTranslationUnit, Cstring), tu, file_name)
end

"""
    clang_getFileContents(tu, file, size)
Retrieve the buffer associated with the given file.
Returns a pointer to the buffer in memory that holds the contents of `file`, or a NULL pointer
when the file is not loaded.

## Arguments
- `tu`: the translation unit
- `file`: the file for which to retrieve the buffer
- `size`: if non-NULL, will be set to the size of the buffer.
"""
function clang_getFileContents(tu, file, size)
    ccall((:clang_getFileContents, libclang), Cstring, (CXTranslationUnit, CXFile, Ptr{Csize_t}), tu, file, size)
end

"""
    clang_File_isEqual(file1, file2)
Returns non-zero if the `file1` and `file2` point to the same file, or they are both NULL.
"""
function clang_File_isEqual(file1, file2)
    ccall((:clang_File_isEqual, libclang), Cint, (CXFile, CXFile), file1, file2)
end

"""
    clang_File_tryGetRealPathName(file)
Returns the real path name of `file`. An empty string may be returned.
Use [`clang_getFileName`](@ref) in that case.
"""
function clang_File_tryGetRealPathName(file)
    ccall((:clang_File_tryGetRealPathName, libclang), CXString, (CXFile,), file)
end

## Physical source locations

"""
Identifies a specific source location within a translation unit.

Use [`clang_getExpansionLocation`](@ref) or [`clang_getSpellingLocation`](@ref) to map a
source location to a particular file, line, and column.
"""
struct CXSourceLocation
    ptr_data::NTuple{2, Ptr{Cvoid}}
    int_data::UInt32
end

"""
Identifies a half-open character range in the source code.

Use [`clang_getRangeStart`](@ref) and [`clang_getRangeEnd`](@ref) to retrieve the starting
and end locations from a source range, respectively.
"""
struct CXSourceRange
    ptr_data::NTuple{2, Ptr{Cvoid}}
    begin_int_data::UInt32
    end_int_data::UInt32
end

"""
    clang_getNullLocation()
Retrieve a NULL (invalid) source location.
"""
function clang_getNullLocation()
    ccall((:clang_getNullLocation, libclang), CXSourceLocation, ())
end

"""
    clang_equalLocations(loc1, loc2)
Determine whether two source locations, which must refer into the same translation unit,
refer to exactly the same point in the source code.

Returns non-zero if the source locations refer to the same location, zero if they refer to
different locations.
"""
function clang_equalLocations(loc1, loc2)
    ccall((:clang_equalLocations, libclang), UInt32, (CXSourceLocation, CXSourceLocation), loc1, loc2)
end

"""
    clang_getLocation(tu, file, line, column)
Retrieves the source location associated with a given file/line/column in a particular translation unit.
"""
function clang_getLocation(tu, file, line, column)
    ccall((:clang_getLocation, libclang), CXSourceLocation, (CXTranslationUnit, CXFile, UInt32, UInt32), tu, file, line, column)
end

"""
    clang_getLocationForOffset(tu, file, offset)
Retrieves the source location associated with a given character offset in a particular translation unit.
"""
function clang_getLocationForOffset(tu, file, offset)
    ccall((:clang_getLocationForOffset, libclang), CXSourceLocation, (CXTranslationUnit, CXFile, UInt32), tu, file, offset)
end

"""
    clang_Location_isInSystemHeader(location)
Returns non-zero if the given source location is in a system header.
"""
function clang_Location_isInSystemHeader(location)
    ccall((:clang_Location_isInSystemHeader, libclang), Cint, (CXSourceLocation,), location)
end

"""
    clang_Location_isFromMainFile(location)
Returns non-zero if the given source location is in the main file of the corresponding translation unit.
"""
function clang_Location_isFromMainFile(location)
    ccall((:clang_Location_isFromMainFile, libclang), Cint, (CXSourceLocation,), location)
end

"""
    clang_getNullRange()
Retrieve a NULL (invalid) source range.
"""
function clang_getNullRange()
    ccall((:clang_getNullRange, libclang), CXSourceRange, ())
end

"""
    clang_getRange(_begin, _end)
Retrieve a source range given the beginning and ending source locations.
"""
function clang_getRange(_begin, _end)
    ccall((:clang_getRange, libclang), CXSourceRange, (CXSourceLocation, CXSourceLocation), _begin, _end)
end

"""
    clang_equalRanges(range1, range2)
Determine whether two ranges are equivalent. Returns non-zero if the ranges are the same, zero if they differ.
"""
function clang_equalRanges(range1, range2)
    ccall((:clang_equalRanges, libclang), UInt32, (CXSourceRange, CXSourceRange), range1, range2)
end

"""
    clang_Range_isNull(range)
Returns non-zero if `range` is null.
"""
function clang_Range_isNull(range)
    ccall((:clang_Range_isNull, libclang), Cint, (CXSourceRange,), range)
end

"""
    clang_getExpansionLocation(location, file, line, column, offset)
Retrieve the file, line, column, and offset represented by the given source location.
If the location refers into a macro expansion, retrieves the location of the macro expansion.

## Arguments
- `location`: the location within a source file that will be decomposed into its parts
- `file`: if non-NULL, will be set to the file to which the given source location points
- `line`: if non-NULL, will be set to the line to which the given source location points.
- `column`: if non-NULL, will be set to the column to which the given source location points.
- `offset`: if non-NULL, will be set to the offset into the buffer to which the given source location points.
"""
function clang_getExpansionLocation(location, file, line, column, offset)
    ccall((:clang_getExpansionLocation, libclang), Cvoid, (CXSourceLocation, Ptr{CXFile}, Ptr{UInt32}, Ptr{UInt32}, Ptr{UInt32}), location, file, line, column, offset)
end

"""
    clang_getPresumedLocation(location, filename, line, column)
Retrieve the file, line and column represented by the given source location, as specified in
a # line directive.

Example: given the following source code in a file somefile.c
```c
#123 "dummy.c" 1

static int func(void)
{
    return 0;
}
```
the location information returned by this function would be
```
File: dummy.c Line: 124 Column: 12
```
whereas [`clang_getExpansionLocation`](@ref) would have returned
```
File: somefile.c Line: 3 Column: 12
```

## Arguments
- `location`: the location within a source file that will be decomposed into its parts
- `filename`: if non-NULL, will be set to the filename of the source location. Note that filenames returned will be for "virtual" files, which don't necessarily exist on the machine running clang - e.g. when parsing preprocessed output obtained from a different environment. If a non-NULL value is passed in, remember to dispose of the returned value using [`clang_disposeString`](@ref) once you've finished with it. For an invalid source location, an empty string is returned
- `line`: if non-NULL, will be set to the line number of the source location. For an invalid source location, zero is returned
- `column`: if non-NULL, will be set to the column number of the source location. For an invalid source location, zero is returned
"""
function clang_getPresumedLocation(location, filename, line, column)
    ccall((:clang_getPresumedLocation, libclang), Cvoid, (CXSourceLocation, Ptr{CXString}, Ptr{UInt32}, Ptr{UInt32}), location, filename, line, column)
end

"""
    clang_getInstantiationLocation(location, file, line, column, offset)
Legacy API to retrieve the file, line, column, and offset represented by the given source location.

This interface has been replaced by the newer interface [`clang_getExpansionLocation`](@ref).
See that interface's documentation for details.
"""
function clang_getInstantiationLocation(location, file, line, column, offset)
    ccall((:clang_getInstantiationLocation, libclang), Cvoid, (CXSourceLocation, Ptr{CXFile}, Ptr{UInt32}, Ptr{UInt32}, Ptr{UInt32}), location, file, line, column, offset)
end

"""
    clang_getSpellingLocation(location, file, line, column, offset)
Retrieve the file, line, column, and offset represented by the given source location.

If the location refers into a macro instantiation, return where the location was originally
spelled in the source file.

## Arguments
- `location`: the location within a source file that will be decomposed into its parts
- `file`: if non-NULL, will be set to the file to which the given source location points
- `line`: if non-NULL, will be set to the line to which the given source location points
- `column`: if non-NULL, will be set to the column to which the given source location points
- `offset`: if non-NULL, will be set to the offset into the buffer to which the given source location points
"""
function clang_getSpellingLocation(location, file, line, column, offset)
    ccall((:clang_getSpellingLocation, libclang), Cvoid, (CXSourceLocation, Ptr{CXFile}, Ptr{UInt32}, Ptr{UInt32}, Ptr{UInt32}), location, file, line, column, offset)
end

"""
    clang_getFileLocation(location, file, line, column, offset)
Retrieve the file, line, column, and offset represented by the given source location.

If the location refers into a macro expansion, return where the macro was expanded or where
the macro argument was written, if the location points at a macro argument.

## Arguments
- `location`: the location within a source file that will be decomposed into its parts
- `file`: if non-NULL, will be set to the file to which the given source location points
- `line`: if non-NULL, will be set to the line to which the given source location points
- `column`: if non-NULL, will be set to the column to which the given source location points
- `offset`: if non-NULL, will be set to the offset into the buffer to which the given source location points
"""
function clang_getFileLocation(location, file, line, column, offset)
    ccall((:clang_getFileLocation, libclang), Cvoid, (CXSourceLocation, Ptr{CXFile}, Ptr{UInt32}, Ptr{UInt32}, Ptr{UInt32}), location, file, line, column, offset)
end

"""
    clang_getRangeStart(range)
Retrieve a source location representing the first character within a source range.
"""
function clang_getRangeStart(range)
    ccall((:clang_getRangeStart, libclang), CXSourceLocation, (CXSourceRange,), range)
end

"""
    clang_getRangeEnd(range)
Retrieve a source location representing the last character within a source range.
"""
function clang_getRangeEnd(range)
    ccall((:clang_getRangeEnd, libclang), CXSourceLocation, (CXSourceRange,), range)
end

"""
Identifies an array of ranges.
"""
struct CXSourceRangeList
    count::UInt32               # The number of ranges in the `ranges` array
    ranges::Ptr{CXSourceRange}  # An array of `CXSourceRanges`
end

"""
    clang_getSkippedRanges(tu, file)
Retrieve all ranges that were skipped by the preprocessor.

The preprocessor will skip lines when they are surrounded by an `if/ifdef/ifndef` directive
whose condition does not evaluate to true.
"""
function clang_getSkippedRanges(tu, file)
    ccall((:clang_getSkippedRanges, libclang), Ptr{CXSourceRangeList}, (CXTranslationUnit, CXFile), tu, file)
end

"""
    clang_getAllSkippedRanges(tu)
Retrieve all ranges from all files that were skipped by the preprocessor.

The preprocessor will skip lines when they are surrounded by an `if/ifdef/ifndef` directive
whose condition does not evaluate to true.
"""
function clang_getAllSkippedRanges(tu)
    ccall((:clang_getAllSkippedRanges, libclang), Ptr{CXSourceRangeList}, (CXTranslationUnit,), tu)
end

"""
    clang_disposeSourceRangeList(ranges)
Destroy the given [`CXSourceRangeList`](@ref).
"""
function clang_disposeSourceRangeList(ranges)
    ccall((:clang_disposeSourceRangeList, libclang), Cvoid, (Ptr{CXSourceRangeList},), ranges)
end

## Diagnostic reporting

"""
Describes the severity of a particular diagnostic.
- `CXDiagnostic_Ignored`: a diagnostic that has been suppressed, e.g., by a command-line option.
- `CXDiagnostic_Note`: this diagnostic is a note that should be attached to the previous (non-note) diagnostic.
- `CXDiagnostic_Warning`: this diagnostic indicates suspicious code that may not be wrong.
- `CXDiagnostic_Error`: this diagnostic indicates that the code is ill-formed.
- `CXDiagnostic_Fatal`: this diagnostic indicates that the code is ill-formed such that future parser recovery is unlikely to produce useful results.
"""
@cenum CXDiagnosticSeverity::UInt32 begin
    CXDiagnostic_Ignored = 0
    CXDiagnostic_Note = 1
    CXDiagnostic_Warning = 2
    CXDiagnostic_Error = 3
    CXDiagnostic_Fatal = 4
end

"""
A single diagnostic, containing the diagnostic's severity, location, text, source ranges, and fix-it hints.
"""
const CXDiagnostic = Ptr{Cvoid}

"""
A group of CXDiagnostics.
"""
const CXDiagnosticSet = Ptr{Cvoid}

"""
    clang_getNumDiagnosticsInSet(Diags)
Determine the number of diagnostics in a [`CXDiagnosticSet`](@ref).
"""
function clang_getNumDiagnosticsInSet(Diags)
    ccall((:clang_getNumDiagnosticsInSet, libclang), UInt32, (CXDiagnosticSet,), Diags)
end

"""
    clang_getDiagnosticInSet(Diags, Index)
Retrieve a diagnostic associated with the given [`CXDiagnosticSet`](@ref).
Returns the requested diagnostic. This diagnostic must be freed via a call to [`clang_disposeDiagnostic`](@ref).

## Arguments
- `Diags`: the [`CXDiagnosticSet`](@ref) to query
- `Index`: the zero-based diagnostic number to retrieve
"""
function clang_getDiagnosticInSet(Diags, Index)
    ccall((:clang_getDiagnosticInSet, libclang), CXDiagnostic, (CXDiagnosticSet, UInt32), Diags, Index)
end


@cenum CXLoadDiag_Error::UInt32 begin
    CXLoadDiag_None = 0
    CXLoadDiag_Unknown = 1
    CXLoadDiag_CannotLoad = 2
    CXLoadDiag_InvalidFile = 3
end

"""

"""
function clang_loadDiagnostics(file, error, errorString)
    ccall((:clang_loadDiagnostics, libclang), CXDiagnosticSet, (Cstring, Ptr{CXLoadDiag_Error}, Ptr{CXString}), file, error, errorString)
end

"""

"""
function clang_disposeDiagnosticSet(Diags)
    ccall((:clang_disposeDiagnosticSet, libclang), Cvoid, (CXDiagnosticSet,), Diags)
end

"""

"""
function clang_getChildDiagnostics(D)
    ccall((:clang_getChildDiagnostics, libclang), CXDiagnosticSet, (CXDiagnostic,), D)
end

"""

"""
function clang_getNumDiagnostics(Unit)
    ccall((:clang_getNumDiagnostics, libclang), UInt32, (CXTranslationUnit,), Unit)
end

"""

"""
function clang_getDiagnostic(Unit, Index)
    ccall((:clang_getDiagnostic, libclang), CXDiagnostic, (CXTranslationUnit, UInt32), Unit, Index)
end

"""

"""
function clang_getDiagnosticSetFromTU(Unit)
    ccall((:clang_getDiagnosticSetFromTU, libclang), CXDiagnosticSet, (CXTranslationUnit,), Unit)
end

"""

"""
function clang_disposeDiagnostic(Diagnostic)
    ccall((:clang_disposeDiagnostic, libclang), Cvoid, (CXDiagnostic,), Diagnostic)
end

"""

"""
@cenum CXDiagnosticDisplayOptions::UInt32 begin
    CXDiagnostic_DisplaySourceLocation = 1
    CXDiagnostic_DisplayColumn = 2
    CXDiagnostic_DisplaySourceRanges = 4
    CXDiagnostic_DisplayOption = 8
    CXDiagnostic_DisplayCategoryId = 16
    CXDiagnostic_DisplayCategoryName = 32
end

"""

"""
function clang_formatDiagnostic(Diagnostic, Options)
    ccall((:clang_formatDiagnostic, libclang), CXString, (CXDiagnostic, UInt32), Diagnostic, Options)
end

"""

"""
function clang_defaultDiagnosticDisplayOptions()
    ccall((:clang_defaultDiagnosticDisplayOptions, libclang), UInt32, ())
end

"""

"""
function clang_getDiagnosticSeverity(arg1)
    ccall((:clang_getDiagnosticSeverity, libclang), CXDiagnosticSeverity, (CXDiagnostic,), arg1)
end

"""

"""
function clang_getDiagnosticLocation(arg1)
    ccall((:clang_getDiagnosticLocation, libclang), CXSourceLocation, (CXDiagnostic,), arg1)
end

"""

"""
function clang_getDiagnosticSpelling(arg1)
    ccall((:clang_getDiagnosticSpelling, libclang), CXString, (CXDiagnostic,), arg1)
end

"""

"""
function clang_getDiagnosticOption(Diag, Disable)
    ccall((:clang_getDiagnosticOption, libclang), CXString, (CXDiagnostic, Ptr{CXString}), Diag, Disable)
end

"""

"""
function clang_getDiagnosticCategory(arg1)
    ccall((:clang_getDiagnosticCategory, libclang), UInt32, (CXDiagnostic,), arg1)
end

"""

"""
function clang_getDiagnosticCategoryName(Category)
    ccall((:clang_getDiagnosticCategoryName, libclang), CXString, (UInt32,), Category)
end

"""

"""
function clang_getDiagnosticCategoryText(arg1)
    ccall((:clang_getDiagnosticCategoryText, libclang), CXString, (CXDiagnostic,), arg1)
end

"""

"""
function clang_getDiagnosticNumRanges(arg1)
    ccall((:clang_getDiagnosticNumRanges, libclang), UInt32, (CXDiagnostic,), arg1)
end

"""

"""
function clang_getDiagnosticRange(Diagnostic, Range)
    ccall((:clang_getDiagnosticRange, libclang), CXSourceRange, (CXDiagnostic, UInt32), Diagnostic, Range)
end

"""

"""
function clang_getDiagnosticNumFixIts(Diagnostic)
    ccall((:clang_getDiagnosticNumFixIts, libclang), UInt32, (CXDiagnostic,), Diagnostic)
end

"""

"""
function clang_getDiagnosticFixIt(Diagnostic, FixIt, ReplacementRange)
    ccall((:clang_getDiagnosticFixIt, libclang), CXString, (CXDiagnostic, UInt32, Ptr{CXSourceRange}), Diagnostic, FixIt, ReplacementRange)
end

## Translation unit manipulation

"""

"""
function clang_getTranslationUnitSpelling(CTUnit)
    ccall((:clang_getTranslationUnitSpelling, libclang), CXString, (CXTranslationUnit,), CTUnit)
end

"""

"""
function clang_createTranslationUnitFromSourceFile(CIdx, source_filename, num_clang_command_line_args, clang_command_line_args, num_unsaved_files, unsaved_files)
    ccall((:clang_createTranslationUnitFromSourceFile, libclang), CXTranslationUnit, (CXIndex, Cstring, Cint, Ptr{Cstring}, UInt32, Ptr{CXUnsavedFile}), CIdx, source_filename, num_clang_command_line_args, clang_command_line_args, num_unsaved_files, unsaved_files)
end

"""

"""
function clang_createTranslationUnit(CIdx, ast_filename)
    ccall((:clang_createTranslationUnit, libclang), CXTranslationUnit, (CXIndex, Cstring), CIdx, ast_filename)
end

"""

"""
function clang_createTranslationUnit2(CIdx, ast_filename, out_TU)
    ccall((:clang_createTranslationUnit2, libclang), CXErrorCode, (CXIndex, Cstring, Ptr{CXTranslationUnit}), CIdx, ast_filename, out_TU)
end

@cenum CXTranslationUnit_Flags::UInt32 begin
    CXTranslationUnit_None = 0
    CXTranslationUnit_DetailedPreprocessingRecord = 1
    CXTranslationUnit_Incomplete = 2
    CXTranslationUnit_PrecompiledPreamble = 4
    CXTranslationUnit_CacheCompletionResults = 8
    CXTranslationUnit_ForSerialization = 16
    CXTranslationUnit_CXXChainedPCH = 32
    CXTranslationUnit_SkipFunctionBodies = 64
    CXTranslationUnit_IncludeBriefCommentsInCodeCompletion = 128
    CXTranslationUnit_CreatePreambleOnFirstParse = 256
    CXTranslationUnit_KeepGoing = 512
    CXTranslationUnit_SingleFileParse = 1024
    CXTranslationUnit_LimitSkipFunctionBodiesToPreamble = 2048
    CXTranslationUnit_IncludeAttributedTypes = 4096
    CXTranslationUnit_VisitImplicitAttributes = 8192
end

"""

"""
function clang_defaultEditingTranslationUnitOptions()
    ccall((:clang_defaultEditingTranslationUnitOptions, libclang), UInt32, ())
end

"""

"""
function clang_parseTranslationUnit(CIdx, source_filename, command_line_args, num_command_line_args, unsaved_files, num_unsaved_files, options)
    ccall((:clang_parseTranslationUnit, libclang), CXTranslationUnit, (CXIndex, Cstring, Ptr{Cstring}, Cint, Ptr{CXUnsavedFile}, UInt32, UInt32), CIdx, source_filename, command_line_args, num_command_line_args, unsaved_files, num_unsaved_files, options)
end

"""

"""
function clang_parseTranslationUnit2(CIdx, source_filename, command_line_args, num_command_line_args, unsaved_files, num_unsaved_files, options, out_TU)
    ccall((:clang_parseTranslationUnit2, libclang), CXErrorCode, (CXIndex, Cstring, Ptr{Cstring}, Cint, Ptr{CXUnsavedFile}, UInt32, UInt32, Ptr{CXTranslationUnit}), CIdx, source_filename, command_line_args, num_command_line_args, unsaved_files, num_unsaved_files, options, out_TU)
end

"""

"""
function clang_parseTranslationUnit2FullArgv(CIdx, source_filename, command_line_args, num_command_line_args, unsaved_files, num_unsaved_files, options, out_TU)
    ccall((:clang_parseTranslationUnit2FullArgv, libclang), CXErrorCode, (CXIndex, Cstring, Ptr{Cstring}, Cint, Ptr{CXUnsavedFile}, UInt32, UInt32, Ptr{CXTranslationUnit}), CIdx, source_filename, command_line_args, num_command_line_args, unsaved_files, num_unsaved_files, options, out_TU)
end

@cenum CXSaveTranslationUnit_Flags::UInt32 begin
    CXSaveTranslationUnit_None = 0
end

"""
    clang_defaultSaveOptions(TU)
Returns the set of flags that is suitable for saving a translation unit.

The set of flags returned provide options for [`clang_saveTranslationUnit`](@ref) by default.
The returned flag set contains an unspecified set of options that save translation units with
the most commonly-requested data.
"""
function clang_defaultSaveOptions(TU)
    ccall((:clang_defaultSaveOptions, libclang), UInt32, (CXTranslationUnit,), TU)
end

"""
Describes the kind of error that occurred (if any) in a call to [`clang_saveTranslationUnit`](@ref).
"""
@cenum CXSaveError::UInt32 begin
    CXSaveError_None = 0
    CXSaveError_Unknown = 1
    CXSaveError_TranslationErrors = 2
    CXSaveError_InvalidTU = 3
end

"""
    clang_saveTranslationUnit(TU, FileName, options) -> Cint
Saves a translation unit into a serialized representation of that translation unit on disk.

Any translation unit that was parsed without error can be saved into a file. The translation
unit can then be deserialized into a new [`CXTranslationUnit`](@ref) with [`clang_createTranslationUnit`](@ref)
or, if it is an incomplete translation unit that corresponds to a header, used as a precompiled
header when parsing other translation units.

## Arguments
- `TU`: The translation unit to save.
- `FileName`: The file to which the translation unit will be saved.
- `options`: A bitmask of options that affects how the translation unit is saved. This should be a bitwise OR of the `CXSaveTranslationUnit_XXX` flags.

## Returns
A value that will match one of the enumerators of the [`CXSaveError`](@ref) enumeration.
Zero ([`CXSaveError_None`](@ref)) indicates that the translation unit was saved successfully, while a
non-zero value indicates that a problem occurred.
"""
function clang_saveTranslationUnit(TU, FileName, options)
    ccall((:clang_saveTranslationUnit, libclang), Cint, (CXTranslationUnit, Cstring, UInt32), TU, FileName, options)
end

"""
    clang_suspendTranslationUnit(TU) -> UInt32
Suspend a translation unit in order to free memory associated with it.

A suspended translation unit uses significantly less memory but on the other side does not
support any other calls than [`clang_reparseTranslationUnit`](@ref) to resume it or
[`clang_disposeTranslationUnit`](@ref) to dispose it completely.
"""
function clang_suspendTranslationUnit(TU)
    ccall((:clang_suspendTranslationUnit, libclang), UInt32, (CXTranslationUnit,), TU)
end

"""
    clang_disposeTranslationUnit(TU) -> Cvoid
Destroy the specified CXTranslationUnit object.
"""
function clang_disposeTranslationUnit(TU)
    ccall((:clang_disposeTranslationUnit, libclang), Cvoid, (CXTranslationUnit,), TU)
end

"""
Flags that control the reparsing of translation units.

The enumerators in this enumeration type are meant to be bitwise ORed together to specify
which options should be used when reparsing the translation unit.
- `CXReparse_None`: Used to indicate that no special reparsing options are needed.
"""
@cenum CXReparse_Flags::UInt32 begin
    CXReparse_None = 0
end

"""
    clang_defaultReparseOptions(TU) -> UInt32
Returns the set of flags that is suitable for reparsing a translation unit.

The set of flags returned provide options for [`clang_reparseTranslationUnit`](@ref) by default.
The returned flag set contains an unspecified set of optimizations geared toward common uses
of reparsing. The set of optimizations enabled may change from one version to the next.
"""
function clang_defaultReparseOptions(TU)
    ccall((:clang_defaultReparseOptions, libclang), UInt32, (CXTranslationUnit,), TU)
end

"""
    clang_reparseTranslationUnit(TU, num_unsaved_files, unsaved_files, options) -> Cint
Reparse the source files that produced this translation unit.

This routine can be used to re-parse the source files that originally created the given
translation unit, for example because those source files have changed (either on disk or as
passed via `unsaved_files`). The source code will be reparsed with the same command-line
options as it was originally parsed.

Reparsing a translation unit invalidates all cursors and source locations that refer into
that translation unit. This makes reparsing a translation unit semantically equivalent to
destroying the translation unit and then creating a new translation unit with the same
command-line arguments. However, it may be more efficient to reparse a translation unit
using this routine.

## Arguments
- `TU`: The translation unit whose contents will be re-parsed. The translation unit must originally have been built with [`clang_createTranslationUnitFromSourceFile`](@ref).
- `num_unsaved_files`: The number of unsaved file entries in `unsaved_files`.
- `unsaved_files`: The files that have not yet been saved to disk but may be required for parsing, including the contents of those files.  The contents and name of these files (as specified by [`CXUnsavedFile`](@ref)) are copied when necessary, so the client only needs to guarantee their validity until the call to this function returns.
- `options`: A bitset of options composed of the flags in [`CXReparse_Flags`](@ref). The function [`clang_defaultReparseOptions`](@ref) produces a default set of options recommended for most uses, based on the translation unit.

## Returns
0 if the sources could be reparsed.  A non-zero error code will be returned if reparsing was
impossible, such that the translation unit is invalid. In such cases, the only valid call
for `TU` is `clang_disposeTranslationUnit(TU)`.  The error codes returned by this routine
are described by the [`CXErrorCode`](@ref) enum.
"""
function clang_reparseTranslationUnit(TU, num_unsaved_files, unsaved_files, options)
    ccall((:clang_reparseTranslationUnit, libclang), Cint, (CXTranslationUnit, UInt32, Ptr{CXUnsavedFile}, UInt32), TU, num_unsaved_files, unsaved_files, options)
end

"""
Categorizes how memory is being used by a translation unit.
"""
@cenum CXTUResourceUsageKind::UInt32 begin
    CXTUResourceUsage_AST = 1
    CXTUResourceUsage_Identifiers = 2
    CXTUResourceUsage_Selectors = 3
    CXTUResourceUsage_GlobalCompletionResults = 4
    CXTUResourceUsage_SourceManagerContentCache = 5
    CXTUResourceUsage_AST_SideTables = 6
    CXTUResourceUsage_SourceManager_Membuffer_Malloc = 7
    CXTUResourceUsage_SourceManager_Membuffer_MMap = 8
    CXTUResourceUsage_ExternalASTSource_Membuffer_Malloc = 9
    CXTUResourceUsage_ExternalASTSource_Membuffer_MMap = 10
    CXTUResourceUsage_Preprocessor = 11
    CXTUResourceUsage_PreprocessingRecord = 12
    CXTUResourceUsage_SourceManager_DataStructures = 13
    CXTUResourceUsage_Preprocessor_HeaderSearch = 14
    CXTUResourceUsage_MEMORY_IN_BYTES_BEGIN = 1
    CXTUResourceUsage_MEMORY_IN_BYTES_END = 14
    CXTUResourceUsage_First = 1
    CXTUResourceUsage_Last = 14
end

"""
    clang_getTUResourceUsageName(kind) -> Cstring
Returns the human-readable null-terminated C string that represents the name of the memory category.  This string should never be freed.
"""
function clang_getTUResourceUsageName(kind)
    ccall((:clang_getTUResourceUsageName, libclang), Cstring, (CXTUResourceUsageKind,), kind)
end

struct CXTUResourceUsageEntry
    kind::CXTUResourceUsageKind  # the memory usage category
    amount::Culong               # amount of resources used. The units will depend on the resource kind.
end

"""
The memory usage of a [`CXTranslationUnit`](@ref), broken into categories.
"""
struct CXTUResourceUsage
    data::Ptr{Cvoid}                      # private data member, used for queries
    numEntries::UInt32                    # the number of entries in the 'entries' array
    entries::Ptr{CXTUResourceUsageEntry}  # an array of key-value pairs, representing the breakdown of memory usage
end

"""
    clang_getCXTUResourceUsage(TU) -> CXTUResourceUsage
Return the memory usage of a translation unit.  This object should be released with
[`clang_disposeCXTUResourceUsage`](@ref).
"""
function clang_getCXTUResourceUsage(TU)
    ccall((:clang_getCXTUResourceUsage, libclang), CXTUResourceUsage, (CXTranslationUnit,), TU)
end

"""
    clang_disposeCXTUResourceUsage(usage) -> Cvoid
"""
function clang_disposeCXTUResourceUsage(usage)
    ccall((:clang_disposeCXTUResourceUsage, libclang), Cvoid, (CXTUResourceUsage,), usage)
end

"""
    clang_getTranslationUnitTargetInfo(CTUnit) -> CXTargetInfo
Get target information for this translation unit.

The [`CXTargetInfo`](@ref) object cannot outlive the [`CXTranslationUnit`](@ref) object.
"""
function clang_getTranslationUnitTargetInfo(CTUnit)
    ccall((:clang_getTranslationUnitTargetInfo, libclang), CXTargetInfo, (CXTranslationUnit,), CTUnit)
end

"""
    clang_TargetInfo_dispose(Info) -> Cvoid
Destroy the CXTargetInfo object.
"""
function clang_TargetInfo_dispose(Info)
    ccall((:clang_TargetInfo_dispose, libclang), Cvoid, (CXTargetInfo,), Info)
end

"""
    clang_TargetInfo_getTriple(Info) -> CXString
Get the normalized target triple as a string.

Returns the empty string in case of any error.
"""
function clang_TargetInfo_getTriple(Info)
    ccall((:clang_TargetInfo_getTriple, libclang), CXString, (CXTargetInfo,), Info)
end

"""
    clang_TargetInfo_getPointerWidth(Info) -> Cint
Get the pointer width of the target in bits.

Returns -1 in case of error.
"""
function clang_TargetInfo_getPointerWidth(Info)
    ccall((:clang_TargetInfo_getPointerWidth, libclang), Cint, (CXTargetInfo,), Info)
end

"""
Describes the kind of entity that a cursor refers to.
"""
@cenum CXCursorKind::UInt32 begin
    CXCursor_UnexposedDecl = 1
    CXCursor_StructDecl = 2
    CXCursor_UnionDecl = 3
    CXCursor_ClassDecl = 4
    CXCursor_EnumDecl = 5
    CXCursor_FieldDecl = 6
    CXCursor_EnumConstantDecl = 7
    CXCursor_FunctionDecl = 8
    CXCursor_VarDecl = 9
    CXCursor_ParmDecl = 10
    CXCursor_ObjCInterfaceDecl = 11
    CXCursor_ObjCCategoryDecl = 12
    CXCursor_ObjCProtocolDecl = 13
    CXCursor_ObjCPropertyDecl = 14
    CXCursor_ObjCIvarDecl = 15
    CXCursor_ObjCInstanceMethodDecl = 16
    CXCursor_ObjCClassMethodDecl = 17
    CXCursor_ObjCImplementationDecl = 18
    CXCursor_ObjCCategoryImplDecl = 19
    CXCursor_TypedefDecl = 20
    CXCursor_CXXMethod = 21
    CXCursor_Namespace = 22
    CXCursor_LinkageSpec = 23
    CXCursor_Constructor = 24
    CXCursor_Destructor = 25
    CXCursor_ConversionFunction = 26
    CXCursor_TemplateTypeParameter = 27
    CXCursor_NonTypeTemplateParameter = 28
    CXCursor_TemplateTemplateParameter = 29
    CXCursor_FunctionTemplate = 30
    CXCursor_ClassTemplate = 31
    CXCursor_ClassTemplatePartialSpecialization = 32
    CXCursor_NamespaceAlias = 33
    CXCursor_UsingDirective = 34
    CXCursor_UsingDeclaration = 35
    CXCursor_TypeAliasDecl = 36
    CXCursor_ObjCSynthesizeDecl = 37
    CXCursor_ObjCDynamicDecl = 38
    CXCursor_CXXAccessSpecifier = 39
    CXCursor_FirstDecl = 1
    CXCursor_LastDecl = 39
    CXCursor_FirstRef = 40
    CXCursor_ObjCSuperClassRef = 40
    CXCursor_ObjCProtocolRef = 41
    CXCursor_ObjCClassRef = 42
    CXCursor_TypeRef = 43
    CXCursor_CXXBaseSpecifier = 44
    CXCursor_TemplateRef = 45
    CXCursor_NamespaceRef = 46
    CXCursor_MemberRef = 47
    CXCursor_LabelRef = 48
    CXCursor_OverloadedDeclRef = 49
    CXCursor_VariableRef = 50
    CXCursor_LastRef = 50
    CXCursor_FirstInvalid = 70
    CXCursor_InvalidFile = 70
    CXCursor_NoDeclFound = 71
    CXCursor_NotImplemented = 72
    CXCursor_InvalidCode = 73
    CXCursor_LastInvalid = 73
    CXCursor_FirstExpr = 100
    CXCursor_UnexposedExpr = 100
    CXCursor_DeclRefExpr = 101
    CXCursor_MemberRefExpr = 102
    CXCursor_CallExpr = 103
    CXCursor_ObjCMessageExpr = 104
    CXCursor_BlockExpr = 105
    CXCursor_IntegerLiteral = 106
    CXCursor_FloatingLiteral = 107
    CXCursor_ImaginaryLiteral = 108
    CXCursor_StringLiteral = 109
    CXCursor_CharacterLiteral = 110
    CXCursor_ParenExpr = 111
    CXCursor_UnaryOperator = 112
    CXCursor_ArraySubscriptExpr = 113
    CXCursor_BinaryOperator = 114
    CXCursor_CompoundAssignOperator = 115
    CXCursor_ConditionalOperator = 116
    CXCursor_CStyleCastExpr = 117
    CXCursor_CompoundLiteralExpr = 118
    CXCursor_InitListExpr = 119
    CXCursor_AddrLabelExpr = 120
    CXCursor_StmtExpr = 121
    CXCursor_GenericSelectionExpr = 122
    CXCursor_GNUNullExpr = 123
    CXCursor_CXXStaticCastExpr = 124
    CXCursor_CXXDynamicCastExpr = 125
    CXCursor_CXXReinterpretCastExpr = 126
    CXCursor_CXXConstCastExpr = 127
    CXCursor_CXXFunctionalCastExpr = 128
    CXCursor_CXXTypeidExpr = 129
    CXCursor_CXXBoolLiteralExpr = 130
    CXCursor_CXXNullPtrLiteralExpr = 131
    CXCursor_CXXThisExpr = 132
    CXCursor_CXXThrowExpr = 133
    CXCursor_CXXNewExpr = 134
    CXCursor_CXXDeleteExpr = 135
    CXCursor_UnaryExpr = 136
    CXCursor_ObjCStringLiteral = 137
    CXCursor_ObjCEncodeExpr = 138
    CXCursor_ObjCSelectorExpr = 139
    CXCursor_ObjCProtocolExpr = 140
    CXCursor_ObjCBridgedCastExpr = 141
    CXCursor_PackExpansionExpr = 142
    CXCursor_SizeOfPackExpr = 143
    CXCursor_LambdaExpr = 144
    CXCursor_ObjCBoolLiteralExpr = 145
    CXCursor_ObjCSelfExpr = 146
    CXCursor_OMPArraySectionExpr = 147
    CXCursor_ObjCAvailabilityCheckExpr = 148
    CXCursor_FixedPointLiteral = 149
    CXCursor_LastExpr = 149
    CXCursor_FirstStmt = 200
    CXCursor_UnexposedStmt = 200
    CXCursor_LabelStmt = 201
    CXCursor_CompoundStmt = 202
    CXCursor_CaseStmt = 203
    CXCursor_DefaultStmt = 204
    CXCursor_IfStmt = 205
    CXCursor_SwitchStmt = 206
    CXCursor_WhileStmt = 207
    CXCursor_DoStmt = 208
    CXCursor_ForStmt = 209
    CXCursor_GotoStmt = 210
    CXCursor_IndirectGotoStmt = 211
    CXCursor_ContinueStmt = 212
    CXCursor_BreakStmt = 213
    CXCursor_ReturnStmt = 214
    CXCursor_GCCAsmStmt = 215
    CXCursor_AsmStmt = 215
    CXCursor_ObjCAtTryStmt = 216
    CXCursor_ObjCAtCatchStmt = 217
    CXCursor_ObjCAtFinallyStmt = 218
    CXCursor_ObjCAtThrowStmt = 219
    CXCursor_ObjCAtSynchronizedStmt = 220
    CXCursor_ObjCAutoreleasePoolStmt = 221
    CXCursor_ObjCForCollectionStmt = 222
    CXCursor_CXXCatchStmt = 223
    CXCursor_CXXTryStmt = 224
    CXCursor_CXXForRangeStmt = 225
    CXCursor_SEHTryStmt = 226
    CXCursor_SEHExceptStmt = 227
    CXCursor_SEHFinallyStmt = 228
    CXCursor_MSAsmStmt = 229
    CXCursor_NullStmt = 230
    CXCursor_DeclStmt = 231
    CXCursor_OMPParallelDirective = 232
    CXCursor_OMPSimdDirective = 233
    CXCursor_OMPForDirective = 234
    CXCursor_OMPSectionsDirective = 235
    CXCursor_OMPSectionDirective = 236
    CXCursor_OMPSingleDirective = 237
    CXCursor_OMPParallelForDirective = 238
    CXCursor_OMPParallelSectionsDirective = 239
    CXCursor_OMPTaskDirective = 240
    CXCursor_OMPMasterDirective = 241
    CXCursor_OMPCriticalDirective = 242
    CXCursor_OMPTaskyieldDirective = 243
    CXCursor_OMPBarrierDirective = 244
    CXCursor_OMPTaskwaitDirective = 245
    CXCursor_OMPFlushDirective = 246
    CXCursor_SEHLeaveStmt = 247
    CXCursor_OMPOrderedDirective = 248
    CXCursor_OMPAtomicDirective = 249
    CXCursor_OMPForSimdDirective = 250
    CXCursor_OMPParallelForSimdDirective = 251
    CXCursor_OMPTargetDirective = 252
    CXCursor_OMPTeamsDirective = 253
    CXCursor_OMPTaskgroupDirective = 254
    CXCursor_OMPCancellationPointDirective = 255
    CXCursor_OMPCancelDirective = 256
    CXCursor_OMPTargetDataDirective = 257
    CXCursor_OMPTaskLoopDirective = 258
    CXCursor_OMPTaskLoopSimdDirective = 259
    CXCursor_OMPDistributeDirective = 260
    CXCursor_OMPTargetEnterDataDirective = 261
    CXCursor_OMPTargetExitDataDirective = 262
    CXCursor_OMPTargetParallelDirective = 263
    CXCursor_OMPTargetParallelForDirective = 264
    CXCursor_OMPTargetUpdateDirective = 265
    CXCursor_OMPDistributeParallelForDirective = 266
    CXCursor_OMPDistributeParallelForSimdDirective = 267
    CXCursor_OMPDistributeSimdDirective = 268
    CXCursor_OMPTargetParallelForSimdDirective = 269
    CXCursor_OMPTargetSimdDirective = 270
    CXCursor_OMPTeamsDistributeDirective = 271
    CXCursor_OMPTeamsDistributeSimdDirective = 272
    CXCursor_OMPTeamsDistributeParallelForSimdDirective = 273
    CXCursor_OMPTeamsDistributeParallelForDirective = 274
    CXCursor_OMPTargetTeamsDirective = 275
    CXCursor_OMPTargetTeamsDistributeDirective = 276
    CXCursor_OMPTargetTeamsDistributeParallelForDirective = 277
    CXCursor_OMPTargetTeamsDistributeParallelForSimdDirective = 278
    CXCursor_OMPTargetTeamsDistributeSimdDirective = 279
    CXCursor_LastStmt = 279
    CXCursor_TranslationUnit = 300
    CXCursor_FirstAttr = 400
    CXCursor_UnexposedAttr = 400
    CXCursor_IBActionAttr = 401
    CXCursor_IBOutletAttr = 402
    CXCursor_IBOutletCollectionAttr = 403
    CXCursor_CXXFinalAttr = 404
    CXCursor_CXXOverrideAttr = 405
    CXCursor_AnnotateAttr = 406
    CXCursor_AsmLabelAttr = 407
    CXCursor_PackedAttr = 408
    CXCursor_PureAttr = 409
    CXCursor_ConstAttr = 410
    CXCursor_NoDuplicateAttr = 411
    CXCursor_CUDAConstantAttr = 412
    CXCursor_CUDADeviceAttr = 413
    CXCursor_CUDAGlobalAttr = 414
    CXCursor_CUDAHostAttr = 415
    CXCursor_CUDASharedAttr = 416
    CXCursor_VisibilityAttr = 417
    CXCursor_DLLExport = 418
    CXCursor_DLLImport = 419
    CXCursor_NSReturnsRetained = 420
    CXCursor_NSReturnsNotRetained = 421
    CXCursor_NSReturnsAutoreleased = 422
    CXCursor_NSConsumesSelf = 423
    CXCursor_NSConsumed = 424
    CXCursor_ObjCException = 425
    CXCursor_ObjCNSObject = 426
    CXCursor_ObjCIndependentClass = 427
    CXCursor_ObjCPreciseLifetime = 428
    CXCursor_ObjCReturnsInnerPointer = 429
    CXCursor_ObjCRequiresSuper = 430
    CXCursor_ObjCRootClass = 431
    CXCursor_ObjCSubclassingRestricted = 432
    CXCursor_ObjCExplicitProtocolImpl = 433
    CXCursor_ObjCDesignatedInitializer = 434
    CXCursor_ObjCRuntimeVisible = 435
    CXCursor_ObjCBoxable = 436
    CXCursor_FlagEnum = 437
    CXCursor_LastAttr = 437
    CXCursor_PreprocessingDirective = 500
    CXCursor_MacroDefinition = 501
    CXCursor_MacroExpansion = 502
    CXCursor_MacroInstantiation = 502
    CXCursor_InclusionDirective = 503
    CXCursor_FirstPreprocessing = 500
    CXCursor_LastPreprocessing = 503
    CXCursor_ModuleImportDecl = 600
    CXCursor_TypeAliasTemplateDecl = 601
    CXCursor_StaticAssert = 602
    CXCursor_FriendDecl = 603
    CXCursor_FirstExtraDecl = 600
    CXCursor_LastExtraDecl = 603
    CXCursor_OverloadCandidate = 700
end

"""
A cursor representing some element in the abstract syntax tree for a translation unit.

The cursor abstraction unifies the different kinds of entities in a program--declaration,
statements, expressions, references to declarations, etc.--under a single "cursor" abstraction
with a common set of operations. Common operation for a cursor include: getting the physical
location in a source file where the cursor points, getting the name associated with a cursor,
and retrieving cursors for any child nodes of a particular cursor.

Cursors can be produced in two specific ways. [`clang_getTranslationUnitCursor`](@ref) produces
a cursor for a translation unit, from which one can use [`clang_visitChildren`](@ref) to explore
the rest of the translation unit. [`clang_getCursor`](@ref) maps from a physical source location to the
entity that resides at that location, allowing one to map from the source code into the AST.
"""
struct CXCursor
    kind::CXCursorKind
    xdata::Cint
    data::NTuple{3, Ptr{Cvoid}}
end

## Cursor manipulations

"""
    clang_getNullCursor() -> CXCursor
Retrieve the NULL cursor, which represents no entity.
"""
function clang_getNullCursor()
    ccall((:clang_getNullCursor, libclang), CXCursor, ())
end

"""
    clang_getTranslationUnitCursor(TU) -> CXCursor
Retrieve the cursor that represents the given translation unit.

The translation unit cursor can be used to start traversing the various declarations within
the given translation unit.
"""
function clang_getTranslationUnitCursor(TU)
    ccall((:clang_getTranslationUnitCursor, libclang), CXCursor, (CXTranslationUnit,), TU)
end

"""
    clang_equalCursors(cursor1, cursor2) -> UInt32
Determine whether two cursors are equivalent.
"""
function clang_equalCursors(cursor1, cursor2)
    ccall((:clang_equalCursors, libclang), UInt32, (CXCursor, CXCursor), cursor1, cursor2)
end

"""
    clang_Cursor_isNull(cursor) -> Cint
Returns non-zero if `cursor` is null.
"""
function clang_Cursor_isNull(cursor)
    ccall((:clang_Cursor_isNull, libclang), Cint, (CXCursor,), cursor)
end

"""
    clang_hashCursor(cursor) -> UInt32
Compute a hash value for the given cursor.
"""
function clang_hashCursor(cursor)
    ccall((:clang_hashCursor, libclang), UInt32, (CXCursor,), cursor)
end

"""
    clang_getCursorKind(cursor) -> CXCursorKind
Retrieve the kind of the given cursor.
"""
function clang_getCursorKind(cursor)
    ccall((:clang_getCursorKind, libclang), CXCursorKind, (CXCursor,), cursor)
end

"""
    clang_isDeclaration(cursor_kind) -> UInt32
Determine whether the given cursor kind represents a declaration.
"""
function clang_isDeclaration(cursor_kind)
    ccall((:clang_isDeclaration, libclang), UInt32, (CXCursorKind,), cursor_kind)
end

"""
    clang_isInvalidDeclaration(cursor) -> UInt32
Determine whether the given declaration is invalid.

A declaration is invalid if it could not be parsed successfully.

## Returns
non-zero if the cursor represents a declaration and it is invalid, otherwise NULL.
"""
function clang_isInvalidDeclaration(cursor)
    ccall((:clang_isInvalidDeclaration, libclang), UInt32, (CXCursor,), cursor)
end

"""
    clang_isReference(cursor_kind) -> UInt32
Determine whether the given cursor kind represents a simple reference.

Note that other kinds of cursors (such as expressions) can also refer to other cursors.
Use [`clang_getCursorReferenced`](@ref) to determine whether a particular cursor refers to
another entity.
"""
function clang_isReference(cursor_kind)
    ccall((:clang_isReference, libclang), UInt32, (CXCursorKind,), cursor_kind)
end

"""
    clang_isExpression(cursor_kind) -> UInt32
Determine whether the given cursor kind represents an expression.
"""
function clang_isExpression(cursor_kind)
    ccall((:clang_isExpression, libclang), UInt32, (CXCursorKind,), cursor_kind)
end

"""
    clang_isStatement(cursor_kind) -> UInt32
Determine whether the given cursor kind represents a statement.
"""
function clang_isStatement(cursor_kind)
    ccall((:clang_isStatement, libclang), UInt32, (CXCursorKind,), cursor_kind)
end

"""
    clang_isAttribute(cursor_kind) -> UInt32
Determine whether the given cursor kind represents an attribute.
"""
function clang_isAttribute(cursor_kind)
    ccall((:clang_isAttribute, libclang), UInt32, (CXCursorKind,), cursor_kind)
end

"""
    clang_Cursor_hasAttrs(C) -> UInt32
Determine whether the given cursor has any attributes.
"""
function clang_Cursor_hasAttrs(C)
    ccall((:clang_Cursor_hasAttrs, libclang), UInt32, (CXCursor,), C)
end

"""
    clang_isInvalid(cursor_kind) -> UInt32
Determine whether the given cursor kind represents an invalid cursor.
"""
function clang_isInvalid(cursor_kind)
    ccall((:clang_isInvalid, libclang), UInt32, (CXCursorKind,), cursor_kind)
end

"""
    clang_isTranslationUnit(cursor_kind) -> UInt32
Determine whether the given cursor kind represents a translation unit.
"""
function clang_isTranslationUnit(cursor_kind)
    ccall((:clang_isTranslationUnit, libclang), UInt32, (CXCursorKind,), cursor_kind)
end

"""
    clang_isPreprocessing(cursor_kind) -> UInt32
Determine whether the given cursor represents a preprocessing element, such as a preprocessor
directive or macro instantiation.
"""
function clang_isPreprocessing(cursor_kind)
    ccall((:clang_isPreprocessing, libclang), UInt32, (CXCursorKind,), cursor_kind)
end

"""
    clang_isUnexposed(cursor_kind) -> UInt32
Determine whether the given cursor represents a currently unexposed piece of the AST (e.g., [`CXCursor_UnexposedStmt`](@ref)).
"""
function clang_isUnexposed(cursor_kind)
    ccall((:clang_isUnexposed, libclang), UInt32, (CXCursorKind,), cursor_kind)
end

"""
Describe the linkage of the entity referred to by a cursor.
- `CXLinkage_Invalid`: This value indicates that no linkage information is available for a provided CXCursor.
- `CXLinkage_NoLinkage`: This is the linkage for variables, parameters, and so on that have automatic storage.  This covers normal (non-extern) local variables.
- `CXLinkage_Internal`: This is the linkage for static variables and static functions.
- `CXLinkage_UniqueExternal`: This is the linkage for entities with external linkage that live in C++ anonymous namespaces.
- `CXLinkage_External`: This is the linkage for entities with true, external linkage.
"""
@cenum CXLinkageKind::UInt32 begin
    CXLinkage_Invalid = 0
    CXLinkage_NoLinkage = 1
    CXLinkage_Internal = 2
    CXLinkage_UniqueExternal = 3
    CXLinkage_External = 4
end

"""
    clang_getCursorLinkage(cursor) -> CXLinkageKind
Determine the linkage of the entity referred to by a given cursor.
"""
function clang_getCursorLinkage(cursor)
    ccall((:clang_getCursorLinkage, libclang), CXLinkageKind, (CXCursor,), cursor)
end

@cenum CXVisibilityKind::UInt32 begin
    CXVisibility_Invalid = 0    # this value indicates that no visibility information is available for a provided CXCursor
    CXVisibility_Hidden = 1     # symbol not seen by the linker
    CXVisibility_Protected = 2  # symbol seen by the linker but resolves to a symbol inside this object
    CXVisibility_Default = 3    # symbol seen by the linker and acts like a normal symbol
end

"""
    clang_getCursorVisibility(cursor) -> CXVisibilityKind
Describe the visibility of the entity referred to by a cursor.

This returns the default visibility if not explicitly specified by a visibility attribute.
The default visibility may be changed by commandline arguments.

## Arguments
- `cursor`: The cursor to query.

## Returns
The visibility of the cursor.
"""
function clang_getCursorVisibility(cursor) -> CXVisibilityKind
    ccall((:clang_getCursorVisibility, libclang), CXVisibilityKind, (CXCursor,), cursor)
end

"""
    clang_getCursorAvailability(cursor) -> CXAvailabilityKind
Determine the availability of the entity that this cursor refers to, taking the current target platform into account.

## Arguments
- `cursor`: The cursor to query.

## Returns
The visibility of the cursor.
"""
function clang_getCursorAvailability(cursor)
    ccall((:clang_getCursorAvailability, libclang), CXAvailabilityKind, (CXCursor,), cursor)
end

"""
Describes the availability of a given entity on a particular platform, e.g., a particular
class might only be available on Mac OS 10.7 or newer.
"""
struct CXPlatformAvailability
    Platform::CXString      # A string that describes the platform for which this structure provides availability information. Possible values are "ios" or "macos".
    Introduced::CXVersion   # The version number in which this entity was introduced.
    Deprecated::CXVersion   # The version number in which this entity was deprecated (but is still available).
    Obsoleted::CXVersion    # The version number in which this entity was obsoleted, and therefore is no longer available.
    Unavailable::Cint       # Whether the entity is unconditionally unavailable on this platform.
    Message::CXString       # An optional message to provide to a user of this API, e.g., to suggest replacement APIs.
end

"""
    clang_getCursorPlatformAvailability(cursor, always_deprecated, deprecated_message, always_unavailable, unavailable_message, availability, availability_size) -> Cint
Determine the availability of the entity that this cursor refers to on any platforms for
which availability information is known.

## Arguments
- `cursor`: The cursor to query.
- `always_deprecated`: If non-NULL, will be set to indicate whether the entity is deprecated on all platforms.
- `deprecated_message`: If non-NULL, will be set to the message text provided along with the unconditional deprecation of this entity. The client is responsible for deallocating this string.
- `always_unavailable`: If non-NULL, will be set to indicate whether the entity is unavailable on all platforms.
- `unavailable_message`: If non-NULL, will be set to the message text provided along with the unconditional unavailability of this entity. The client is responsible for deallocating this string.
- `availability`: If non-NULL, an array of [`CXPlatformAvailability`](@ref) instances that will be populated with platform availability information, up to either the number of platforms for which availability information is available (as returned by this function) or `availability_size`, whichever is smaller.
- `availability_size`: The number of elements available in the `availability` array.

## Returns
The number of platforms (N) for which availability information is available (which is
unrelated to `availability_size`).

Note that the client is responsible for calling [`clang_disposeCXPlatformAvailability`](@ref)
to free each of the platform-availability structures returned. There are
`min(N, `availability_size`)` such structures.
"""
function clang_getCursorPlatformAvailability(cursor, always_deprecated, deprecated_message, always_unavailable, unavailable_message, availability, availability_size)
    ccall((:clang_getCursorPlatformAvailability, libclang), Cint, (CXCursor, Ptr{Cint}, Ptr{CXString}, Ptr{Cint}, Ptr{CXString}, Ptr{CXPlatformAvailability}, Cint), cursor, always_deprecated, deprecated_message, always_unavailable, unavailable_message, availability, availability_size)
end

"""
    clang_disposeCXPlatformAvailability(availability) -> Cvoid
Free the memory associated with a [`CXPlatformAvailability`](@ref) structure.
"""
function clang_disposeCXPlatformAvailability(availability)
    ccall((:clang_disposeCXPlatformAvailability, libclang), Cvoid, (Ptr{CXPlatformAvailability},), availability)
end

"""
Describe the "language" of the entity referred to by a cursor.
"""
@cenum CXLanguageKind::UInt32 begin
    CXLanguage_Invalid = 0
    CXLanguage_C = 1
    CXLanguage_ObjC = 2
    CXLanguage_CPlusPlus = 3
end

"""
    clang_getCursorLanguage(cursor) -> CXLanguageKind
Determine the "language" of the entity referred to by a given cursor.
"""
function clang_getCursorLanguage(cursor)
    ccall((:clang_getCursorLanguage, libclang), CXLanguageKind, (CXCursor,), cursor)
end

"""
Describe the "thread-local storage (TLS) kind" of the declaration referred to by a cursor.
"""
@cenum CXTLSKind::UInt32 begin
    CXTLS_None = 0
    CXTLS_Dynamic = 1
    CXTLS_Static = 2
end

"""
    clang_getCursorTLSKind(cursor) -> CXTLSKind
Determine the "thread-local storage (TLS) kind" of the declaration referred to by a cursor.
"""
function clang_getCursorTLSKind(cursor)
    ccall((:clang_getCursorTLSKind, libclang), CXTLSKind, (CXCursor,), cursor)
end

"""
    clang_Cursor_getTranslationUnit(cursor) -> CXTranslationUnit
Returns the translation unit that a cursor originated from.
"""
function clang_Cursor_getTranslationUnit(cursor)
    ccall((:clang_Cursor_getTranslationUnit, libclang), CXTranslationUnit, (CXCursor,), cursor)
end

"""
A fast container representing a set of CXCursors.
"""
const CXCursorSet = Ptr{Cvoid}

"""
    clang_createCXCursorSet() -> CXCursorSet
Creates an empty CXCursorSet.
"""
function clang_createCXCursorSet()
    ccall((:clang_createCXCursorSet, libclang), CXCursorSet, ())
end

"""
    clang_disposeCXCursorSet(cset) -> Cvoid
Disposes a CXCursorSet and releases its associated memory.
"""
function clang_disposeCXCursorSet(cset)
    ccall((:clang_disposeCXCursorSet, libclang), Cvoid, (CXCursorSet,), cset)
end

"""
    clang_CXCursorSet_contains(cset, cursor) -> UInt32
Queries a [`CXCursorSet`](@ref) to see if it contains a specific [`CXCursor`](@ref).

## Returns
non-zero if the set contains the specified cursor.
"""
function clang_CXCursorSet_contains(cset, cursor)
    ccall((:clang_CXCursorSet_contains, libclang), UInt32, (CXCursorSet, CXCursor), cset, cursor)
end

"""
    clang_CXCursorSet_insert(cset, cursor) -> UInt32
Inserts a [`CXCursor`](@ref) into a [`CXCursorSet`](@ref).

## Returns
zero if the CXCursor was already in the set, and non-zero otherwise.
"""
function clang_CXCursorSet_insert(cset, cursor)
    ccall((:clang_CXCursorSet_insert, libclang), UInt32, (CXCursorSet, CXCursor), cset, cursor)
end

"""
    clang_getCursorSemanticParent(cursor) -> CXCursor
Determine the semantic parent of the given cursor.

The semantic parent of a cursor is the cursor that semantically contains the given `cursor`.
For many declarations, the lexical and semantic parents are equivalent (the lexical parent
is returned by [`clang_getCursorLexicalParent`](@ref)). They diverge when declarations or
definitions are provided out-of-line. For example:
```c
class C {
    void f();
};

void C::f() { }
```

In the out-of-line definition of `C::f`, the semantic parent is the class `C`, of which this
function is a member. The lexical parent is the place where the declaration actually occurs
in the source code; in this case, the definition occurs in the translation unit. In general,
the lexical parent for a given entity can change without affecting the semantics of the
program, and the lexical parent of different declarations of the same entity may be different.
Changing the semantic parent of a declaration, on the other hand, can have a major impact on
semantics, and redeclarations of a particular entity should all have the same semantic context.

In the example above, both declarations of `C::f` have `C` as their semantic context, while
the lexical context of the first `C::f` is `C` and the lexical context of the second `C::f`
is the translation unit.

For global declarations, the semantic parent is the translation unit.
"""
function clang_getCursorSemanticParent(cursor)
    ccall((:clang_getCursorSemanticParent, libclang), CXCursor, (CXCursor,), cursor)
end

"""
    clang_getCursorLexicalParent(cursor) -> CXCursor
Determine the lexical parent of the given cursor.

The lexical parent of a cursor is the cursor in which the given `cursor` was actually written.
For many declarations, the lexical and semantic parents are equivalent (the semantic parent
is returned by [`clang_getCursorSemanticParent`](@ref)). They diverge when declarations or
definitions are provided out-of-line. For example:
```c
class C {
    void f();
};

void C::f() { }
```

In the out-of-line definition of `C::f`, the semantic parent is the class `C`, of which this
function is a member. The lexical parent is the place where the declaration actually occurs
in the source code; in this case, the definition occurs in the translation unit. In general,
the lexical parent for a given entity can change without affecting the semantics of the
program, and the lexical parent of different declarations of the same entity may be different.
Changing the semantic parent of a declaration, on the other hand, can have a major impact on
semantics, and redeclarations of a particular entity should all have the same semantic context.

In the example above, both declarations of `C::f` have `C` as their semantic context, while
the lexical context of the first `C::f` is `C` and the lexical context of the second `C::f`
is the translation unit.

For declarations written in the global scope, the lexical parent is the translation unit.
"""
function clang_getCursorLexicalParent(cursor)
    ccall((:clang_getCursorLexicalParent, libclang), CXCursor, (CXCursor,), cursor)
end

"""
    clang_getOverriddenCursors(cursor, overridden, num_overridden) -> Cvoid
Determine the set of methods that are overridden by the given method.

In both Objective-C and C++, a method (aka virtual member function, in C++) can override a
virtual method in a base class. For Objective-C, a method is said to override any method in
the class's base class, its protocols, or its categories' protocols, that has the same selector
and is of the same kind (class or instance). If no such method exists, the search continues
to the class's superclass, its protocols, and its categories, and so on. A method from an
Objective-C implementation is considered to override the same methods as its corresponding
method in the interface.

For C++, a virtual member function overrides any virtual member function with the same
signature that occurs in its base classes. With multiple inheritance, a virtual member
function can override several virtual member functions coming from different base classes.

In all cases, this function determines the immediate overridden method, rather than all of
the overridden methods. For example, if a method is originally declared in a class A, then
overridden in B(which in inherits from A) and also in C (which inherited from B), then the
only overridden method returned from this function when invoked on C's method will be B's
method. The client may then invoke this function again, given the previously-found overridden
methods, to map out the complete method-override set.

## Arguments
- `cursor`: A cursor representing an Objective-C or C++ method. This routine will compute the set of methods that this method overrides.
- `overridden`: A pointer whose pointee will be replaced with a pointer to an array of cursors, representing the set of overridden methods. If there are no overridden methods, the pointee will be set to NULL. The pointee must be freed via a call to [`clang_disposeOverriddenCursors`](@ref).
- `num_overridden`: A pointer to the number of overridden functions, will be set to the number of overridden functions in the array pointed to by `overridden`.
"""
function clang_getOverriddenCursors(cursor, overridden, num_overridden)
    ccall((:clang_getOverriddenCursors, libclang), Cvoid, (CXCursor, Ptr{Ptr{CXCursor}}, Ptr{UInt32}), cursor, overridden, num_overridden)
end

"""
    clang_disposeOverriddenCursors(overridden) -> Cvoid
Free the set of overridden cursors returned by [`clang_getOverriddenCursors`](@ref).
"""
function clang_disposeOverriddenCursors(overridden)
    ccall((:clang_disposeOverriddenCursors, libclang), Cvoid, (Ptr{CXCursor},), overridden)
end

"""
    clang_getIncludedFile(cursor) -> CXFile
Retrieve the file that is included by the given inclusion directive cursor.
"""
function clang_getIncludedFile(cursor)
    ccall((:clang_getIncludedFile, libclang), CXFile, (CXCursor,), cursor)
end

## Mapping between cursors and source code
# Cursors represent a location within the Abstract Syntax Tree (AST). These routines help
# map between cursors and the physical locations where the described entities occur in the
# source code. The mapping is provided in both directions, so one can map from source code
# to the AST and back.

"""
    clang_getCursor(TU, srcloc) -> CXCursor
Map a source location to the cursor that describes the entity at that location in the source code.

[`clang_getCursor`](@ref) maps an arbitrary source location within a translation unit down
to the most specific cursor that describes the entity at that location. For example, given
an expression `x + y`, invoking [`clang_getCursor`](@ref) with a source location pointing
to "x" will return the cursor for "x"; similarly for "y". If the cursor points anywhere
between "x" or "y" (e.g., on the + or the whitespace around it), [`clang_getCursor`](@ref)
will return a cursor referring to the "+" expression.

## Returns
a cursor representing the entity at the given source location, or a NULL cursor if no such entity can be found.
"""
function clang_getCursor(TU, srcloc)
    ccall((:clang_getCursor, libclang), CXCursor, (CXTranslationUnit, CXSourceLocation), TU, srcloc)
end

"""
    clang_getCursorLocation(srcloc) -> CXSourceLocation
Retrieve the physical location of the source constructor referenced by the given cursor.

The location of a declaration is typically the location of the name of that declaration,
where the name of that declaration would occur if it is unnamed, or some keyword that
introduces that particular declaration. The location of a reference is where that reference
occurs within the source code.
"""
function clang_getCursorLocation(srcloc)
    ccall((:clang_getCursorLocation, libclang), CXSourceLocation, (CXCursor,), srcloc)
end

"""
    clang_getCursorExtent(src_range) -> CXSourceRange
Retrieve the physical extent of the source construct referenced by the given cursor.

The extent of a cursor starts with the file/line/column pointing at the first character
within the source construct that the cursor refers to and ends with the last character
within that source construct. For a declaration, the extent covers the declaration itself.
For a reference, the extent covers the location of the reference (e.g., where the referenced
entity was actually used).
"""
function clang_getCursorExtent(src_range)
    ccall((:clang_getCursorExtent, libclang), CXSourceRange, (CXCursor,), src_range)
end

## Type information for CXCursors

"""
Describes the kind of type
"""
@cenum CXTypeKind::UInt32 begin
    CXType_Invalid = 0 # Represents an invalid type (e.g., where no type is available).
    CXType_Unexposed = 1  # A type whose specific kind is not exposed via this interface.
    # Builtin types
    CXType_Void = 2
    CXType_Bool = 3
    CXType_Char_U = 4
    CXType_UChar = 5
    CXType_Char16 = 6
    CXType_Char32 = 7
    CXType_UShort = 8
    CXType_UInt = 9
    CXType_ULong = 10
    CXType_ULongLong = 11
    CXType_UInt128 = 12
    CXType_Char_S = 13
    CXType_SChar = 14
    CXType_WChar = 15
    CXType_Short = 16
    CXType_Int = 17
    CXType_Long = 18
    CXType_LongLong = 19
    CXType_Int128 = 20
    CXType_Float = 21
    CXType_Double = 22
    CXType_LongDouble = 23
    CXType_NullPtr = 24
    CXType_Overload = 25
    CXType_Dependent = 26
    CXType_ObjCId = 27
    CXType_ObjCClass = 28
    CXType_ObjCSel = 29
    CXType_Float128 = 30
    CXType_Half = 31
    CXType_Float16 = 32
    CXType_ShortAccum = 33
    CXType_Accum = 34
    CXType_LongAccum = 35
    CXType_UShortAccum = 36
    CXType_UAccum = 37
    CXType_ULongAccum = 38
    CXType_FirstBuiltin = 2
    CXType_LastBuiltin = 38
    CXType_Complex = 100
    CXType_Pointer = 101
    CXType_BlockPointer = 102
    CXType_LValueReference = 103
    CXType_RValueReference = 104
    CXType_Record = 105
    CXType_Enum = 106
    CXType_Typedef = 107
    CXType_ObjCInterface = 108
    CXType_ObjCObjectPointer = 109
    CXType_FunctionNoProto = 110
    CXType_FunctionProto = 111
    CXType_ConstantArray = 112
    CXType_Vector = 113
    CXType_IncompleteArray = 114
    CXType_VariableArray = 115
    CXType_DependentSizedArray = 116
    CXType_MemberPointer = 117
    CXType_Auto = 118
    CXType_Elaborated = 119  # Represents a type that was referred to using an elaborated type keyword. E.g., struct S, or via a qualified name, e.g., N::M::type, or both.
    CXType_Pipe = 120  # OpenCL PipeType.
    # OpenCL builtin types
    CXType_OCLImage1dRO = 121
    CXType_OCLImage1dArrayRO = 122
    CXType_OCLImage1dBufferRO = 123
    CXType_OCLImage2dRO = 124
    CXType_OCLImage2dArrayRO = 125
    CXType_OCLImage2dDepthRO = 126
    CXType_OCLImage2dArrayDepthRO = 127
    CXType_OCLImage2dMSAARO = 128
    CXType_OCLImage2dArrayMSAARO = 129
    CXType_OCLImage2dMSAADepthRO = 130
    CXType_OCLImage2dArrayMSAADepthRO = 131
    CXType_OCLImage3dRO = 132
    CXType_OCLImage1dWO = 133
    CXType_OCLImage1dArrayWO = 134
    CXType_OCLImage1dBufferWO = 135
    CXType_OCLImage2dWO = 136
    CXType_OCLImage2dArrayWO = 137
    CXType_OCLImage2dDepthWO = 138
    CXType_OCLImage2dArrayDepthWO = 139
    CXType_OCLImage2dMSAAWO = 140
    CXType_OCLImage2dArrayMSAAWO = 141
    CXType_OCLImage2dMSAADepthWO = 142
    CXType_OCLImage2dArrayMSAADepthWO = 143
    CXType_OCLImage3dWO = 144
    CXType_OCLImage1dRW = 145
    CXType_OCLImage1dArrayRW = 146
    CXType_OCLImage1dBufferRW = 147
    CXType_OCLImage2dRW = 148
    CXType_OCLImage2dArrayRW = 149
    CXType_OCLImage2dDepthRW = 150
    CXType_OCLImage2dArrayDepthRW = 151
    CXType_OCLImage2dMSAARW = 152
    CXType_OCLImage2dArrayMSAARW = 153
    CXType_OCLImage2dMSAADepthRW = 154
    CXType_OCLImage2dArrayMSAADepthRW = 155
    CXType_OCLImage3dRW = 156
    CXType_OCLSampler = 157
    CXType_OCLEvent = 158
    CXType_OCLQueue = 159
    CXType_OCLReserveID = 160
    CXType_ObjCObject = 161
    CXType_ObjCTypeParam = 162
    CXType_Attributed = 163
    CXType_OCLIntelSubgroupAVCMcePayload = 164
    CXType_OCLIntelSubgroupAVCImePayload = 165
    CXType_OCLIntelSubgroupAVCRefPayload = 166
    CXType_OCLIntelSubgroupAVCSicPayload = 167
    CXType_OCLIntelSubgroupAVCMceResult = 168
    CXType_OCLIntelSubgroupAVCImeResult = 169
    CXType_OCLIntelSubgroupAVCRefResult = 170
    CXType_OCLIntelSubgroupAVCSicResult = 171
    CXType_OCLIntelSubgroupAVCImeResultSingleRefStreamout = 172
    CXType_OCLIntelSubgroupAVCImeResultDualRefStreamout = 173
    CXType_OCLIntelSubgroupAVCImeSingleRefStreamin = 174
    CXType_OCLIntelSubgroupAVCImeDualRefStreamin = 175
end

"""
Describes the calling convention of a function type
"""
@cenum CXCallingConv::UInt32 begin
    CXCallingConv_Default = 0
    CXCallingConv_C = 1
    CXCallingConv_X86StdCall = 2
    CXCallingConv_X86FastCall = 3
    CXCallingConv_X86ThisCall = 4
    CXCallingConv_X86Pascal = 5
    CXCallingConv_AAPCS = 6
    CXCallingConv_AAPCS_VFP = 7
    CXCallingConv_X86RegCall = 8
    CXCallingConv_IntelOclBicc = 9
    CXCallingConv_Win64 = 10
    CXCallingConv_X86_64Win64 = 10  # Alias for compatibility with older versions of API
    CXCallingConv_X86_64SysV = 11
    CXCallingConv_X86VectorCall = 12
    CXCallingConv_Swift = 13
    CXCallingConv_PreserveMost = 14
    CXCallingConv_PreserveAll = 15
    CXCallingConv_AArch64VectorCall = 16
    CXCallingConv_Invalid = 100
    CXCallingConv_Unexposed = 200
end

"""
The type of an element in the abstract syntax tree.
"""
struct CXType
    kind::CXTypeKind
    data::NTuple{2, Ptr{Cvoid}}
end

"""
    clang_getCursorType(C) -> CXType
Retrieve the type of a CXCursor (if any).
"""
function clang_getCursorType(C)
    ccall((:clang_getCursorType, libclang), CXType, (CXCursor,), C)
end

"""
    clang_getTypeSpelling(CT) -> CXString
Pretty-print the underlying type using the rules of the language of the translation unit
from which it came.

If the type is invalid, an empty string is returned.
"""
function clang_getTypeSpelling(CT)
    ccall((:clang_getTypeSpelling, libclang), CXString, (CXType,), CT)
end

"""
    clang_getTypedefDeclUnderlyingType(C) -> CXType
Retrieve the underlying type of a typedef declaration.

If the cursor does not reference a typedef declaration, an invalid type is returned.
"""
function clang_getTypedefDeclUnderlyingType(C)
    ccall((:clang_getTypedefDeclUnderlyingType, libclang), CXType, (CXCursor,), C)
end

"""
    clang_getEnumDeclIntegerType(C) -> CXType
Retrieve the integer type of an enum declaration.

If the cursor does not reference an enum declaration, an invalid type is returned.
"""
function clang_getEnumDeclIntegerType(C)
    ccall((:clang_getEnumDeclIntegerType, libclang), CXType, (CXCursor,), C)
end

"""
    clang_getEnumConstantDeclValue(C) -> Clonglong
Retrieve the integer value of an enum constant declaration as a `signed long long`.

If the cursor does not reference an enum constant declaration, LLONG_MIN is returned.
Since this is also potentially a valid constant value, the kind of the cursor must be verified
before calling this function.
"""
function clang_getEnumConstantDeclValue(C)
    ccall((:clang_getEnumConstantDeclValue, libclang), Clonglong, (CXCursor,), C)
end

"""
    clang_getEnumConstantDeclUnsignedValue(C) -> Culonglong
Retrieve the integer value of an enum constant declaration as an `unsigned long long`.

If the cursor does not reference an enum constant declaration, ULLONG_MAX is returned.
Since this is also potentially a valid constant value, the kind of the cursor must be
verified before calling this function.
"""
function clang_getEnumConstantDeclUnsignedValue(C)
    ccall((:clang_getEnumConstantDeclUnsignedValue, libclang), Culonglong, (CXCursor,), C)
end

"""
    clang_getFieldDeclBitWidth(C) -> Cint
Retrieve the bit width of a bit field declaration as an integer.

If a cursor that is not a bit field declaration is passed in, -1 is returned.
"""
function clang_getFieldDeclBitWidth(C)
    ccall((:clang_getFieldDeclBitWidth, libclang), Cint, (CXCursor,), C)
end

"""
    clang_Cursor_getNumArguments(C) -> Cint
Retrieve the number of non-variadic arguments associated with a given cursor.

The number of arguments can be determined for calls as well as for declarations of functions
or methods. For other cursors -1 is returned.
"""
function clang_Cursor_getNumArguments(C)
    ccall((:clang_Cursor_getNumArguments, libclang), Cint, (CXCursor,), C)
end

"""
    clang_Cursor_getArgument(C, i) -> CXCursor
Retrieve the argument cursor of a function or method.

The argument cursor can be determined for calls as well as for declarations of functions or
methods. For other cursors and for invalid indices, an invalid cursor is returned.
"""
function clang_Cursor_getArgument(C, i)
    ccall((:clang_Cursor_getArgument, libclang), CXCursor, (CXCursor, UInt32), C, i)
end

"""
Describes the kind of a template argument.

See the definition of `llvm::clang::TemplateArgument::ArgKind` for full element descriptions.
"""
@cenum CXTemplateArgumentKind::UInt32 begin
    CXTemplateArgumentKind_Null = 0
    CXTemplateArgumentKind_Type = 1
    CXTemplateArgumentKind_Declaration = 2
    CXTemplateArgumentKind_NullPtr = 3
    CXTemplateArgumentKind_Integral = 4
    CXTemplateArgumentKind_Template = 5
    CXTemplateArgumentKind_TemplateExpansion = 6
    CXTemplateArgumentKind_Expression = 7
    CXTemplateArgumentKind_Pack = 8
    # Indicates an error case, preventing the kind from being deduced
    CXTemplateArgumentKind_Invalid = 9
end

"""
    clang_Cursor_getNumTemplateArguments(C) -> Cint
Returns the number of template args of a function decl representing a template specialization.

If the argument cursor cannot be converted into a template function declaration, -1 is returned.

For example, for the following declaration and specialization:

```c
template <typename T, int kInt, bool kBool>
void foo() { ... }

template <>
void foo<float, -7, true>();
```

The value 3 would be returned from this call.
"""
function clang_Cursor_getNumTemplateArguments(C)
    ccall((:clang_Cursor_getNumTemplateArguments, libclang), Cint, (CXCursor,), C)
end

"""
    clang_Cursor_getTemplateArgumentKind(C, I) -> CXTemplateArgumentKind
Retrieve the kind of the I'th template argument of the CXCursor `C`.

If the argument CXCursor does not represent a FunctionDecl, an invalid template argument kind is returned.

For example, for the following declaration and specialization:

```c
template <typename T, int kInt, bool kBool>
void foo() { ... }

template <>
void foo<float, -7, true>();
```
For I = 0, 1, and 2, Type, Integral, and Integral will be returned, respectively.
"""
function clang_Cursor_getTemplateArgumentKind(C, I)
    ccall((:clang_Cursor_getTemplateArgumentKind, libclang), CXTemplateArgumentKind, (CXCursor, UInt32), C, I)
end

"""
    clang_Cursor_getTemplateArgumentType(C, I) -> CXType
Retrieve a CXType representing the type of a TemplateArgument of a function decl representing a template specialization.

If the argument CXCursor does not represent a FunctionDecl whose I'th template argument has
a kind of CXTemplateArgKind_Integral, an invalid type is returned.

For example, for the following declaration and specialization:
```c
template <typename T, int kInt, bool kBool>
void foo() { ... }

template <>
void foo<float, -7, true>();
```
If called with I = 0, "float", will be returned.
Invalid types will be returned for I == 1 or 2.
"""
function clang_Cursor_getTemplateArgumentType(C, I)
    ccall((:clang_Cursor_getTemplateArgumentType, libclang), CXType, (CXCursor, UInt32), C, I)
end

"""
    clang_Cursor_getTemplateArgumentValue(C, I) -> Clonglong
Retrieve the value of an Integral TemplateArgument (of a function decl representing a
template specialization) as a signed long long.

It is undefined to call this function on a CXCursor that does not represent a FunctionDecl
or whose I'th template argument is not an integral value.

For example, for the following declaration and specialization:

```c
template <typename T, int kInt, bool kBool>
void foo() { ... }

template <>
void foo<float, -7, true>();
```

If called with I = 1 or 2, -7 or true will be returned, respectively.
For I == 0, this function's behavior is undefined.
"""
function clang_Cursor_getTemplateArgumentValue(C, I)
    ccall((:clang_Cursor_getTemplateArgumentValue, libclang), Clonglong, (CXCursor, UInt32), C, I)
end

"""
    clang_Cursor_getTemplateArgumentUnsignedValue(C, I) -> Culonglong
Retrieve the value of an Integral TemplateArgument (of a function decl representing a
template specialization) as an unsigned long long.

It is undefined to call this function on a CXCursor that does not represent a FunctionDecl
or whose I'th template argument is not an integral value.

For example, for the following declaration and specialization:
```c
template <typename T, int kInt, bool kBool>
void foo() { ... }

template <>
void foo<float, 2147483649, true>();
```
If called with I = 1 or 2, 2147483649 or true will be returned, respectively.
For I == 0, this function's behavior is undefined.
"""
function clang_Cursor_getTemplateArgumentUnsignedValue(C, I)
    ccall((:clang_Cursor_getTemplateArgumentUnsignedValue, libclang), Culonglong, (CXCursor, UInt32), C, I)
end

"""
    clang_equalTypes(A, B) -> UInt32
Determine whether two CXTypes represent the same type.

## Returns
non-zero if the CXTypes represent the same type and zero otherwise.
"""
function clang_equalTypes(A, B)
    ccall((:clang_equalTypes, libclang), UInt32, (CXType, CXType), A, B)
end

"""
    clang_getCanonicalType(T) -> CXType
Return the canonical type for a CXType.

Clang's type system explicitly models typedefs and all the ways a specific type can be
represented.  The canonical type is the underlying type with all the "sugar" removed.
For example, if 'T' is a typedef for 'int', the canonical type for 'T' would be 'int'.
"""
function clang_getCanonicalType(T)
    ccall((:clang_getCanonicalType, libclang), CXType, (CXType,), T)
end

"""
    clang_isConstQualifiedType(T) -> UInt32
Determine whether a CXType has the "const" qualifier set, without looking through typedefs
that may have added "const" at a different level.
"""
function clang_isConstQualifiedType(T)
    ccall((:clang_isConstQualifiedType, libclang), UInt32, (CXType,), T)
end

"""
    clang_Cursor_isMacroFunctionLike(C) -> UInt32
Determine whether a  CXCursor that is a macro, is function like.
"""
function clang_Cursor_isMacroFunctionLike(C)
    ccall((:clang_Cursor_isMacroFunctionLike, libclang), UInt32, (CXCursor,), C)
end

"""
    clang_Cursor_isMacroBuiltin(C) -> UInt32
Determine whether a CXCursor that is a macro, is a builtin one.
"""
function clang_Cursor_isMacroBuiltin(C)
    ccall((:clang_Cursor_isMacroBuiltin, libclang), UInt32, (CXCursor,), C)
end

"""
    clang_Cursor_isFunctionInlined(C) -> UInt32
Determine whether a CXCursor that is a function declaration, is an inline declaration.
"""
function clang_Cursor_isFunctionInlined(C)
    ccall((:clang_Cursor_isFunctionInlined, libclang), UInt32, (CXCursor,), C)
end

"""
    clang_isVolatileQualifiedType(T) -> UInt32
Determine whether a CXType has the "volatile" qualifier set, without looking through typedefs
that may have added "volatile" at a different level.
"""
function clang_isVolatileQualifiedType(T)
    ccall((:clang_isVolatileQualifiedType, libclang), UInt32, (CXType,), T)
end

"""
    clang_isRestrictQualifiedType(T) -> UInt32
Determine whether a CXType has the "restrict" qualifier set, without looking through typedefs
that may have added "restrict" at a different level.
"""
function clang_isRestrictQualifiedType(T)
    ccall((:clang_isRestrictQualifiedType, libclang), UInt32, (CXType,), T)
end

"""
    clang_getAddressSpace(T) -> UInt32
Returns the address space of the given type.
"""
function clang_getAddressSpace(T)
    ccall((:clang_getAddressSpace, libclang), UInt32, (CXType,), T)
end

"""
    clang_getTypedefName(CT) -> CXString
Returns the typedef name of the given type.
"""
function clang_getTypedefName(CT)
    ccall((:clang_getTypedefName, libclang), CXString, (CXType,), CT)
end

"""
    clang_getPointeeType(T) -> CXType
For pointer types, returns the type of the pointee.
"""
function clang_getPointeeType(T)
    ccall((:clang_getPointeeType, libclang), CXType, (CXType,), T)
end

"""
    clang_getTypeDeclaration(T) -> CXCursor
Return the cursor for the declaration of the given type.
"""
function clang_getTypeDeclaration(T)
    ccall((:clang_getTypeDeclaration, libclang), CXCursor, (CXType,), T)
end

"""
    clang_getDeclObjCTypeEncoding(C) -> CXString
Returns the Objective-C type encoding for the specified declaration.
"""
function clang_getDeclObjCTypeEncoding(C)
    ccall((:clang_getDeclObjCTypeEncoding, libclang), CXString, (CXCursor,), C)
end

"""
    clang_Type_getObjCEncoding(type) -> CXString
Returns the Objective-C type encoding for the specified CXType.
"""
function clang_Type_getObjCEncoding(type)
    ccall((:clang_Type_getObjCEncoding, libclang), CXString, (CXType,), type)
end

"""
    clang_getTypeKindSpelling(K) -> CXString
Retrieve the spelling of a given [`CXTypeKind`](@ref).
"""
function clang_getTypeKindSpelling(K)
    ccall((:clang_getTypeKindSpelling, libclang), CXString, (CXTypeKind,), K)
end

"""
    clang_getFunctionTypeCallingConv(T) -> CXCallingConv
Retrieve the calling convention associated with a function type.

If a non-function type is passed in, [`CXCallingConv_Invalid`](@ref) is returned.
"""
function clang_getFunctionTypeCallingConv(T)
    ccall((:clang_getFunctionTypeCallingConv, libclang), CXCallingConv, (CXType,), T)
end

"""
    clang_getResultType(T) -> CXType
Retrieve the return type associated with a function type.

If a non-function type is passed in, an invalid type is returned.
"""
function clang_getResultType(T)
    ccall((:clang_getResultType, libclang), CXType, (CXType,), T)
end

"""
    clang_getExceptionSpecificationType(T) -> Cint
Retrieve the exception specification type associated with a function type.
This is a value of type CXCursor_ExceptionSpecificationKind.

If a non-function type is passed in, an error code of -1 is returned.
"""
function clang_getExceptionSpecificationType(T)
    ccall((:clang_getExceptionSpecificationType, libclang), Cint, (CXType,), T)
end

"""
    clang_getNumArgTypes(T) -> Cint
Retrieve the number of non-variadic parameters associated with a function type.

If a non-function type is passed in, -1 is returned.
"""
function clang_getNumArgTypes(T)
    ccall((:clang_getNumArgTypes, libclang), Cint, (CXType,), T)
end

"""
    clang_getArgType(T, i) -> CXType
Retrieve the type of a parameter of a function type.

If a non-function type is passed in or the function does not have enough parameters, an
invalid type is returned.
"""
function clang_getArgType(T, i)
    ccall((:clang_getArgType, libclang), CXType, (CXType, UInt32), T, i)
end

"""
    clang_Type_getObjCObjectBaseType(T) -> CXType
Retrieves the base type of the ObjCObjectType.

If the type is not an ObjC object, an invalid type is returned.
"""
function clang_Type_getObjCObjectBaseType(T)
    ccall((:clang_Type_getObjCObjectBaseType, libclang), CXType, (CXType,), T)
end

"""
    clang_Type_getNumObjCProtocolRefs(T) -> UInt32
Retrieve the number of protocol references associated with an ObjC object/id.

If the type is not an ObjC object, 0 is returned.
"""
function clang_Type_getNumObjCProtocolRefs(T)
    ccall((:clang_Type_getNumObjCProtocolRefs, libclang), UInt32, (CXType,), T)
end

"""
    clang_Type_getObjCProtocolDecl(T, i) -> CXCursor
Retrieve the decl for a protocol reference for an ObjC object/id.

If the type is not an ObjC object or there are not enough protocol references, an invalid
cursor is returned.
"""
function clang_Type_getObjCProtocolDecl(T, i)
    ccall((:clang_Type_getObjCProtocolDecl, libclang), CXCursor, (CXType, UInt32), T, i)
end

"""
    clang_Type_getNumObjCTypeArgs(T) -> UInt32
Retreive the number of type arguments associated with an ObjC object.

If the type is not an ObjC object, 0 is returned.
"""
function clang_Type_getNumObjCTypeArgs(T)
    ccall((:clang_Type_getNumObjCTypeArgs, libclang), UInt32, (CXType,), T)
end

"""
    clang_Type_getObjCTypeArg(T, i) -> CXType
Retrieve a type argument associated with an ObjC object.

If the type is not an ObjC or the index is not valid, an invalid type is returned.
"""
function clang_Type_getObjCTypeArg(T, i)
    ccall((:clang_Type_getObjCTypeArg, libclang), CXType, (CXType, UInt32), T, i)
end

"""
    clang_isFunctionTypeVariadic(T) -> UInt32
Return 1 if the CXType is a variadic function type, and 0 otherwise.
"""
function clang_isFunctionTypeVariadic(T)
    ccall((:clang_isFunctionTypeVariadic, libclang), UInt32, (CXType,), T)
end

"""
    clang_getCursorResultType(C) -> CXType
Retrieve the return type associated with a given cursor.

This only returns a valid type if the cursor refers to a function or method.
"""
function clang_getCursorResultType(C)
    ccall((:clang_getCursorResultType, libclang), CXType, (CXCursor,), C)
end

"""
    clang_getCursorExceptionSpecificationType(C) -> Cint
Retrieve the exception specification type associated with a given cursor.
This is a value of type CXCursor_ExceptionSpecificationKind.

This only returns a valid result if the cursor refers to a function or method.
"""
function clang_getCursorExceptionSpecificationType(C)
    ccall((:clang_getCursorExceptionSpecificationType, libclang), Cint, (CXCursor,), C)
end

"""
    clang_isPODType(T) -> UInt32
Return 1 if the CXType is a POD (plain old data) type, and 0 otherwise.
"""
function clang_isPODType(T)
    ccall((:clang_isPODType, libclang), UInt32, (CXType,), T)
end

"""
    clang_getElementType(T) -> CXType
Return the element type of an array, complex, or vector type.

If a type is passed in that is not an array, complex, or vector type, an invalid type is returned.
"""
function clang_getElementType(T)
    ccall((:clang_getElementType, libclang), CXType, (CXType,), T)
end

"""
    clang_getNumElements(T) -> Clonglong
Return the number of elements of an array or vector type.

If a type is passed in that is not an array or vector type, -1 is returned.
"""
function clang_getNumElements(T)
    ccall((:clang_getNumElements, libclang), Clonglong, (CXType,), T)
end

"""
    clang_getArrayElementType(T) -> CXType
Return the element type of an array type.

If a non-array type is passed in, an invalid type is returned.
"""
function clang_getArrayElementType(T)
    ccall((:clang_getArrayElementType, libclang), CXType, (CXType,), T)
end

"""
    clang_getArraySize(T) -> Clonglong
Return the array size of a constant array.

If a non-array type is passed in, -1 is returned.
"""
function clang_getArraySize(T)
    ccall((:clang_getArraySize, libclang), Clonglong, (CXType,), T)
end

"""
    clang_Type_getNamedType(T) -> CXType
Retrieve the type named by the qualified-id.

If a non-elaborated type is passed in, an invalid type is returned.
"""
function clang_Type_getNamedType(T)
    ccall((:clang_Type_getNamedType, libclang), CXType, (CXType,), T)
end

"""
    clang_Type_isTransparentTagTypedef(T) -> UInt32
Determine if a typedef is 'transparent' tag.

A typedef is considered 'transparent' if it shares a name and spelling location with its
underlying tag type, as is the case with the NS_ENUM macro.

## Returns
non-zero if transparent and zero otherwise.
"""
function clang_Type_isTransparentTagTypedef(T)
    ccall((:clang_Type_isTransparentTagTypedef, libclang), UInt32, (CXType,), T)
end


@cenum CXTypeNullabilityKind::UInt32 begin
    CXTypeNullability_NonNull = 0       # Values of this type can never be null
    CXTypeNullability_Nullable = 1      # Values of this type can be null
    CXTypeNullability_Unspecified = 2   # Whether values of this type can be null is (explicitly) unspecified. This captures a (fairly rare) case where we can't conclude anything about the nullability of the type even though it has been considered.
    CXTypeNullability_Invalid = 3       # Nullability is not applicable to this type
end

"""
    clang_Type_getNullability(T) -> CXTypeNullabilityKind
Retrieve the nullability kind of a pointer type.
"""
function clang_Type_getNullability(T)
    ccall((:clang_Type_getNullability, libclang), CXTypeNullabilityKind, (CXType,), T)
end

"""
List the possible error codes for [`clang_Type_getSizeOf`](@ref), [`clang_Type_getAlignOf`](@ref),
[`clang_Type_getOffsetOf`](@ref) and [`clang_Cursor_getOffsetOf`](@ref).

A value of this enumeration type can be returned if the target type is not a valid argument
to sizeof, alignof or offsetof.
"""
@cenum CXTypeLayoutError::Int32 begin
    CXTypeLayoutError_Invalid = -1          # Type is of kind `CXType_Invalid`
    CXTypeLayoutError_Incomplete = -2       # The type is an incomplete Type
    CXTypeLayoutError_Dependent = -3        # The type is a dependent Type
    CXTypeLayoutError_NotConstantSize = -4  # The type is not a constant size type
    CXTypeLayoutError_InvalidFieldName = -5 # The Field name is not valid for this record
end

"""

"""
function clang_Type_getAlignOf(T)
    ccall((:clang_Type_getAlignOf, libclang), Clonglong, (CXType,), T)
end

"""

"""
function clang_Type_getClassType(T)
    ccall((:clang_Type_getClassType, libclang), CXType, (CXType,), T)
end

"""

"""
function clang_Type_getSizeOf(T)
    ccall((:clang_Type_getSizeOf, libclang), Clonglong, (CXType,), T)
end

"""

"""
function clang_Type_getOffsetOf(T, S)
    ccall((:clang_Type_getOffsetOf, libclang), Clonglong, (CXType, Cstring), T, S)
end

"""

"""
function clang_Type_getModifiedType(T)
    ccall((:clang_Type_getModifiedType, libclang), CXType, (CXType,), T)
end

"""

"""
function clang_Cursor_getOffsetOfField(C)
    ccall((:clang_Cursor_getOffsetOfField, libclang), Clonglong, (CXCursor,), C)
end

"""

"""
function clang_Cursor_isAnonymous(C)
    ccall((:clang_Cursor_isAnonymous, libclang), UInt32, (CXCursor,), C)
end

@cenum CXRefQualifierKind::UInt32 begin
    CXRefQualifier_None = 0     # no ref-qualifier was provided
    CXRefQualifier_LValue = 1   # an lvalue ref-qualifier was provided (`&`)
    CXRefQualifier_RValue = 2   # an rvalue ref-qualifier was provided (`&&`)
end

"""

"""
function clang_Type_getNumTemplateArguments(T)
    ccall((:clang_Type_getNumTemplateArguments, libclang), Cint, (CXType,), T)
end

"""

"""
function clang_Type_getTemplateArgumentAsType(T, i)
    ccall((:clang_Type_getTemplateArgumentAsType, libclang), CXType, (CXType, UInt32), T, i)
end

"""

"""
function clang_Type_getCXXRefQualifier(T)
    ccall((:clang_Type_getCXXRefQualifier, libclang), CXRefQualifierKind, (CXType,), T)
end

"""

"""
function clang_Cursor_isBitField(C)
    ccall((:clang_Cursor_isBitField, libclang), UInt32, (CXCursor,), C)
end

"""

"""
function clang_isVirtualBase(arg1)
    ccall((:clang_isVirtualBase, libclang), UInt32, (CXCursor,), arg1)
end

"""
Represents the C++ access control level to a base class for a cursor with kind [`CX_CXXBaseSpecifier`](@ref).
"""
@cenum CX_CXXAccessSpecifier::UInt32 begin
    CX_CXXInvalidAccessSpecifier = 0
    CX_CXXPublic = 1
    CX_CXXProtected = 2
    CX_CXXPrivate = 3
end


"""
    clang_getCXXAccessSpecifier(cursor)
Returns the access control level for the referenced object.

If the cursor refers to a C++ declaration, its access control level within its parent scope
is returned. Otherwise, if the cursor refers to a base specifier or access specifier, the
specifier itself is returned.
"""
function clang_getCXXAccessSpecifier(cursor)
    ccall((:clang_getCXXAccessSpecifier, libclang), CX_CXXAccessSpecifier, (CXCursor,), cursor)
end

"""
Represents the storage classes as declared in the source. `CX_SC_Invalid` was added for the
case that the passed cursor in not a declaration.
"""
@cenum CX_StorageClass::UInt32 begin
    CX_SC_Invalid = 0
    CX_SC_None = 1
    CX_SC_Extern = 2
    CX_SC_Static = 3
    CX_SC_PrivateExtern = 4
    CX_SC_OpenCLWorkGroupLocal = 5
    CX_SC_Auto = 6
    CX_SC_Register = 7
end

"""

"""
function clang_Cursor_getStorageClass(arg1)
    ccall((:clang_Cursor_getStorageClass, libclang), CX_StorageClass, (CXCursor,), arg1)
end

"""

"""
function clang_getNumOverloadedDecls(cursor)
    ccall((:clang_getNumOverloadedDecls, libclang), UInt32, (CXCursor,), cursor)
end

"""

"""
function clang_getOverloadedDecl(cursor, index)
    ccall((:clang_getOverloadedDecl, libclang), CXCursor, (CXCursor, UInt32), cursor, index)
end

"""

"""
function clang_getIBOutletCollectionType(arg1)
    ccall((:clang_getIBOutletCollectionType, libclang), CXType, (CXCursor,), arg1)
end

## Traversing the AST with cursors
# These routines provide the ability to traverse the abstract syntax tree using cursors.

"""
Describes how the traversal of the children of a particular cursor should proceed after
visiting a particular child cursor.

A value of this enumeration type should be returned by each [`CXCursorVisitor`](@ref) to
indicate how [`clang_visitChildren`](@ref) proceed.
"""
@cenum CXChildVisitResult::UInt32 begin
    CXChildVisit_Break = 0      # terminates the cursor traversal
    CXChildVisit_Continue = 1   # continues the cursor traversal with the next sibling of the cursor just visited, without visiting its children
    CXChildVisit_Recurse = 2    # recursively traverse the children of this cursor, using the same visitor and client data
end

"""
Visitor invoked for each cursor found by a traversal.

This visitor function will be invoked for each cursor found by [`clang_visitCursorChildren`](@ref).
Its first argument is the cursor being visited, its second argument is the parent visitor for
that cursor, and its third argument is the client data provided to [`clang_visitCursorChildren`](@ref).

The visitor should return one of the [`CXChildVisitResult`](@ref) values to direct [`clang_visitCursorChildren`](@ref).

```c
typedef enum CXChildVisitResult (*CXCursorVisitor)(CXCursor cursor, CXCursor parent, CXClientData client_data);
```
"""
const CXCursorVisitor = Ptr{Cvoid}


"""

"""
function clang_visitChildren(parent, visitor, client_data)
    ccall((:clang_visitChildren, libclang), UInt32, (CXCursor, CXCursorVisitor, CXClientData), parent, visitor, client_data)
end

##  Cross-referencing in the AST

"""

"""
function clang_getCursorUSR(arg1)
    ccall((:clang_getCursorUSR, libclang), CXString, (CXCursor,), arg1)
end

"""

"""
function clang_constructUSR_ObjCClass(class_name)
    ccall((:clang_constructUSR_ObjCClass, libclang), CXString, (Cstring,), class_name)
end

"""

"""
function clang_constructUSR_ObjCCategory(class_name, category_name)
    ccall((:clang_constructUSR_ObjCCategory, libclang), CXString, (Cstring, Cstring), class_name, category_name)
end

"""

"""
function clang_constructUSR_ObjCProtocol(protocol_name)
    ccall((:clang_constructUSR_ObjCProtocol, libclang), CXString, (Cstring,), protocol_name)
end

"""

"""
function clang_constructUSR_ObjCIvar(name, classUSR)
    ccall((:clang_constructUSR_ObjCIvar, libclang), CXString, (Cstring, CXString), name, classUSR)
end

"""

"""
function clang_constructUSR_ObjCMethod(name, isInstanceMethod, classUSR)
    ccall((:clang_constructUSR_ObjCMethod, libclang), CXString, (Cstring, UInt32, CXString), name, isInstanceMethod, classUSR)
end

"""

"""
function clang_constructUSR_ObjCProperty(property, classUSR)
    ccall((:clang_constructUSR_ObjCProperty, libclang), CXString, (Cstring, CXString), property, classUSR)
end

"""

"""
function clang_getCursorSpelling(arg1)
    ccall((:clang_getCursorSpelling, libclang), CXString, (CXCursor,), arg1)
end

"""

"""
function clang_Cursor_getSpellingNameRange(arg1, pieceIndex, options)
    ccall((:clang_Cursor_getSpellingNameRange, libclang), CXSourceRange, (CXCursor, UInt32, UInt32), arg1, pieceIndex, options)
end

"""
Opaque pointer representing a policy that controls pretty printing for [`clang_getCursorPrettyPrinted`](@ref).
"""
const CXPrintingPolicy = Ptr{Cvoid}

"""
Properties for the printing policy.

See `clang::PrintingPolicy` for more information.
"""
@cenum CXPrintingPolicyProperty::UInt32 begin
    CXPrintingPolicy_Indentation = 0
    CXPrintingPolicy_SuppressSpecifiers = 1
    CXPrintingPolicy_SuppressTagKeyword = 2
    CXPrintingPolicy_IncludeTagDefinition = 3
    CXPrintingPolicy_SuppressScope = 4
    CXPrintingPolicy_SuppressUnwrittenScope = 5
    CXPrintingPolicy_SuppressInitializers = 6
    CXPrintingPolicy_ConstantArraySizeAsWritten = 7
    CXPrintingPolicy_AnonymousTagLocations = 8
    CXPrintingPolicy_SuppressStrongLifetime = 9
    CXPrintingPolicy_SuppressLifetimeQualifiers = 10
    CXPrintingPolicy_SuppressTemplateArgsInCXXConstructors = 11
    CXPrintingPolicy_Bool = 12
    CXPrintingPolicy_Restrict = 13
    CXPrintingPolicy_Alignof = 14
    CXPrintingPolicy_UnderscoreAlignof = 15
    CXPrintingPolicy_UseVoidForZeroParams = 16
    CXPrintingPolicy_TerseOutput = 17
    CXPrintingPolicy_PolishForDeclaration = 18
    CXPrintingPolicy_Half = 19
    CXPrintingPolicy_MSWChar = 20
    CXPrintingPolicy_IncludeNewlines = 21
    CXPrintingPolicy_MSVCFormatting = 22
    CXPrintingPolicy_ConstantsAsWritten = 23
    CXPrintingPolicy_SuppressImplicitBase = 24
    CXPrintingPolicy_FullyQualifiedName = 25
    CXPrintingPolicy_LastProperty = 25
end


"""

"""
function clang_PrintingPolicy_getProperty(Policy, Property)
    ccall((:clang_PrintingPolicy_getProperty, libclang), UInt32, (CXPrintingPolicy, CXPrintingPolicyProperty), Policy, Property)
end

"""

"""
function clang_PrintingPolicy_setProperty(Policy, Property, Value)
    ccall((:clang_PrintingPolicy_setProperty, libclang), Cvoid, (CXPrintingPolicy, CXPrintingPolicyProperty, UInt32), Policy, Property, Value)
end

"""

"""
function clang_getCursorPrintingPolicy(arg1)
    ccall((:clang_getCursorPrintingPolicy, libclang), CXPrintingPolicy, (CXCursor,), arg1)
end

"""

"""
function clang_PrintingPolicy_dispose(Policy)
    ccall((:clang_PrintingPolicy_dispose, libclang), Cvoid, (CXPrintingPolicy,), Policy)
end

"""

"""
function clang_getCursorPrettyPrinted(Cursor, Policy)
    ccall((:clang_getCursorPrettyPrinted, libclang), CXString, (CXCursor, CXPrintingPolicy), Cursor, Policy)
end

"""

"""
function clang_getCursorDisplayName(arg1)
    ccall((:clang_getCursorDisplayName, libclang), CXString, (CXCursor,), arg1)
end

"""

"""
function clang_getCursorReferenced(arg1)
    ccall((:clang_getCursorReferenced, libclang), CXCursor, (CXCursor,), arg1)
end

"""

"""
function clang_getCursorDefinition(arg1)
    ccall((:clang_getCursorDefinition, libclang), CXCursor, (CXCursor,), arg1)
end

"""

"""
function clang_isCursorDefinition(arg1)
    ccall((:clang_isCursorDefinition, libclang), UInt32, (CXCursor,), arg1)
end

"""

"""
function clang_getCanonicalCursor(arg1)
    ccall((:clang_getCanonicalCursor, libclang), CXCursor, (CXCursor,), arg1)
end

"""

"""
function clang_Cursor_getObjCSelectorIndex(arg1)
    ccall((:clang_Cursor_getObjCSelectorIndex, libclang), Cint, (CXCursor,), arg1)
end

"""

"""
function clang_Cursor_isDynamicCall(C)
    ccall((:clang_Cursor_isDynamicCall, libclang), Cint, (CXCursor,), C)
end

"""

"""
function clang_Cursor_getReceiverType(C)
    ccall((:clang_Cursor_getReceiverType, libclang), CXType, (CXCursor,), C)
end

"""
Property attributes for a [`CXCursor_ObjCPropertyDecl`](@ref).
"""
@cenum CXObjCPropertyAttrKind::UInt32 begin
    CXObjCPropertyAttr_noattr = 0
    CXObjCPropertyAttr_readonly = 1
    CXObjCPropertyAttr_getter = 2
    CXObjCPropertyAttr_assign = 4
    CXObjCPropertyAttr_readwrite = 8
    CXObjCPropertyAttr_retain = 16
    CXObjCPropertyAttr_copy = 32
    CXObjCPropertyAttr_nonatomic = 64
    CXObjCPropertyAttr_setter = 128
    CXObjCPropertyAttr_atomic = 256
    CXObjCPropertyAttr_weak = 512
    CXObjCPropertyAttr_strong = 1024
    CXObjCPropertyAttr_unsafe_unretained = 2048
    CXObjCPropertyAttr_class = 4096
end

"""

"""
function clang_Cursor_getObjCPropertyAttributes(C, reserved)
    ccall((:clang_Cursor_getObjCPropertyAttributes, libclang), UInt32, (CXCursor, UInt32), C, reserved)
end

"""

"""
function clang_Cursor_getObjCPropertyGetterName(C)
    ccall((:clang_Cursor_getObjCPropertyGetterName, libclang), CXString, (CXCursor,), C)
end

"""

"""
function clang_Cursor_getObjCPropertySetterName(C)
    ccall((:clang_Cursor_getObjCPropertySetterName, libclang), CXString, (CXCursor,), C)
end

"""
`Qualifiers` written next to the return and parameter types in Objective-C method declarations.
"""
@cenum CXObjCDeclQualifierKind::UInt32 begin
    CXObjCDeclQualifier_None = 0
    CXObjCDeclQualifier_In = 1
    CXObjCDeclQualifier_Inout = 2
    CXObjCDeclQualifier_Out = 4
    CXObjCDeclQualifier_Bycopy = 8
    CXObjCDeclQualifier_Byref = 16
    CXObjCDeclQualifier_Oneway = 32
end

"""

"""
function clang_Cursor_getObjCDeclQualifiers(C)
    ccall((:clang_Cursor_getObjCDeclQualifiers, libclang), UInt32, (CXCursor,), C)
end

"""

"""
function clang_Cursor_isObjCOptional(C)
    ccall((:clang_Cursor_isObjCOptional, libclang), UInt32, (CXCursor,), C)
end

"""

"""
function clang_Cursor_isVariadic(C)
    ccall((:clang_Cursor_isVariadic, libclang), UInt32, (CXCursor,), C)
end

"""

"""
function clang_Cursor_isExternalSymbol(C, language, definedIn, isGenerated)
    ccall((:clang_Cursor_isExternalSymbol, libclang), UInt32, (CXCursor, Ptr{CXString}, Ptr{CXString}, Ptr{UInt32}), C, language, definedIn, isGenerated)
end

"""

"""
function clang_Cursor_getCommentRange(C)
    ccall((:clang_Cursor_getCommentRange, libclang), CXSourceRange, (CXCursor,), C)
end

"""

"""
function clang_Cursor_getRawCommentText(C)
    ccall((:clang_Cursor_getRawCommentText, libclang), CXString, (CXCursor,), C)
end

"""

"""
function clang_Cursor_getBriefCommentText(C)
    ccall((:clang_Cursor_getBriefCommentText, libclang), CXString, (CXCursor,), C)
end

## Name Mangling API Functions

"""
    clang_Cursor_getMangling(cursor)
Retrieve the [`CXStrings`](@ref) representing the mangled name of the cursor.
"""
function clang_Cursor_getMangling(cursor)
    ccall((:clang_Cursor_getMangling, libclang), CXString, (CXCursor,), cursor)
end

"""
    clang_Cursor_getCXXManglings(cursor)
Retrieve the [`CXStrings`](@ref) representing the mangled symbols of the C++ constructor or
destructor at the cursor.
"""
function clang_Cursor_getCXXManglings(cursor)
    ccall((:clang_Cursor_getCXXManglings, libclang), Ptr{CXStringSet}, (CXCursor,), cursor)
end

"""
    clang_Cursor_getObjCManglings(cursor)
Retrieve the [`CXStrings`](@ref) representing the mangled symbols of the ObjC class interface
or implementation at the cursor.
"""
function clang_Cursor_getObjCManglings(cursor)
    ccall((:clang_Cursor_getObjCManglings, libclang), Ptr{CXStringSet}, (CXCursor,), cursor)
end

## Module introspection
# The functions in this group provide access to information about modules.

const CXModule = Ptr{Cvoid}

"""

"""
function clang_Cursor_getModule(C)
    ccall((:clang_Cursor_getModule, libclang), CXModule, (CXCursor,), C)
end

"""

"""
function clang_getModuleForFile(arg1, arg2)
    ccall((:clang_getModuleForFile, libclang), CXModule, (CXTranslationUnit, CXFile), arg1, arg2)
end

"""

"""
function clang_Module_getASTFile(Module)
    ccall((:clang_Module_getASTFile, libclang), CXFile, (CXModule,), Module)
end

"""

"""
function clang_Module_getParent(Module)
    ccall((:clang_Module_getParent, libclang), CXModule, (CXModule,), Module)
end

"""

"""
function clang_Module_getName(Module)
    ccall((:clang_Module_getName, libclang), CXString, (CXModule,), Module)
end

"""

"""
function clang_Module_getFullName(Module)
    ccall((:clang_Module_getFullName, libclang), CXString, (CXModule,), Module)
end

"""

"""
function clang_Module_isSystem(Module)
    ccall((:clang_Module_isSystem, libclang), Cint, (CXModule,), Module)
end

"""

"""
function clang_Module_getNumTopLevelHeaders(arg1, Module)
    ccall((:clang_Module_getNumTopLevelHeaders, libclang), UInt32, (CXTranslationUnit, CXModule), arg1, Module)
end

"""

"""
function clang_Module_getTopLevelHeader(arg1, Module, Index)
    ccall((:clang_Module_getTopLevelHeader, libclang), CXFile, (CXTranslationUnit, CXModule, UInt32), arg1, Module, Index)
end

## C++ AST introspection
# The routines in this group provide access information in the ASTs specific to C++ language features.


"""

"""
function clang_CXXConstructor_isConvertingConstructor(C)
    ccall((:clang_CXXConstructor_isConvertingConstructor, libclang), UInt32, (CXCursor,), C)
end

"""

"""
function clang_CXXConstructor_isCopyConstructor(C)
    ccall((:clang_CXXConstructor_isCopyConstructor, libclang), UInt32, (CXCursor,), C)
end

"""

"""
function clang_CXXConstructor_isDefaultConstructor(C)
    ccall((:clang_CXXConstructor_isDefaultConstructor, libclang), UInt32, (CXCursor,), C)
end

"""

"""
function clang_CXXConstructor_isMoveConstructor(C)
    ccall((:clang_CXXConstructor_isMoveConstructor, libclang), UInt32, (CXCursor,), C)
end

"""

"""
function clang_CXXField_isMutable(C)
    ccall((:clang_CXXField_isMutable, libclang), UInt32, (CXCursor,), C)
end

"""

"""
function clang_CXXMethod_isDefaulted(C)
    ccall((:clang_CXXMethod_isDefaulted, libclang), UInt32, (CXCursor,), C)
end

"""

"""
function clang_CXXMethod_isPureVirtual(C)
    ccall((:clang_CXXMethod_isPureVirtual, libclang), UInt32, (CXCursor,), C)
end

"""

"""
function clang_CXXMethod_isStatic(C)
    ccall((:clang_CXXMethod_isStatic, libclang), UInt32, (CXCursor,), C)
end

"""

"""
function clang_CXXMethod_isVirtual(C)
    ccall((:clang_CXXMethod_isVirtual, libclang), UInt32, (CXCursor,), C)
end

"""

"""
function clang_CXXRecord_isAbstract(C)
    ccall((:clang_CXXRecord_isAbstract, libclang), UInt32, (CXCursor,), C)
end

"""

"""
function clang_EnumDecl_isScoped(C)
    ccall((:clang_EnumDecl_isScoped, libclang), UInt32, (CXCursor,), C)
end

"""

"""
function clang_CXXMethod_isConst(C)
    ccall((:clang_CXXMethod_isConst, libclang), UInt32, (CXCursor,), C)
end

"""

"""
function clang_getTemplateCursorKind(C)
    ccall((:clang_getTemplateCursorKind, libclang), CXCursorKind, (CXCursor,), C)
end

"""

"""
function clang_getSpecializedCursorTemplate(C)
    ccall((:clang_getSpecializedCursorTemplate, libclang), CXCursor, (CXCursor,), C)
end

"""

"""
function clang_getCursorReferenceNameRange(C, NameFlags, PieceIndex)
    ccall((:clang_getCursorReferenceNameRange, libclang), CXSourceRange, (CXCursor, UInt32, UInt32), C, NameFlags, PieceIndex)
end

@cenum CXNameRefFlags::UInt32 begin
    CXNameRange_WantQualifier = 1
    CXNameRange_WantTemplateArgs = 2
    CXNameRange_WantSinglePiece = 4
end

## Token extraction and manipulation
# The routines in this group provide access to the tokens within a translation unit, along
# with a semantic mapping of those tokens to their corresponding cursors.

"""
Describes a kind of token.
"""
@cenum CXTokenKind::UInt32 begin
    CXToken_Punctuation = 0
    CXToken_Keyword = 1
    CXToken_Identifier = 2
    CXToken_Literal = 3
    CXToken_Comment = 4
end

"""
Describes a single preprocessing token.
"""
struct CXToken
    int_data::NTuple{4, UInt32}
    ptr_data::Ptr{Cvoid}
end

"""

"""
function clang_getToken(TU, Location)
    ccall((:clang_getToken, libclang), Ptr{CXToken}, (CXTranslationUnit, CXSourceLocation), TU, Location)
end

"""

"""
function clang_getTokenKind(arg1)
    ccall((:clang_getTokenKind, libclang), CXTokenKind, (CXToken,), arg1)
end

"""

"""
function clang_getTokenSpelling(arg1, arg2)
    ccall((:clang_getTokenSpelling, libclang), CXString, (CXTranslationUnit, CXToken), arg1, arg2)
end

"""

"""
function clang_getTokenLocation(arg1, arg2)
    ccall((:clang_getTokenLocation, libclang), CXSourceLocation, (CXTranslationUnit, CXToken), arg1, arg2)
end

"""

"""
function clang_getTokenExtent(arg1, arg2)
    ccall((:clang_getTokenExtent, libclang), CXSourceRange, (CXTranslationUnit, CXToken), arg1, arg2)
end

"""

"""
function clang_tokenize(TU, Range, Tokens, NumTokens)
    ccall((:clang_tokenize, libclang), Cvoid, (CXTranslationUnit, CXSourceRange, Ptr{Ptr{CXToken}}, Ptr{UInt32}), TU, Range, Tokens, NumTokens)
end

"""

"""
function clang_annotateTokens(TU, Tokens, NumTokens, Cursors)
    ccall((:clang_annotateTokens, libclang), Cvoid, (CXTranslationUnit, Ptr{CXToken}, UInt32, Ptr{CXCursor}), TU, Tokens, NumTokens, Cursors)
end

"""

"""
function clang_disposeTokens(TU, Tokens, NumTokens)
    ccall((:clang_disposeTokens, libclang), Cvoid, (CXTranslationUnit, Ptr{CXToken}, UInt32), TU, Tokens, NumTokens)
end

## Debugging facilities
# These routines are used for testing and debugging, only, and should not be relied upon.

"""

"""
function clang_getCursorKindSpelling(Kind)
    ccall((:clang_getCursorKindSpelling, libclang), CXString, (CXCursorKind,), Kind)
end

"""

"""
function clang_getDefinitionSpellingAndExtent(arg1, startBuf, endBuf, startLine, startColumn, endLine, endColumn)
    ccall((:clang_getDefinitionSpellingAndExtent, libclang), Cvoid, (CXCursor, Ptr{Cstring}, Ptr{Cstring}, Ptr{UInt32}, Ptr{UInt32}, Ptr{UInt32}, Ptr{UInt32}), arg1, startBuf, endBuf, startLine, startColumn, endLine, endColumn)
end

"""

"""
function clang_enableStackTraces()
    ccall((:clang_enableStackTraces, libclang), Cvoid, ())
end

"""

"""
function clang_executeOnThread(fn, user_data, stack_size)
    ccall((:clang_executeOnThread, libclang), Cvoid, (Ptr{Cvoid}, Ptr{Cvoid}, UInt32), fn, user_data, stack_size)
end

## Code completion
# Code completion involves taking an (incomplete) source file, along with knowledge of where
# the user is actively editing that file, and suggesting syntactically- and semantically-valid
# constructs that the user might want to use at that particular point in the source code.
# These data structures and routines provide support for code completion.

"""
A semantic string that describes a code-completion result.

A semantic string that describes the formatting of a code-completion result as a single
"template" of text that should be inserted into the source buffer when a particular
code-completion result is selected. Each semantic string is made up of some number of "chunks",
each of which contains some text along with a description of what that text means, e.g.,
the name of the entity being referenced, whether the text chunk is part of the template, or
whether it is a "placeholder" that the user should replace with actual code,of a specific kind.
See [`CXCompletionChunkKind`](@ref) for a description of the different kinds of chunks.
"""
const CXCompletionString = Ptr{Cvoid}

"""
A single result of code completion.
"""
struct CXCompletionResult
    CursorKind::CXCursorKind
    CompletionString::CXCompletionString
end

"""
Describes a single piece of text within a code-completion string.

Each "chunk" within a code-completion string ([`CXCompletionString`](@ref)) is either a piece
of text with a specific "kind" that describes how that text should be interpreted by the client
or is another completion string.
"""
@cenum CXCompletionChunkKind::UInt32 begin
    CXCompletionChunk_Optional = 0
    CXCompletionChunk_TypedText = 1
    CXCompletionChunk_Text = 2
    CXCompletionChunk_Placeholder = 3
    CXCompletionChunk_Informative = 4
    CXCompletionChunk_CurrentParameter = 5
    CXCompletionChunk_LeftParen = 6
    CXCompletionChunk_RightParen = 7
    CXCompletionChunk_LeftBracket = 8
    CXCompletionChunk_RightBracket = 9
    CXCompletionChunk_LeftBrace = 10
    CXCompletionChunk_RightBrace = 11
    CXCompletionChunk_LeftAngle = 12
    CXCompletionChunk_RightAngle = 13
    CXCompletionChunk_Comma = 14
    CXCompletionChunk_ResultType = 15
    CXCompletionChunk_Colon = 16
    CXCompletionChunk_SemiColon = 17
    CXCompletionChunk_Equal = 18
    CXCompletionChunk_HorizontalSpace = 19
    CXCompletionChunk_VerticalSpace = 20
end

"""

"""
function clang_getCompletionChunkKind(completion_string, chunk_number)
    ccall((:clang_getCompletionChunkKind, libclang), CXCompletionChunkKind, (CXCompletionString, UInt32), completion_string, chunk_number)
end

"""

"""
function clang_getCompletionChunkText(completion_string, chunk_number)
    ccall((:clang_getCompletionChunkText, libclang), CXString, (CXCompletionString, UInt32), completion_string, chunk_number)
end

"""

"""
function clang_getCompletionChunkCompletionString(completion_string, chunk_number)
    ccall((:clang_getCompletionChunkCompletionString, libclang), CXCompletionString, (CXCompletionString, UInt32), completion_string, chunk_number)
end

"""

"""
function clang_getNumCompletionChunks(completion_string)
    ccall((:clang_getNumCompletionChunks, libclang), UInt32, (CXCompletionString,), completion_string)
end

"""

"""
function clang_getCompletionPriority(completion_string)
    ccall((:clang_getCompletionPriority, libclang), UInt32, (CXCompletionString,), completion_string)
end

"""

"""
function clang_getCompletionAvailability(completion_string)
    ccall((:clang_getCompletionAvailability, libclang), CXAvailabilityKind, (CXCompletionString,), completion_string)
end

"""

"""
function clang_getCompletionNumAnnotations(completion_string)
    ccall((:clang_getCompletionNumAnnotations, libclang), UInt32, (CXCompletionString,), completion_string)
end

"""

"""
function clang_getCompletionAnnotation(completion_string, annotation_number)
    ccall((:clang_getCompletionAnnotation, libclang), CXString, (CXCompletionString, UInt32), completion_string, annotation_number)
end

"""

"""
function clang_getCompletionParent(completion_string, kind)
    ccall((:clang_getCompletionParent, libclang), CXString, (CXCompletionString, Ptr{CXCursorKind}), completion_string, kind)
end

"""

"""
function clang_getCompletionBriefComment(completion_string)
    ccall((:clang_getCompletionBriefComment, libclang), CXString, (CXCompletionString,), completion_string)
end

"""

"""
function clang_getCursorCompletionString(cursor)
    ccall((:clang_getCursorCompletionString, libclang), CXCompletionString, (CXCursor,), cursor)
end

"""
Contains the results of code-completion.

This data structure contains the results of code completion, as produced by [`clang_codeCompleteAt`](@ref).
Its contents must be freed by [`clang_disposeCodeCompleteResults`](@ref).
"""
struct CXCodeCompleteResults
    Results::Ptr{CXCompletionResult}
    NumResults::UInt32
end

"""

"""
function clang_getCompletionNumFixIts(results, completion_index)
    ccall((:clang_getCompletionNumFixIts, libclang), UInt32, (Ptr{CXCodeCompleteResults}, UInt32), results, completion_index)
end

"""

"""
function clang_getCompletionFixIt(results, completion_index, fixit_index, replacement_range)
    ccall((:clang_getCompletionFixIt, libclang), CXString, (Ptr{CXCodeCompleteResults}, UInt32, UInt32, Ptr{CXSourceRange}), results, completion_index, fixit_index, replacement_range)
end

"""
Flags that can be passed to [`clang_codeCompleteAt`](@ref) to modify its behavior.

The enumerators in this enumeration can be bitwise-OR'd together to provide multiple options
to [`clang_codeCompleteAt`](@ref).
"""
@cenum CXCodeComplete_Flags::UInt32 begin
    CXCodeComplete_IncludeMacros = 1
    CXCodeComplete_IncludeCodePatterns = 2
    CXCodeComplete_IncludeBriefComments = 4
    CXCodeComplete_SkipPreamble = 8
    CXCodeComplete_IncludeCompletionsWithFixIts = 16
end

"""
Bits that represent the context under which completion is occurring.

The enumerators in this enumeration may be bitwise-OR'd together if multiple contexts are
occurring simultaneously.
"""
@cenum CXCompletionContext::UInt32 begin
    CXCompletionContext_Unexposed = 0
    CXCompletionContext_AnyType = 1
    CXCompletionContext_AnyValue = 2
    CXCompletionContext_ObjCObjectValue = 4
    CXCompletionContext_ObjCSelectorValue = 8
    CXCompletionContext_CXXClassTypeValue = 16
    CXCompletionContext_DotMemberAccess = 32
    CXCompletionContext_ArrowMemberAccess = 64
    CXCompletionContext_ObjCPropertyAccess = 128
    CXCompletionContext_EnumTag = 256
    CXCompletionContext_UnionTag = 512
    CXCompletionContext_StructTag = 1024
    CXCompletionContext_ClassTag = 2048
    CXCompletionContext_Namespace = 4096
    CXCompletionContext_NestedNameSpecifier = 8192
    CXCompletionContext_ObjCInterface = 16384
    CXCompletionContext_ObjCProtocol = 32768
    CXCompletionContext_ObjCCategory = 65536
    CXCompletionContext_ObjCInstanceMessage = 131072
    CXCompletionContext_ObjCClassMessage = 262144
    CXCompletionContext_ObjCSelectorName = 524288
    CXCompletionContext_MacroName = 1048576
    CXCompletionContext_NaturalLanguage = 2097152
    CXCompletionContext_IncludedFile = 4194304
    CXCompletionContext_Unknown = 8388607
end

"""

"""
function clang_defaultCodeCompleteOptions()
    ccall((:clang_defaultCodeCompleteOptions, libclang), UInt32, ())
end

"""

"""
function clang_codeCompleteAt(TU, complete_filename, complete_line, complete_column, unsaved_files, num_unsaved_files, options)
    ccall((:clang_codeCompleteAt, libclang), Ptr{CXCodeCompleteResults}, (CXTranslationUnit, Cstring, UInt32, UInt32, Ptr{CXUnsavedFile}, UInt32, UInt32), TU, complete_filename, complete_line, complete_column, unsaved_files, num_unsaved_files, options)
end

"""

"""
function clang_sortCodeCompletionResults(Results, NumResults)
    ccall((:clang_sortCodeCompletionResults, libclang), Cvoid, (Ptr{CXCompletionResult}, UInt32), Results, NumResults)
end

"""

"""
function clang_disposeCodeCompleteResults(Results)
    ccall((:clang_disposeCodeCompleteResults, libclang), Cvoid, (Ptr{CXCodeCompleteResults},), Results)
end

"""

"""
function clang_codeCompleteGetNumDiagnostics(Results)
    ccall((:clang_codeCompleteGetNumDiagnostics, libclang), UInt32, (Ptr{CXCodeCompleteResults},), Results)
end

"""

"""
function clang_codeCompleteGetDiagnostic(Results, Index)
    ccall((:clang_codeCompleteGetDiagnostic, libclang), CXDiagnostic, (Ptr{CXCodeCompleteResults}, UInt32), Results, Index)
end

"""

"""
function clang_codeCompleteGetContexts(Results)
    ccall((:clang_codeCompleteGetContexts, libclang), Culonglong, (Ptr{CXCodeCompleteResults},), Results)
end

"""

"""
function clang_codeCompleteGetContainerKind(Results, IsIncomplete)
    ccall((:clang_codeCompleteGetContainerKind, libclang), CXCursorKind, (Ptr{CXCodeCompleteResults}, Ptr{UInt32}), Results, IsIncomplete)
end

"""

"""
function clang_codeCompleteGetContainerUSR(Results)
    ccall((:clang_codeCompleteGetContainerUSR, libclang), CXString, (Ptr{CXCodeCompleteResults},), Results)
end

"""

"""
function clang_codeCompleteGetObjCSelector(Results)
    ccall((:clang_codeCompleteGetObjCSelector, libclang), CXString, (Ptr{CXCodeCompleteResults},), Results)
end

"""

"""
function clang_getClangVersion()
    ccall((:clang_getClangVersion, libclang), CXString, ())
end

"""

"""
function clang_toggleCrashRecovery(isEnabled)
    ccall((:clang_toggleCrashRecovery, libclang), Cvoid, (UInt32,), isEnabled)
end

"""
Visitor invoked for each file in a translation unit (used with [`clang_getInclusions`](@ref)).

This visitor function will be invoked by [`clang_getInclusions`](@ref) for each file included
(either at the top-level or by ``#include directives`) within a translation unit. The first
argument is the file being included, and the second and third arguments provide the inclusion
stack. The array is sorted in order of immediate inclusion. For example, the first element
refers to the location that included 'included_file'.

```c
typedef void (*CXInclusionVisitor)(CXFile included_file,
                                   CXSourceLocation* inclusion_stack,
                                   unsigned include_len,
                                   CXClientData client_data);
```
"""
const CXInclusionVisitor = Ptr{Cvoid}

"""
    clang_getInclusions(tu, visitor, client_data)
Visit the set of preprocessor inclusions in a translation unit.
The visitor function is called with the provided data for every included file.
This does not include headers included by the PCH file (unless one is inspecting the inclusions
in the PCH file itself).
"""
function clang_getInclusions(tu, visitor, client_data)
    ccall((:clang_getInclusions, libclang), Cvoid, (CXTranslationUnit, CXInclusionVisitor, CXClientData), tu, visitor, client_data)
end

@cenum CXEvalResultKind::UInt32 begin
    CXEval_Int = 1
    CXEval_Float = 2
    CXEval_ObjCStrLiteral = 3
    CXEval_StrLiteral = 4
    CXEval_CFStr = 5
    CXEval_Other = 6
    CXEval_UnExposed = 0
end

"""
Evaluation result of a cursor
"""
const CXEvalResult = Ptr{Cvoid}

"""

"""
function clang_Cursor_Evaluate(C)
    ccall((:clang_Cursor_Evaluate, libclang), CXEvalResult, (CXCursor,), C)
end

"""

"""
function clang_EvalResult_getKind(E)
    ccall((:clang_EvalResult_getKind, libclang), CXEvalResultKind, (CXEvalResult,), E)
end

"""

"""
function clang_EvalResult_getAsInt(E)
    ccall((:clang_EvalResult_getAsInt, libclang), Cint, (CXEvalResult,), E)
end

"""

"""
function clang_EvalResult_getAsLongLong(E)
    ccall((:clang_EvalResult_getAsLongLong, libclang), Clonglong, (CXEvalResult,), E)
end

"""

"""
function clang_EvalResult_isUnsignedInt(E)
    ccall((:clang_EvalResult_isUnsignedInt, libclang), UInt32, (CXEvalResult,), E)
end

"""

"""
function clang_EvalResult_getAsUnsigned(E)
    ccall((:clang_EvalResult_getAsUnsigned, libclang), Culonglong, (CXEvalResult,), E)
end

"""

"""
function clang_EvalResult_getAsDouble(E)
    ccall((:clang_EvalResult_getAsDouble, libclang), Cdouble, (CXEvalResult,), E)
end

"""

"""
function clang_EvalResult_getAsStr(E)
    ccall((:clang_EvalResult_getAsStr, libclang), Cstring, (CXEvalResult,), E)
end

"""

"""
function clang_EvalResult_dispose(E)
    ccall((:clang_EvalResult_dispose, libclang), Cvoid, (CXEvalResult,), E)
end

## Remapping functions

"""
A remapping of original source files and their translated files.
"""
const CXRemapping = Ptr{Cvoid}

"""

"""
function clang_getRemappings(path)
    ccall((:clang_getRemappings, libclang), CXRemapping, (Cstring,), path)
end

"""

"""
function clang_getRemappingsFromFileList(filePaths, numFiles)
    ccall((:clang_getRemappingsFromFileList, libclang), CXRemapping, (Ptr{Cstring}, UInt32), filePaths, numFiles)
end

"""

"""
function clang_remap_getNumFiles(arg1)
    ccall((:clang_remap_getNumFiles, libclang), UInt32, (CXRemapping,), arg1)
end

"""

"""
function clang_remap_getFilenames(arg1, index, original, transformed)
    ccall((:clang_remap_getFilenames, libclang), Cvoid, (CXRemapping, UInt32, Ptr{CXString}, Ptr{CXString}), arg1, index, original, transformed)
end

"""

"""
function clang_remap_dispose(arg1)
    ccall((:clang_remap_dispose, libclang), Cvoid, (CXRemapping,), arg1)
end

## Higher level API functions

@cenum CXVisitorResult::UInt32 begin
    CXVisit_Break = 0
    CXVisit_Continue = 1
end

struct CXCursorAndRangeVisitor
    context::Ptr{Cvoid}
    visit::Ptr{Cvoid}
end

@cenum CXResult::UInt32 begin
    CXResult_Success = 0
    CXResult_Invalid = 1
    CXResult_VisitBreak = 2
end

"""

"""
function clang_findReferencesInFile(cursor, file, visitor)
    ccall((:clang_findReferencesInFile, libclang), CXResult, (CXCursor, CXFile, CXCursorAndRangeVisitor), cursor, file, visitor)
end

"""

"""
function clang_findIncludesInFile(TU, file, visitor)
    ccall((:clang_findIncludesInFile, libclang), CXResult, (CXTranslationUnit, CXFile, CXCursorAndRangeVisitor), TU, file, visitor)
end

"""
The client's data object that is associated with a [`CXFile`](@ref).
"""
const CXIdxClientFile = Ptr{Cvoid}

"""
The client's data object that is associated with a semantic entity.
"""
const CXIdxClientEntity = Ptr{Cvoid}

"""
The client's data object that is associated with a semantic container of entities.
"""
const CXIdxClientContainer = Ptr{Cvoid}

"""
The client's data object that is associated with an AST file (PCH or module).
"""
const CXIdxClientASTFile = Ptr{Cvoid}

"""
Source location passed to index callbacks.
"""
struct CXIdxLoc
    ptr_data::NTuple{2, Ptr{Cvoid}}
    int_data::UInt32
end

"""
Data for ppIncludedFile callback.
"""
struct CXIdxIncludedFileInfo
    hashLoc::CXIdxLoc
    filename::Cstring
    file::CXFile
    isImport::Cint
    isAngled::Cint
    isModuleImport::Cint
end

"""
Data for IndexerCallbacks#importedASTFile.
"""
struct CXIdxImportedASTFileInfo
    file::CXFile
    _module::CXModule
    loc::CXIdxLoc
    isImplicit::Cint
end

@cenum CXIdxEntityKind::UInt32 begin
    CXIdxEntity_Unexposed = 0
    CXIdxEntity_Typedef = 1
    CXIdxEntity_Function = 2
    CXIdxEntity_Variable = 3
    CXIdxEntity_Field = 4
    CXIdxEntity_EnumConstant = 5
    CXIdxEntity_ObjCClass = 6
    CXIdxEntity_ObjCProtocol = 7
    CXIdxEntity_ObjCCategory = 8
    CXIdxEntity_ObjCInstanceMethod = 9
    CXIdxEntity_ObjCClassMethod = 10
    CXIdxEntity_ObjCProperty = 11
    CXIdxEntity_ObjCIvar = 12
    CXIdxEntity_Enum = 13
    CXIdxEntity_Struct = 14
    CXIdxEntity_Union = 15
    CXIdxEntity_CXXClass = 16
    CXIdxEntity_CXXNamespace = 17
    CXIdxEntity_CXXNamespaceAlias = 18
    CXIdxEntity_CXXStaticVariable = 19
    CXIdxEntity_CXXStaticMethod = 20
    CXIdxEntity_CXXInstanceMethod = 21
    CXIdxEntity_CXXConstructor = 22
    CXIdxEntity_CXXDestructor = 23
    CXIdxEntity_CXXConversionFunction = 24
    CXIdxEntity_CXXTypeAlias = 25
    CXIdxEntity_CXXInterface = 26
end

@cenum CXIdxEntityLanguage::UInt32 begin
    CXIdxEntityLang_None = 0
    CXIdxEntityLang_C = 1
    CXIdxEntityLang_ObjC = 2
    CXIdxEntityLang_CXX = 3
    CXIdxEntityLang_Swift = 4
end

"""
Extra C++ template information for an entity. This can apply to:
* CXIdxEntity_Function
* CXIdxEntity_CXXClass
* CXIdxEntity_CXXStaticMethod
* CXIdxEntity_CXXInstanceMethod
* CXIdxEntity_CXXConstructor
* CXIdxEntity_CXXConversionFunction
* CXIdxEntity_CXXTypeAlias
"""
@cenum CXIdxEntityCXXTemplateKind::UInt32 begin
    CXIdxEntity_NonTemplate = 0
    CXIdxEntity_Template = 1
    CXIdxEntity_TemplatePartialSpecialization = 2
    CXIdxEntity_TemplateSpecialization = 3
end

@cenum CXIdxAttrKind::UInt32 begin
    CXIdxAttr_Unexposed = 0
    CXIdxAttr_IBAction = 1
    CXIdxAttr_IBOutlet = 2
    CXIdxAttr_IBOutletCollection = 3
end


struct CXIdxAttrInfo
    kind::CXIdxAttrKind
    cursor::CXCursor
    loc::CXIdxLoc
end

struct CXIdxEntityInfo
    kind::CXIdxEntityKind
    templateKind::CXIdxEntityCXXTemplateKind
    lang::CXIdxEntityLanguage
    name::Cstring
    USR::Cstring
    cursor::CXCursor
    attributes::Ptr{Ptr{CXIdxAttrInfo}}
    numAttributes::UInt32
end

struct CXIdxContainerInfo
    cursor::CXCursor
end

struct CXIdxIBOutletCollectionAttrInfo
    attrInfo::Ptr{CXIdxAttrInfo}
    objcClass::Ptr{CXIdxEntityInfo}
    classCursor::CXCursor
    classLoc::CXIdxLoc
end

@cenum CXIdxDeclInfoFlags::UInt32 begin
    CXIdxDeclFlag_Skipped = 1
end


struct CXIdxDeclInfo
    entityInfo::Ptr{CXIdxEntityInfo}
    cursor::CXCursor
    loc::CXIdxLoc
    semanticContainer::Ptr{CXIdxContainerInfo}
    lexicalContainer::Ptr{CXIdxContainerInfo}
    isRedeclaration::Cint
    isDefinition::Cint
    isContainer::Cint
    declAsContainer::Ptr{CXIdxContainerInfo}
    isImplicit::Cint
    attributes::Ptr{Ptr{CXIdxAttrInfo}}
    numAttributes::UInt32
    flags::UInt32
end

@cenum CXIdxObjCContainerKind::UInt32 begin
    CXIdxObjCContainer_ForwardRef = 0
    CXIdxObjCContainer_Interface = 1
    CXIdxObjCContainer_Implementation = 2
end


struct CXIdxObjCContainerDeclInfo
    declInfo::Ptr{CXIdxDeclInfo}
    kind::CXIdxObjCContainerKind
end

struct CXIdxBaseClassInfo
    base::Ptr{CXIdxEntityInfo}
    cursor::CXCursor
    loc::CXIdxLoc
end

struct CXIdxObjCProtocolRefInfo
    protocol::Ptr{CXIdxEntityInfo}
    cursor::CXCursor
    loc::CXIdxLoc
end

struct CXIdxObjCProtocolRefListInfo
    protocols::Ptr{Ptr{CXIdxObjCProtocolRefInfo}}
    numProtocols::UInt32
end

struct CXIdxObjCInterfaceDeclInfo
    containerInfo::Ptr{CXIdxObjCContainerDeclInfo}
    superInfo::Ptr{CXIdxBaseClassInfo}
    protocols::Ptr{CXIdxObjCProtocolRefListInfo}
end

struct CXIdxObjCCategoryDeclInfo
    containerInfo::Ptr{CXIdxObjCContainerDeclInfo}
    objcClass::Ptr{CXIdxEntityInfo}
    classCursor::CXCursor
    classLoc::CXIdxLoc
    protocols::Ptr{CXIdxObjCProtocolRefListInfo}
end

struct CXIdxObjCPropertyDeclInfo
    declInfo::Ptr{CXIdxDeclInfo}
    getter::Ptr{CXIdxEntityInfo}
    setter::Ptr{CXIdxEntityInfo}
end

struct CXIdxCXXClassDeclInfo
    declInfo::Ptr{CXIdxDeclInfo}
    bases::Ptr{Ptr{CXIdxBaseClassInfo}}
    numBases::UInt32
end

"""
Data for IndexerCallbacks#indexEntityReference.

This may be deprecated in a future version as this duplicates the [`CXSymbolRole_Implicit`](@ref)
bit in [`CXSymbolRole`](@ref).
"""
@cenum CXIdxEntityRefKind::UInt32 begin
    CXIdxEntityRef_Direct = 1
    CXIdxEntityRef_Implicit = 2
end

"""
Roles that are attributed to symbol occurrences.

Internal: this currently mirrors low 9 bits of clang::index::SymbolRole with higher bits zeroed.
These high bits may be exposed in the future.
"""
@cenum CXSymbolRole::UInt32 begin
    CXSymbolRole_None = 0
    CXSymbolRole_Declaration = 1
    CXSymbolRole_Definition = 2
    CXSymbolRole_Reference = 4
    CXSymbolRole_Read = 8
    CXSymbolRole_Write = 16
    CXSymbolRole_Call = 32
    CXSymbolRole_Dynamic = 64
    CXSymbolRole_AddressOf = 128
    CXSymbolRole_Implicit = 256
end

"""
Data for IndexerCallbacks#indexEntityReference.
"""
struct CXIdxEntityRefInfo
    kind::CXIdxEntityRefKind
    cursor::CXCursor
    loc::CXIdxLoc
    referencedEntity::Ptr{CXIdxEntityInfo}
    parentEntity::Ptr{CXIdxEntityInfo}
    container::Ptr{CXIdxContainerInfo}
    role::CXSymbolRole
end

"""
A group of callbacks used by [`clang_indexSourceFile`](@ref) and [`clang_indexTranslationUnit`](@ref).
"""
struct IndexerCallbacks
    abortQuery::Ptr{Cvoid}
    diagnostic::Ptr{Cvoid}
    enteredMainFile::Ptr{Cvoid}
    ppIncludedFile::Ptr{Cvoid}
    importedASTFile::Ptr{Cvoid}
    startedTranslationUnit::Ptr{Cvoid}
    indexDeclaration::Ptr{Cvoid}
    indexEntityReference::Ptr{Cvoid}
end

"""

"""
function clang_index_isEntityObjCContainerKind(arg1)
    ccall((:clang_index_isEntityObjCContainerKind, libclang), Cint, (CXIdxEntityKind,), arg1)
end

"""

"""
function clang_index_getObjCContainerDeclInfo(arg1)
    ccall((:clang_index_getObjCContainerDeclInfo, libclang), Ptr{CXIdxObjCContainerDeclInfo}, (Ptr{CXIdxDeclInfo},), arg1)
end

"""

"""
function clang_index_getObjCInterfaceDeclInfo(arg1)
    ccall((:clang_index_getObjCInterfaceDeclInfo, libclang), Ptr{CXIdxObjCInterfaceDeclInfo}, (Ptr{CXIdxDeclInfo},), arg1)
end

"""

"""
function clang_index_getObjCCategoryDeclInfo(arg1)
    ccall((:clang_index_getObjCCategoryDeclInfo, libclang), Ptr{CXIdxObjCCategoryDeclInfo}, (Ptr{CXIdxDeclInfo},), arg1)
end

"""

"""
function clang_index_getObjCProtocolRefListInfo(arg1)
    ccall((:clang_index_getObjCProtocolRefListInfo, libclang), Ptr{CXIdxObjCProtocolRefListInfo}, (Ptr{CXIdxDeclInfo},), arg1)
end

"""

"""
function clang_index_getObjCPropertyDeclInfo(arg1)
    ccall((:clang_index_getObjCPropertyDeclInfo, libclang), Ptr{CXIdxObjCPropertyDeclInfo}, (Ptr{CXIdxDeclInfo},), arg1)
end

"""

"""
function clang_index_getIBOutletCollectionAttrInfo(arg1)
    ccall((:clang_index_getIBOutletCollectionAttrInfo, libclang), Ptr{CXIdxIBOutletCollectionAttrInfo}, (Ptr{CXIdxAttrInfo},), arg1)
end

"""

"""
function clang_index_getCXXClassDeclInfo(arg1)
    ccall((:clang_index_getCXXClassDeclInfo, libclang), Ptr{CXIdxCXXClassDeclInfo}, (Ptr{CXIdxDeclInfo},), arg1)
end

"""

"""
function clang_index_getClientContainer(arg1)
    ccall((:clang_index_getClientContainer, libclang), CXIdxClientContainer, (Ptr{CXIdxContainerInfo},), arg1)
end

"""

"""
function clang_index_setClientContainer(arg1, arg2)
    ccall((:clang_index_setClientContainer, libclang), Cvoid, (Ptr{CXIdxContainerInfo}, CXIdxClientContainer), arg1, arg2)
end

"""

"""
function clang_index_getClientEntity(arg1)
    ccall((:clang_index_getClientEntity, libclang), CXIdxClientEntity, (Ptr{CXIdxEntityInfo},), arg1)
end

"""

"""
function clang_index_setClientEntity(arg1, arg2)
    ccall((:clang_index_setClientEntity, libclang), Cvoid, (Ptr{CXIdxEntityInfo}, CXIdxClientEntity), arg1, arg2)
end

"""
An indexing action/session, to be applied to one or multiple translation units.
"""
const CXIndexAction = Ptr{Cvoid}

"""
    clang_IndexAction_create(CIdx)
An indexing action/session, to be applied to one or multiple translation units.
`CIdx` is the index object with which the index action will be associated.
"""
function clang_IndexAction_create(CIdx)
    ccall((:clang_IndexAction_create, libclang), CXIndexAction, (CXIndex,), CIdx)
end

"""
    clang_IndexAction_dispose(action)
Destroy the given index action.

The index action must not be destroyed until all of the translation units created within
that index action have been destroyed.
"""
function clang_IndexAction_dispose(action)
    ccall((:clang_IndexAction_dispose, libclang), Cvoid, (CXIndexAction,), action)
end

@cenum CXIndexOptFlags::UInt32 begin
    CXIndexOpt_None = 0
    CXIndexOpt_SuppressRedundantRefs = 1
    CXIndexOpt_IndexFunctionLocalSymbols = 2
    CXIndexOpt_IndexImplicitTemplateInstantiations = 4
    CXIndexOpt_SuppressWarnings = 8
    CXIndexOpt_SkipParsedBodiesInSession = 16
end

"""

"""
function clang_indexSourceFile(arg1, client_data, index_callbacks, index_callbacks_size, index_options, source_filename, command_line_args, num_command_line_args, unsaved_files, num_unsaved_files, out_TU, TU_options)
    ccall((:clang_indexSourceFile, libclang), Cint, (CXIndexAction, CXClientData, Ptr{IndexerCallbacks}, UInt32, UInt32, Cstring, Ptr{Cstring}, Cint, Ptr{CXUnsavedFile}, UInt32, Ptr{CXTranslationUnit}, UInt32), arg1, client_data, index_callbacks, index_callbacks_size, index_options, source_filename, command_line_args, num_command_line_args, unsaved_files, num_unsaved_files, out_TU, TU_options)
end

"""

"""
function clang_indexSourceFileFullArgv(arg1, client_data, index_callbacks, index_callbacks_size, index_options, source_filename, command_line_args, num_command_line_args, unsaved_files, num_unsaved_files, out_TU, TU_options)
    ccall((:clang_indexSourceFileFullArgv, libclang), Cint, (CXIndexAction, CXClientData, Ptr{IndexerCallbacks}, UInt32, UInt32, Cstring, Ptr{Cstring}, Cint, Ptr{CXUnsavedFile}, UInt32, Ptr{CXTranslationUnit}, UInt32), arg1, client_data, index_callbacks, index_callbacks_size, index_options, source_filename, command_line_args, num_command_line_args, unsaved_files, num_unsaved_files, out_TU, TU_options)
end

"""

"""
function clang_indexTranslationUnit(arg1, client_data, index_callbacks, index_callbacks_size, index_options, arg2)
    ccall((:clang_indexTranslationUnit, libclang), Cint, (CXIndexAction, CXClientData, Ptr{IndexerCallbacks}, UInt32, UInt32, CXTranslationUnit), arg1, client_data, index_callbacks, index_callbacks_size, index_options, arg2)
end

"""

"""
function clang_indexLoc_getFileLocation(loc, indexFile, file, line, column, offset)
    ccall((:clang_indexLoc_getFileLocation, libclang), Cvoid, (CXIdxLoc, Ptr{CXIdxClientFile}, Ptr{CXFile}, Ptr{UInt32}, Ptr{UInt32}, Ptr{UInt32}), loc, indexFile, file, line, column, offset)
end

"""

"""
function clang_indexLoc_getCXSourceLocation(loc)
    ccall((:clang_indexLoc_getCXSourceLocation, libclang), CXSourceLocation, (CXIdxLoc,), loc)
end

"""
Visitor invoked for each field found by a traversal.

This visitor function will be invoked for each field found by [`clang_Type_visitFields`](@ref).
Its first argument is the cursor being visited, its second argument is the client data provided
to [`clang_Type_visitFields`](@ref).

The visitor should return one of the [`CXVisitorResult`](@ref) values to direct [`clang_Type_visitFields`](@ref).

```c
typedef enum CXVisitorResult (*CXFieldVisitor)(CXCursor C, CXClientData client_data);
```
"""
const CXFieldVisitor = Ptr{Cvoid}

"""
    clang_Type_visitFields(T, visitor, client_data)
Visit the fields of a particular type. Returns a non-zero value if the traversal was terminated
prematurely by the visitor returning [`CXFieldVisit_Break`](@ref).

This function visits all the direct fields of the given cursor, invoking the given `visitor`
function with the cursors of each visited field. The traversal may be ended prematurely, if
the visitor returns [`CXFieldVisit_Break`](@ref).

## Arguments
- `T`: the record type whose field may be visited
- `visitor`: the visitor function that will be invoked for each field of `T`.
- `client_data`: pointer data supplied by the client, which will be passed to the visitor each time it is invoked.
"""
function clang_Type_visitFields(T, visitor, client_data)
    ccall((:clang_Type_visitFields, libclang), UInt32, (CXType, CXFieldVisitor, CXClientData), T, visitor, client_data)
end
