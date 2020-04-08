module cli

export CLIRestoreSettings
export CLISetParam
export CLISetParamMat
export CLISetParamUMat
export CLISetParamRow
export CLISetParamCol
export CLISetParamURow
export CLISetParamUCol
export CLIGetParamBool
export CLIGetParamInt
export CLIGetParamDouble
export CLIGetParamString
export CLIGetParamVectorStr
export CLIGetParamVectorInt
export CLIGetParamMat
export CLIGetParamUMat
export CLIGetParamCol
export CLIGetParamRow
export CLIGetParamUCol
export CLIGetParamURow
export CLIGetParamMatWithInfo
export CLIEnableVerbose
export CLIDisableVerbose
export CLISetPassed

import mlpack_jll
const library = mlpack_jll.libmlpack_julia_util

# Utility function to convert 1d object to 2d.
function convert_to_2d(in::Array{T, 1})::Array{T, 2} where T
  reshape(in, length(in), 1)
end

# Utility function to convert 2d object to 1d.  Fails if the size of one
# dimension is not 1.
function convert_to_1d(in::Array{T, 2})::Array{T, 1} where T
  if size(in, 1) != 1 && size(in, 2) != 1
    throw(ArgumentError("given matrix must be 1-dimensional; but its size is " *
        "$(size(in))"))
  end

  vec(in)
end

# Utility function to convert to and return a matrix.
function to_matrix(input, T::Type)
  if isa(input, Array{T, 1})
    convert_to_2d(input)
  else
    convert(Array{T, 2}, input)
  end
end

# Utility function to convert to and return a vector.
function to_vector(input, T::Type)
  if isa(input, Array{T, 1})
    input
  else
    convert_to_1d(convert(Array{T, 2}, input))
  end
end

function CLIRestoreSettings(programName::String)
  ccall((:CLI_RestoreSettings, library), Nothing, (Cstring,), programName);
end

function CLISetParam(paramName::String, paramValue::Int)
  ccall((:CLI_SetParamInt, library), Nothing, (Cstring, Cint), paramName,
      Cint(paramValue));
end

function CLISetParam(paramName::String, paramValue::Float64)
  ccall((:CLI_SetParamDouble, library), Nothing, (Cstring, Float64), paramName,
      paramValue);
end

function CLISetParam(paramName::String, paramValue::Bool)
  ccall((:CLI_SetParamBool, library), Nothing, (Cstring, Bool), paramName,
      paramValue);
end

function CLISetParam(paramName::String, paramValue::String)
  ccall((:CLI_SetParamString, library), Nothing, (Cstring, Cstring), paramName,
      paramValue);
end

function CLISetParamMat(paramName::String,
                        paramValue,
                        pointsAsRows::Bool)
  paramMat = to_matrix(paramValue, Float64)
  ccall((:CLI_SetParamMat, library), Nothing, (Cstring, Ptr{Float64}, Csize_t,
      Csize_t, Bool), paramName, Base.pointer(paramMat), size(paramMat, 1),
      size(paramMat, 2), pointsAsRows);
end

function CLISetParamUMat(paramName::String,
                         paramValue,
                         pointsAsRows::Bool)
  paramMat = to_matrix(paramValue, Int)

  # Sanity check.
  if minimum(paramMat) <= 0
    throw(DomainError("Input $(paramName) cannot have 0 or negative values!  " *
        "Must be 1 or greater."))
  end

  m = convert(Array{Csize_t, 2}, paramMat .- 1)
  ccall((:CLI_SetParamUMat, library), Nothing, (Cstring, Ptr{Csize_t}, Csize_t,
      Csize_t, Bool), paramName, Base.pointer(m), size(paramValue, 1),
      size(paramValue, 2), pointsAsRows);
end

function CLISetParam(paramName::String,
                     vector::Vector{String})
  # For this we have to set the size of the vector then each string
  # sequentially.  I am not sure if this is fully necessary but I have some
  # reservations about Julia's support for passing arrays of strings correctly
  # as a const char**.
  ccall((:CLI_SetParamVectorStrLen, library), Nothing, (Cstring, Csize_t),
      paramName, size(vector, 1));
  for i in 1:size(vector, 1)
    ccall((:CLI_SetParamVectorStrStr, library), Nothing, (Cstring, Cstring,
        Csize_t), paramName, vector[i], i .- 1);
  end
end

function CLISetParam(paramName::String,
                     vector::Vector{Int})
  cint_vec = convert(Vector{Cint}, vector)
  ccall((:CLI_SetParamVectorInt, library), Nothing, (Cstring, Ptr{Cint},
      Csize_t), paramName, Base.pointer(cint_vec), size(cint_vec, 1));
end

function CLISetParam(paramName::String,
                     matWithInfo::Tuple{Array{Bool, 1}, Array{Float64, 2}},
                     pointsAsRows::Bool)
  ccall((:CLI_SetParamMatWithInfo, library), Nothing, (Cstring, Ptr{Bool},
      Ptr{Float64}, Int, Int, Bool), paramName,
      Base.pointer(matWithInfo[1]), Base.pointer(matWithInfo[2]),
      size(matWithInfo[2], 1), size(matWithInfo[2], 2), pointsAsRows);
end

function CLISetParamRow(paramName::String,
                        paramValue)
  paramVec = to_vector(paramValue, Float64)
  ccall((:CLI_SetParamRow, library), Nothing, (Cstring, Ptr{Float64}, Csize_t),
      paramName, Base.pointer(paramVec), size(paramVec, 1));
end

function CLISetParamCol(paramName::String,
                        paramValue)
  paramVec = to_vector(paramValue, Float64)
  ccall((:CLI_SetParamCol, library), Nothing, (Cstring, Ptr{Float64}, Csize_t),
      paramName, Base.pointer(paramVec), size(paramVec, 1));
end

function CLISetParamURow(paramName::String,
                         paramValue)
  paramVec = to_vector(paramValue, Int)

  # Sanity check.
  if minimum(paramVec) <= 0
    throw(DomainError("Input $(paramName) cannot have 0 or negative values!  " *
        "Must be 1 or greater."))
  end
  m = convert(Array{Csize_t, 1}, paramVec .- 1)

  ccall((:CLI_SetParamURow, library), Nothing, (Cstring, Ptr{Csize_t}, Csize_t),
      paramName, Base.pointer(m), size(paramValue, 1));
end

function CLISetParamUCol(paramName::String,
                         paramValue)
  paramVec = to_vector(paramValue, Int)

  # Sanity check.
  if minimum(paramVec) <= 0
    throw(DomainError("Input $(paramName) cannot have 0 or negative values!  " *
        "Must be 1 or greater."))
  end
  m = convert(Array{Csize_t, 1}, paramValue .- 1)

  ccall((:CLI_SetParamUCol, library), Nothing, (Cstring, Ptr{Csize_t}, Csize_t),
      paramName, Base.pointer(m), size(paramValue, 1));
end

function CLIGetParamBool(paramName::String)
  return ccall((:CLI_GetParamBool, library), Bool, (Cstring,), paramName)
end

function CLIGetParamInt(paramName::String)
  return Int(ccall((:CLI_GetParamInt, library), Cint, (Cstring,), paramName))
end

function CLIGetParamDouble(paramName::String)
  return ccall((:CLI_GetParamDouble, library), Float64, (Cstring,), paramName)
end

function CLIGetParamString(paramName::String)
  return ccall((:CLI_GetParamString, library), Cstring, (Cstring,), paramName)
end

function CLIGetParamVectorStr(paramName::String)
  local size::Csize_t
  local ptr::Ptr{String}

  # Get the size of the vector, then each element.
  size = ccall((:CLI_GetParamVectorStrLen, library), Csize_t, (Cstring,),
      paramName);
  out = Array{String, 1}()
  for i = 1:size
    s = ccall((:CLI_GetParamVectorStrStr, library), Cstring, (Cstring, Csize_t),
        paramName, i .- 1)
    push!(out, Base.unsafe_string(s))
  end

  return out
end

function CLIGetParamVectorInt(paramName::String)
  local size::Csize_t
  local ptr::Ptr{Cint}

  # Get the size of the vector, then the pointer to it.  We will own the
  # pointer.
  size = ccall((:CLI_GetParamVectorIntLen, library), Csize_t, (Cstring,),
      paramName);
  ptr = ccall((:CLI_GetParamVectorIntPtr, library), Ptr{Cint}, (Cstring,),
      paramName);

  return convert(Array{Int, 1}, Base.unsafe_wrap(Array{Cint, 1}, ptr, (size),
      own=true))
end

function CLIGetParamMat(paramName::String, pointsAsRows::Bool)
  # Can we return different return types?  For now let's restrict to a matrix to
  # make it easy...
  local ptr::Ptr{Float64}
  local rows::Csize_t, cols::Csize_t;
  # I suppose it would be possible to do this all in one call, but this seems
  # easy enough.
  rows = ccall((:CLI_GetParamMatRows, library), Csize_t, (Cstring,), paramName);
  cols = ccall((:CLI_GetParamMatCols, library), Csize_t, (Cstring,), paramName);
  ptr = ccall((:CLI_GetParamMat, library), Ptr{Float64}, (Cstring,), paramName);

  if pointsAsRows
    # In this case we have to transpose, unfortunately.
    m = Base.unsafe_wrap(Array{Float64, 2}, ptr, (rows, cols), own=true)
    return m';
  else
    # Here no transpose is necessary.
    return Base.unsafe_wrap(Array{Float64, 2}, ptr, (rows, cols), own=true);
  end
end

function CLIGetParamUMat(paramName::String, pointsAsRows::Bool)
  # Can we return different return types?  For now let's restrict to a matrix to
  # make it easy...
  local ptr::Ptr{Csize_t}
  local rows::Csize_t, cols::Csize_t;
  # I suppose it would be possible to do this all in one call, but this seems
  # easy enough.
  rows = ccall((:CLI_GetParamUMatRows, library), Csize_t, (Cstring,), paramName);
  cols = ccall((:CLI_GetParamUMatCols, library), Csize_t, (Cstring,), paramName);
  ptr = ccall((:CLI_GetParamUMat, library), Ptr{Csize_t}, (Cstring,), paramName);

  if pointsAsRows
    # In this case we have to transpose, unfortunately.
    m = Base.unsafe_wrap(Array{Csize_t, 2}, ptr, (rows, cols), own=true);
    return convert(Array{Int, 2}, m' .+ 1)  # Add 1 because these are indexes.
  else
    # Here no transpose is necessary.
    m = Base.unsafe_wrap(Array{Csize_t, 2}, ptr, (rows, cols), own=true);
    return convert(Array{Int, 2}, m .+ 1)
  end
end

function CLIGetParamCol(paramName::String)
  local ptr::Ptr{Float64};
  local rows::Csize_t;

  rows = ccall((:CLI_GetParamColRows, library), Csize_t, (Cstring,), paramName);
  ptr = ccall((:CLI_GetParamCol, library), Ptr{Float64}, (Cstring,), paramName);

  return Base.unsafe_wrap(Array{Float64, 1}, ptr, rows, own=true);
end

function CLIGetParamRow(paramName::String)
  local ptr::Ptr{Float64};
  local cols::Csize_t;

  cols = ccall((:CLI_GetParamRowCols, library), Csize_t, (Cstring,), paramName);
  ptr = ccall((:CLI_GetParamRow, library), Ptr{Float64}, (Cstring,), paramName);

  return Base.unsafe_wrap(Array{Float64, 1}, ptr, cols, own=true);
end

function CLIGetParamUCol(paramName::String)
  local ptr::Ptr{Csize_t};
  local rows::Csize_t;

  rows = ccall((:CLI_GetParamUColRows, library), Csize_t, (Cstring,), paramName);
  ptr = ccall((:CLI_GetParamUCol, library), Ptr{Csize_t}, (Cstring,), paramName);

  m = Base.unsafe_wrap(Array{Csize_t, 1}, ptr, rows, own=true);
  return convert(Array{Int, 1}, m .+ 1)
end

function CLIGetParamURow(paramName::String)
  local ptr::Ptr{Csize_t};
  local cols::Csize_t;

  cols = ccall((:CLI_GetParamURowCols, library), Csize_t, (Cstring,), paramName);
  ptr = ccall((:CLI_GetParamURow, library), Ptr{Csize_t}, (Cstring,), paramName);

  m = Base.unsafe_wrap(Array{Csize_t, 1}, ptr, cols, own=true);
  return convert(Array{Int, 1}, m .+ 1)
end

function CLIGetParamMatWithInfo(paramName::String, pointsAsRows::Bool)
  local ptrBool::Ptr{Bool};
  local ptrData::Ptr{Float64};
  local rows::Csize_t;
  local cols::Csize_t;

  rows = ccall((:CLI_GetParamMatWithInfoRows, library), Csize_t, (Cstring,),
      paramName);
  cols = ccall((:CLI_GetParamMatWithInfoCols, library), Csize_t, (Cstring,),
      paramName);
  ptrBool = ccall((:CLI_GetParamMatWithInfoBoolPtr, library), Ptr{Bool},
      (Cstring,), paramName);
  ptrMem = ccall((:CLI_GetParamMatWithInfoPtr, library), Ptr{Float64},
      (Cstring,), paramName);

  types = Base.unsafe_wrap(Array{Bool, 1}, ptrBool, (rows), own=true)
  if pointsAsRows
    # In this case we have to transpose, unfortunately.
    m = Base.unsafe_wrap(Array{Float64, 2}, ptr, (rows, cols), own=true)
    return (types, m');
  else
    # Here no transpose is necessary.
    return (types, Base.unsafe_wrap(Array{Float64, 2}, ptr, (rows, cols),
        own=true));
  end
end

function CLIEnableVerbose()
  ccall((:CLI_EnableVerbose, library), Nothing, ());
end

function CLIDisableVerbose()
  ccall((:CLI_DisableVerbose, library), Nothing, ());
end

function CLISetPassed(paramName::String)
  ccall((:CLI_SetPassed, library), Nothing, (Cstring,), paramName);
end

end # module cli
