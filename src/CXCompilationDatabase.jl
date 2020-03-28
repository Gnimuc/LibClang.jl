"""
A compilation database holds all information used to compile files in a project.
For each file in the database, it can be queried for the working directory or the command
line used for the compiler invocation.

Must be freed by [`clang_CompilationDatabase_dispose`](@ref).
"""
const CXCompilationDatabase = Ptr{Cvoid}

"""
Contains the results of a search in the compilation database.

When searching for the compile command for a file, the compilation db can return several
commands, as the file may have been compiled with different options in different places of
the project. This choice of compile commands is wrapped in this opaque data structure.
It must be freed by [`clang_CompileCommands_dispose`](@ref).
"""
const CXCompileCommands = Ptr{Cvoid}

"""
Represents the command line invocation to compile a specific file.
"""
const CXCompileCommand = Ptr{Cvoid}

"""
Error codes for Compilation Database:
- `CXCompilationDatabase_NoError`: no error occurred
- `CXCompilationDatabase_CanNotLoadDatabase`: database can not be loaded
"""
@cenum CXCompilationDatabase_Error::UInt32 begin
    CXCompilationDatabase_NoError = 0
    CXCompilationDatabase_CanNotLoadDatabase = 1
end

"""
    clang_CompilationDatabase_fromDirectory(BuildDir, ErrorCode)
Creates a compilation database from the database found in directory `BuildDir`.
For example, *CMake* can output a `compile_commands.json` which can be used to build the database.

It must be freed by [`clang_CompilationDatabase_dispose`](@ref).
"""
function clang_CompilationDatabase_fromDirectory(BuildDir, ErrorCode)
    ccall((:clang_CompilationDatabase_fromDirectory, libclang), CXCompilationDatabase, (Cstring, Ptr{CXCompilationDatabase_Error}), BuildDir, ErrorCode)
end

"""
    clang_CompilationDatabase_dispose(db)
Free the given compilation database.
"""
function clang_CompilationDatabase_dispose(db)
    ccall((:clang_CompilationDatabase_dispose, libclang), Cvoid, (CXCompilationDatabase,), db)
end

"""
    clang_CompilationDatabase_getCompileCommands(db, CompleteFileName)
Find the compile commands used for a file.
The compile commands must be freed by [`clang_CompileCommands_dispose`](@ref).
"""
function clang_CompilationDatabase_getCompileCommands(db, CompleteFileName)
    ccall((:clang_CompilationDatabase_getCompileCommands, libclang), CXCompileCommands, (CXCompilationDatabase, Cstring), db, CompleteFileName)
end

"""
    clang_CompilationDatabase_getAllCompileCommands(db)
Get all the compile commands in the given compilation database.
"""
function clang_CompilationDatabase_getAllCompileCommands(db)
    ccall((:clang_CompilationDatabase_getAllCompileCommands, libclang), CXCompileCommands, (CXCompilationDatabase,), db)
end

"""
    clang_CompileCommands_dispose(cmds)
Free the given CompileCommands.
"""
function clang_CompileCommands_dispose(cmds)
    ccall((:clang_CompileCommands_dispose, libclang), Cvoid, (CXCompileCommands,), cmds)
end

"""
    clang_CompileCommands_getSize(cmds)
Get the number of CompileCommand we have for a file.
"""
function clang_CompileCommands_getSize(cmds)
    ccall((:clang_CompileCommands_getSize, libclang), UInt32, (CXCompileCommands,), cmds)
end

"""
    clang_CompileCommands_getCommand(cmds, i)
Get the `i`-th CompileCommand for a file.
!!! note
`0 <= i < clang_CompileCommands_getSize(cmds)`
"""
function clang_CompileCommands_getCommand(cmds, i)
    ccall((:clang_CompileCommands_getCommand, libclang), CXCompileCommand, (CXCompileCommands, UInt32), cmds, i)
end

"""
    clang_CompileCommand_getDirectory(cmd)
Get the working directory where the CompileCommand was executed from.
"""
function clang_CompileCommand_getDirectory(cmd)
    ccall((:clang_CompileCommand_getDirectory, libclang), CXString, (CXCompileCommand,), cmd)
end

"""
    clang_CompileCommand_getFilename(cmd)
Get the filename associated with the CompileCommand.
"""
function clang_CompileCommand_getFilename(cmd)
    ccall((:clang_CompileCommand_getFilename, libclang), CXString, (CXCompileCommand,), cmd)
end

"""
    clang_CompileCommand_getNumArgs(cmd)
Get the number of arguments in the compiler invocation.
"""
function clang_CompileCommand_getNumArgs(cmd)
    ccall((:clang_CompileCommand_getNumArgs, libclang), UInt32, (CXCompileCommand,), cmd)
end

"""
    clang_CompileCommand_getArg(cmd, i)
Get the `i`-th argument value in the compiler invocations.
Invariant:
- argument 0 is the compiler executable
"""
function clang_CompileCommand_getArg(cmd, i)
    ccall((:clang_CompileCommand_getArg, libclang), CXString, (CXCompileCommand, UInt32), cmd, i)
end
