"""
A character string.

The [`CXString`](@ref) type is used to return strings from the interface when the ownership
of that string might differ from one call to the next.
Use [`clang_getCString`](@ref) to retrieve the string data and, once finished with the
string data, call [`clang_disposeString`](@ref) to free the string.
"""
struct CXString
    data::Ptr{Cvoid}
    private_flags::UInt32
end

struct CXStringSet
    Strings::Ptr{CXString}
    Count::UInt32
end

"""
    clang_getCString(string)
Retrieve the character data associated with the given string.
"""
function clang_getCString(string)
    ccall((:clang_getCString, libclang), Cstring, (CXString,), string)
end

"""
    clang_disposeString(string)
Free the given string.
"""
function clang_disposeString(string)
    ccall((:clang_disposeString, libclang), Cvoid, (CXString,), string)
end

"""
    clang_disposeStringSet(set)
Free the given string set.
"""
function clang_disposeStringSet(set)
    ccall((:clang_disposeStringSet, libclang), Cvoid, (Ptr{CXStringSet},), set)
end
