export lars

import ..LARS

using mlpack._Internal.io

import mlpack_jll
const larsLibrary = mlpack_jll.libmlpack_julia_lars

# Call the C binding of the mlpack lars binding.
function lars_mlpackMain()
  success = ccall((:lars, larsLibrary), Bool, ())
  if !success
    # Throw an exception---false means there was a C++ exception.
    throw(ErrorException("mlpack binding error; see output"))
  end
end

" Internal module to hold utility functions. "
module lars_internal
  import ..larsLibrary

import ...LARS

# Get the value of a model pointer parameter of type LARS.
function IOGetParamLARS(paramName::String)::LARS
  LARS(ccall((:IO_GetParamLARSPtr, larsLibrary), Ptr{Nothing}, (Cstring,), paramName))
end

# Set the value of a model pointer parameter of type LARS.
function IOSetParamLARS(paramName::String, model::LARS)
  ccall((:IO_SetParamLARSPtr, larsLibrary), Nothing, (Cstring, Ptr{Nothing}), paramName, model.ptr)
end

# Serialize a model to the given stream.
function serializeLARS(stream::IO, model::LARS)
  buf_len = UInt[0]
  buf_ptr = ccall((:SerializeLARSPtr, larsLibrary), Ptr{UInt8}, (Ptr{Nothing}, Ptr{UInt}), model.ptr, pointer(buf_len))
  buf = Base.unsafe_wrap(Vector{UInt8}, buf_ptr, buf_len[1]; own=true)
  write(stream, buf)
end
# Deserialize a model from the given stream.
function deserializeLARS(stream::IO)::LARS
  buffer = read(stream)
  GC.@preserve buffer LARS(ccall((:DeserializeLARSPtr, larsLibrary), Ptr{Nothing}, (Ptr{UInt8}, UInt), pointer(buffer), length(buffer)))
end
end # module

"""
    lars(; [input, input_model, lambda1, lambda2, responses, test, use_cholesky, verbose])

An implementation of LARS: Least Angle Regression (Stagewise/laSso).  This is a
stage-wise homotopy-based algorithm for L1-regularized linear regression (LASSO)
and L1+L2-regularized linear regression (Elastic Net).

This program is able to train a LARS/LASSO/Elastic Net model or load a model
from file, output regression predictions for a test set, and save the trained
model to a file.  The LARS algorithm is described in more detail below:

Let X be a matrix where each row is a point and each column is a dimension, and
let y be a vector of targets.

The Elastic Net problem is to solve

  min_beta 0.5 || X * beta - y ||_2^2 + lambda_1 ||beta||_1 +
      0.5 lambda_2 ||beta||_2^2

If lambda1 > 0 and lambda2 = 0, the problem is the LASSO.
If lambda1 > 0 and lambda2 > 0, the problem is the Elastic Net.
If lambda1 = 0 and lambda2 > 0, the problem is ridge regression.
If lambda1 = 0 and lambda2 = 0, the problem is unregularized linear regression.

For efficiency reasons, it is not recommended to use this algorithm with
`lambda1` = 0.  In that case, use the 'linear_regression' program, which
implements both unregularized linear regression and ridge regression.

To train a LARS/LASSO/Elastic Net model, the `input` and `responses` parameters
must be given.  The `lambda1`, `lambda2`, and `use_cholesky` parameters control
the training options.  A trained model can be saved with the `output_model`.  If
no training is desired at all, a model can be passed via the `input_model`
parameter.

The program can also provide predictions for test data using either the trained
model or the given input model.  Test points can be specified with the `test`
parameter.  Predicted responses to the test points can be saved with the
`output_predictions` output parameter.

For example, the following command trains a model on the data `data` and
responses `responses` with lambda1 set to 0.4 and lambda2 set to 0 (so, LASSO is
being solved), and then the model is saved to `lasso_model`:

```julia
julia> using CSV
julia> data = CSV.read("data.csv")
julia> responses = CSV.read("responses.csv")
julia> lasso_model, _ = lars(input=data, lambda1=0.4, lambda2=0,
            responses=responses)
```

The following command uses the `lasso_model` to provide predicted responses for
the data `test` and save those responses to `test_predictions`: 

```julia
julia> using CSV
julia> test = CSV.read("test.csv")
julia> _, test_predictions = lars(input_model=lasso_model,
            test=test)
```

# Arguments

 - `input::Array{Float64, 2}`: Matrix of covariates (X).
 - `input_model::LARS`: Trained LARS model to use.
 - `lambda1::Float64`: Regularization parameter for l1-norm penalty. 
      Default value `0`.
      
 - `lambda2::Float64`: Regularization parameter for l2-norm penalty. 
      Default value `0`.
      
 - `responses::Array{Float64, 2}`: Matrix of responses/observations (y).
 - `test::Array{Float64, 2}`: Matrix containing points to regress on (test
      points).
 - `use_cholesky::Bool`: Use Cholesky decomposition during computation
      rather than explicitly computing the full Gram matrix.  Default value
      `false`.
      
 - `verbose::Bool`: Display informational messages and the full list of
      parameters and timers at the end of execution.  Default value `false`.
      

# Return values

 - `output_model::LARS`: Output LARS model.
 - `output_predictions::Array{Float64, 2}`: If --test_file is specified,
      this file is where the predicted responses will be saved.

"""
function lars(;
              input = missing,
              input_model::Union{LARS, Missing} = missing,
              lambda1::Union{Float64, Missing} = missing,
              lambda2::Union{Float64, Missing} = missing,
              responses = missing,
              test = missing,
              use_cholesky::Union{Bool, Missing} = missing,
              verbose::Union{Bool, Missing} = missing,
              points_are_rows::Bool = true)
  # Force the symbols to load.
  ccall((:loadSymbols, larsLibrary), Nothing, ());

  IORestoreSettings("LARS")

  # Process each input argument before calling mlpackMain().
  if !ismissing(input)
    IOSetParamMat("input", input, points_are_rows)
  end
  if !ismissing(input_model)
    lars_internal.IOSetParamLARS("input_model", convert(LARS, input_model))
  end
  if !ismissing(lambda1)
    IOSetParam("lambda1", convert(Float64, lambda1))
  end
  if !ismissing(lambda2)
    IOSetParam("lambda2", convert(Float64, lambda2))
  end
  if !ismissing(responses)
    IOSetParamMat("responses", responses, points_are_rows)
  end
  if !ismissing(test)
    IOSetParamMat("test", test, points_are_rows)
  end
  if !ismissing(use_cholesky)
    IOSetParam("use_cholesky", convert(Bool, use_cholesky))
  end
  if verbose !== nothing && verbose === true
    IOEnableVerbose()
  else
    IODisableVerbose()
  end

  IOSetPassed("output_model")
  IOSetPassed("output_predictions")
  # Call the program.
  lars_mlpackMain()

  return lars_internal.IOGetParamLARS("output_model"),
         IOGetParamMat("output_predictions", points_are_rows)
end
