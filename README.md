# UInt12Arrays.jl

## Synposis

UInt12Arrays.jl is a Julia package to support the use of arrays of 12-bit
unsigned integers and their elements. This package's main purpose is to
provide a `UInt12Array` type that allows for the indexing into arrays of packed
`UInt12`s.

## Background

Dealing with 12-bit integers is challenging because the the underlying LLVM
integer support is based on integers that are a multiple of a byte (8-bits).
For integer types that are a multiple of a byte, see
[BitIntegers.jl](https://github.com/rfourquet/BitIntegers.jl).

To use unsigned 12-bit integers (`UInt12`) in computations, it is easiest to
load them as unsigned 16-bit integers (`UInt16`). However, to conserve memory
it may be advantageous to keep the 12-bit integers packed into a dense array.

## What this package does

1. Provide a `UInt12Array` that allows for indexing of arrays of packed `UInt12`s.
2. Allow access of 12-bit integers as type `UInt16` (default element type of `UInt12Array`)
3. Provides a prototype `UInt12` type
