const CXVirtualFileOverlayImpl = Cvoid

"""
Object encapsulating information about overlaying virtual file/directories over the real file system.
"""
const CXVirtualFileOverlay = Ptr{CXVirtualFileOverlayImpl}

"""
    clang_getBuildSessionTimestamp()
Return the timestamp for use with Clang's `-fbuild-session-timestamp=` option.
"""
function clang_getBuildSessionTimestamp()
    ccall((:clang_getBuildSessionTimestamp, libclang), Culonglong, ())
end

"""
    clang_VirtualFileOverlay_create(options)
Create a [`CXVirtualFileOverlay`](@ref) object.

Must be disposed with [`clang_VirtualFileOverlay_dispose`](@ref).

`options` is reserved, always pass 0.
"""
function clang_VirtualFileOverlay_create(options)
    ccall((:clang_VirtualFileOverlay_create, libclang), CXVirtualFileOverlay, (UInt32,), options)
end

"""
    clang_VirtualFileOverlay_addFileMapping(overlay, virtualPath, realPath)
Map an absolute virtual file path to an absolute real one. The virtual path must be
canonicalized (not contain "."/".."). Returns 0 for success, non-zero to indicate an error.
"""
function clang_VirtualFileOverlay_addFileMapping(overlay, virtualPath, realPath)
    ccall((:clang_VirtualFileOverlay_addFileMapping, libclang), CXErrorCode, (CXVirtualFileOverlay, Cstring, Cstring), overlay, virtualPath, realPath)
end

"""
    clang_VirtualFileOverlay_setCaseSensitivity(overlay, caseSensitive)
Set the case sensitivity for the [`CXVirtualFileOverlay`](@ref) object.
The [`CXVirtualFileOverlay`](@ref) object is case-sensitive by default, this option can be
used to override the default. Returns 0 for success, non-zero to indicate an error.
"""
function clang_VirtualFileOverlay_setCaseSensitivity(overlay, caseSensitive)
    ccall((:clang_VirtualFileOverlay_setCaseSensitivity, libclang), CXErrorCode, (CXVirtualFileOverlay, Cint), overlay, caseSensitive)
end

"""
    clang_VirtualFileOverlay_writeToBuffer(overlay, options, out_buffer_ptr, out_buffer_size)
Write out the [`CXVirtualFileOverlay`](@ref) object to a char buffer. Returns 0 for success, non-zero to indicate an error.

## Arguments:
- `options`: is reserved, always pass 0
- `out_buffer_ptr`: pointer to receive the buffer pointer, which should be disposed using [`clang_free`](@ref)
- `out_buffer_size`: pointer to receive the buffer size
"""
function clang_VirtualFileOverlay_writeToBuffer(overlay, options, out_buffer_ptr, out_buffer_size)
    ccall((:clang_VirtualFileOverlay_writeToBuffer, libclang), CXErrorCode, (CXVirtualFileOverlay, UInt32, Ptr{Cstring}, Ptr{UInt32}), overlay, options, out_buffer_ptr, out_buffer_size)
end

"""
    clang_free(buffer)
Free memory allocated by libclang, such as the buffer returned by [`CXVirtualFileOverlay`](@ref)
or [`clang_ModuleMapDescriptor_writeToBuffer`](@ref).

## Arguments:
- `buffer`: memory pointer to free.
"""
function clang_free(buffer)
    ccall((:clang_free, libclang), Cvoid, (Ptr{Cvoid},), buffer)
end

"""
    clang_VirtualFileOverlay_dispose(overlay)
Dispose a [`CXVirtualFileOverlay`](@ref) object.
"""
function clang_VirtualFileOverlay_dispose(overlay)
    ccall((:clang_VirtualFileOverlay_dispose, libclang), Cvoid, (CXVirtualFileOverlay,), overlay)
end



const CXModuleMapDescriptorImpl = Cvoid

"""
Object encapsulating information about a module.map file.
"""
const CXModuleMapDescriptor = Ptr{CXModuleMapDescriptorImpl}

"""
    clang_ModuleMapDescriptor_create(options)
Create a [`CXModuleMapDescriptor`](@ref) object.
Must be disposed with [`clang_ModuleMapDescriptor_dispose`](@ref).
`options` is reserved, always pass 0.
"""
function clang_ModuleMapDescriptor_create(options)
    ccall((:clang_ModuleMapDescriptor_create, libclang), CXModuleMapDescriptor, (UInt32,), options)
end

"""
    clang_ModuleMapDescriptor_setFrameworkModuleName(descriptor, name)
Sets the framework module name that the module.map describes.
Returns 0 for success, non-zero to indicate an error.
"""
function clang_ModuleMapDescriptor_setFrameworkModuleName(descriptor, name)
    ccall((:clang_ModuleMapDescriptor_setFrameworkModuleName, libclang), CXErrorCode, (CXModuleMapDescriptor, Cstring), descriptor, name)
end

"""
    clang_ModuleMapDescriptor_setUmbrellaHeader(descriptor, name)
Sets the umbrealla header name that the module.map describes.
Returns 0 for success, non-zero to indicate an error.
"""
function clang_ModuleMapDescriptor_setUmbrellaHeader(descriptor, name)
    ccall((:clang_ModuleMapDescriptor_setUmbrellaHeader, libclang), CXErrorCode, (CXModuleMapDescriptor, Cstring), descriptor, name)
end

"""
    clang_ModuleMapDescriptor_writeToBuffer(descriptor, options, out_buffer_ptr, out_buffer_size)
Write out the [`CXModuleMapDescriptor`](@ref) object to a char buffer.
Returns 0 for success, non-zero to indicate an error.

## Arguments
- `options`: is reserved, always pass 0.
- `out_buffer_ptr`: pointer to receive the buffer pointer, which should be disposed using [`clang_free`](@ref).
- `out_buffer_size`: pointer to receive the buffer size.
"""
function clang_ModuleMapDescriptor_writeToBuffer(descriptor, options, out_buffer_ptr, out_buffer_size)
    ccall((:clang_ModuleMapDescriptor_writeToBuffer, libclang), CXErrorCode, (CXModuleMapDescriptor, UInt32, Ptr{Cstring}, Ptr{UInt32}), descriptor, options, out_buffer_ptr, out_buffer_size)
end

"""
    clang_ModuleMapDescriptor_dispose(descriptor)
Dispose a [`CXModuleMapDescriptor`](@ref) object.
"""
function clang_ModuleMapDescriptor_dispose(descriptor)
    ccall((:clang_ModuleMapDescriptor_dispose, libclang), Cvoid, (CXModuleMapDescriptor,), descriptor)
end
