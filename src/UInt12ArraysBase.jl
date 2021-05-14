module UInt12ArraysBase

export UInt12Array, UInt12Vector, UInt12Matrix

import ..UInt12Arrays: default_eltype

abstract type AbstractUInt12Array{T, N} <: AbstractArray{T,N} end

"""
UInt12Array has the following parameters:
T - Element type of the UInt12Array. Typically this might be either UInt12 or UInt16
B - Base type for the UIn12Array's internal vector storage
N - Number of dimensions of the array
"""
mutable struct UInt12Array{T, B <: AbstractVector, N} <: AbstractUInt12Array{T,N}
    data::B
    size::NTuple{N,Int}
end

const UInt12Vector{T,B} = UInt12Array{T, B, 1}
const UInt12Matrix{T,B} = UInt12Array{T, B, 2}

# Constructors

"""
    UInt12Vector(data::Vector{UInt8})

    The default constructor has an element type of UInt16 and is backed by a
    byte (UInt8) vector that consists of packed 12-bit integers. Every three
    bytes in the vector represents two 12-bit integers.

    The following packing is assumed:
    The 8 lower bits of the first integer are contained in the first byte.
    The 4 higher bits of the first integer are first 4 bits of the second byte.
    The 4 lower bits of the second integer are the last 4 bits of the second byte.
    The 8 higher bits of the second integer are contained in the third byte.

# Example
```jldoctest
julia> A = UInt12Array(UInt8[0xba, 0xdc, 0xfe])
2-element UInt12Array{UInt16,Array{UInt8,1},1}:
 0x0cba
 0x0fed

julia> A[1]
0x0cba

julia> copy(A)
2-element Array{UInt16,1}:
 0x0cba
 0x0fed

julia> 
```
"""
UInt12Vector(data::B) where B = UInt12Vector{default_eltype}(data)
UInt12Vector(data::B, length::Int) where B = UInt12Vector{default_eltype}(data, length)
UInt12Matrix(data::B, row::Int, col::Int) where B =
    UInt12Matrix{default_eltype}(data, row, col)
UInt12Array(data::B, row::Int, col::Int, depth::Int) where B =
    UInt12Array{default_eltype}(data, row, col, depth)

UInt12Array(data::B) where B <: AbstractVector = UInt12Vector(data)

"""
    UInt12Vector{T}(data::Vector{UInt8})

    The single parameter constructor allows for specification of an element type. For example
    you may want the element type to actually be a UInt12 rather than the default UInt16.
"""
UInt12Vector{T}(data::B) where {T,B <: AbstractVector} =
    UInt12Vector{T}( reinterpret(UInt8, data) )
UInt12Vector{T}(data::B) where {T,B <: AbstractVector{UInt8}} =
    UInt12Vector{T,B}(data, size(data) .*2 .÷ 3)
UInt12Vector{T}(data::B) where {T,B <: AbstractArray{UInt8}} =
    UInt12Vector{T,B}(data, size(data) .*2 .÷ 3)
UInt12Vector{T}(data::B, length::Int) where {T,B} =
    UInt12Vector{T,B}(data, (length,))
UInt12Matrix{T}(data::B, row::Int, col::Int) where {T,B} =
    UInt12Matrix{T,B}(data, (row,col))
UInt12Array{T}(data::B, row::Int, col::Int, depth::Int) where {T,B} =
    UInt12Array{T,B,3}(data, (row, col, depth))


# Undefined initialization

## Element type not defined, default to UInt16
UInt12Vector(::UndefInitializer, length::Int) = UInt12Vector{default_eltype}(undef, length)
UInt12Matrix(::UndefInitializer, row::Int, col::Int) = UInt12Matrix{default_eltype}(undef, row, col)

UInt12Array(::UndefInitializer, row::Int, col::Int, depth::Int) =
    UInt12Array{UInt16}(undef, row, col, depth)

UInt12Array(::UndefInitializer, d::Vararg{Int, N}) where N =
    UInt12Array{default_eltype}(undef, d...)
    
## Element type defined
UInt12Vector{T}(::UndefInitializer, length::Int) where T = UInt12Array{T}(undef, length)
UInt12Matrix{T}(::UndefInitializer, row::Int, col::Int) where T = UInt12Array{T}(undef, row, col)

UInt12Array{T}(::UndefInitializer, length::Int) where T =
    UInt12Array{T,Vector{UInt8},1}( Vector{UInt8}(undef, ceil(Int, length*3/2)), (length,) )

UInt12Array{T}(::UndefInitializer, rows::Int, cols::Int) where T =
    UInt12Array{T,Vector{UInt8},2}( Vector{UInt8}(undef, ceil(Int, rows*cols*3/2)), (rows, cols,) )

UInt12Array{T}(::UndefInitializer, rows::Int, cols::Int, depth::Int) where T =
    UInt12Array{T,Vector{UInt8},3}( Vector{UInt8}(undef, ceil(Int, rows * cols * depth * 3/2)), (rows, cols, depth) )

UInt12Array{T}(::UndefInitializer, d::Vararg{Int, N}) where {T,N} =
    UInt12Array{T,Vector{UInt8},N}( Vector{UInt8}(undef, ceil(Int, prod(d)*3/2) ), d)



# Generic methods for all parameters
Base.size(data::UInt12Array) = data.size
Base.IndexStyle(::Type{<: UInt12Array}) = IndexLinear()

# Methods for B <: AbstractVector{UInt8}, this assumes a straightforward, dense packing
function Base.getindex(A::UInt12Array{T,<: AbstractVector{UInt8},N}, i::Int) where {T,N}
    @boundscheck checkbounds(A, i)
    first_byte_index = ( (i - 1) ÷ 2 ) *3 + 1
    ord = mod1(i,2)
    if ord == 1
        out = A.data[ first_byte_index ] | ( UInt16(A.data[ first_byte_index + 1] & 0x0f) << 8 )
    else
        out = (A.data[ first_byte_index + 1 ] & 0xf0) >> 4 | ( UInt16(A.data[ first_byte_index + 2]) << 4 )
    end
    convert(T, out)
end
function Base.setindex!(A::UInt12Array{T,<: AbstractVector{UInt8},N}, v, i::Int) where {T,N}
    @boundscheck checkbounds(A, i)
    first_byte_index = ( (i - 1) ÷ 2 ) * 3 + 1
    ord = mod1(i,2)
    p = A.data[ first_byte_index + 1 ]
    if ord == 1
        A.data[ first_byte_index ] = 0xff & v
        A.data[ first_byte_index + 1 ] = ( ( 0xf00 & v ) >> 8 ) | (p & 0xf0)
    else
        A.data[ first_byte_index + 1] = ( ( 0x0f & v) << 4 ) | (p & 0x00f)
        A.data[ first_byte_index + 2] = ( 0xff0 & v ) >> 4
    end
end
function Base.resize!(A::UInt12Array{T,B,N}, nl::Integer) where {T,B <: AbstractVector{UInt8},N}
    resize!(A.data, ceil(Int, nl*3/2) )
    A.size = (nl,)
end

end # module UInt12ArraysBase