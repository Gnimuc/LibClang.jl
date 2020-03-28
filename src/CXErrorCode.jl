"""
Error codes returned by libclang routines.

Zero [`CXError_Success`](@ref) is the only error code indicating success.
Other error codes, including not yet assigned non-zero values, indicate errors.

- `CXError_Success`: no error
- `CXError_Failure`: a generic error code, no further details are available
- `CXError_Crashed`: libclang crashed while performing the requested operation
- `CXError_InvalidArguments`: the function detected that the arguments violate the function contract
- `CXError_ASTReadError`: an AST deserialization error has occurred
"""
@cenum CXErrorCode::UInt32 begin
    CXError_Success = 0
    CXError_Failure = 1
    CXError_Crashed = 2
    CXError_InvalidArguments = 3
    CXError_ASTReadError = 4
end
