"""
UInt12Arrays supports the use of 12-bit unsigned integers.

The current design is based on reading 12-bit integers from a vector of
byte-multiple unsigned integers (Vector{UInt8}, Vector{UInt16}, Vector{UInt24}).

The default element type is a UInt16 to which provides best usability and
performance. However, a UInt12 type is also provided and can be used via a
parameter.

Note: The use of UInt16 as the default element may change as the UInt12 type
matures and lower level LLVM support emerges.
"""
module UInt12Arrays

using SIMD
using Mmap

const default_eltype = UInt16

# UInt24 is useful since UInt24 represents three bytes and two 12-bit integers
# also widen(::UInt12)
include("UInt24s.jl")
# UInt12 type
include("UInt12s.jl")
# Base array type, may be split off into a discrete package in the future
include("UInt12ArraysBase.jl")
# Accelerated conversion
include("UnpackUInt12s.jl")

import .UInt12ArraysBase: UInt12Array, UInt12Vector
using .UInt12s, .UInt24s
using .UnpackUInt12s

export UInt12Array, UInt12Vector, UInt12, UInt24

end