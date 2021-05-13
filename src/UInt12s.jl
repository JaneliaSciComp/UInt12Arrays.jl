module UInt12s

using BitIntegers
using ..UInt24s

export UInt12


# From BitIntegers:

## convenient abbreviations, only for internal use

const BBS = Base.BitSigned
const BBU = Base.BitUnsigned
const BBI = Base.BitInteger

# eXtended
const XBS = BitIntegers.AbstractBitSigned
const XBU = BitIntegers.AbstractBitUnsigned
const XBI = Union{XBS,XBU}

# Union, Unified
const UBS = Union{BBS,XBS}
const UBU = Union{BBU,XBU}
const UBI = Union{BBI,XBI}

# End from BitIntegers

# Abstract UInt12

abstract type AbstractUInt12 <: Unsigned end

const UINT12_TYPEMAX = 2^12 - 1

Base.typemin(::Type{T}) where T <: AbstractUInt12 = convert(T, 0)
Base.typemax(::Type{T}) where T <: AbstractUInt12 = convert(T, UINT12_TYPEMAX)

# Concrete base UInt12 type

struct UInt12{T <: Union{Bool, Unsigned}} <: AbstractUInt12
    data::T
    function UInt12{T}(data::Union{Bool, UBI}) where T
        if data > 0xfff
            throw( InexactError(:UInt12, UInt12, data))
        else
            new{T}(data)
        end
    end
end

# Default UInt12 constructor uses UInt16
UInt12(x::Union{Bool, UBU}) = UInt12{UInt16}(x)
UInt12(x::UBS) = UInt12{UInt16}(UInt16(x))
UInt12(x::Union{Float16, Float32, Float64}) = UInt12(UInt16(x))
#UInt12(x::Union{Bool, Base.BitInteger, BitIntegers.AbstractBitSigned, BitIntegers.AbstractBitUnsigned}) = UInt12{UInt16}(x)
#UInt12{UInt16}(x::Union{Bool, Base.BitInteger, BitIntegers.AbstractBitSigned, BitIntegers.AbstractBitUnsigned}) = UInt12{UInt16}(x)

Base.uinttype(::Type{UInt12{T}}) where T = UInt12{T}
Base.widen(::Type{UInt12{T}}) where T = UInt24

macro uint12_str(s)
    return UInt12(parse(UInt16, s))
end

Core.UInt16(x::UInt12) = UInt16(x.data)
Core.Int64(x::UInt12) = Int64(x.data)
Core.UInt64(x::UInt12) = UInt64(x.data)

Base.show(io::IO, n::UInt12) = print(io, "0x", string(n, pad = 3, base = 16))
Base.hex(x::UInt12, pad::Integer, neg::Bool) = Base.hex(x.data, pad, neg)
Base.bin(x::UInt12, pad::Integer, neg::Bool) = Base.bin(x.data, pad, neg)
Base.promote_rule(::Type{UInt12{T}}, o::Type{S}) where {T,S} = promote_type(T, o)
Base.:+(x::UInt12{T}, y::Union{Bool, UBU}) where T = UInt12{T}( (x.data + y) % 0x1000 )

Base.:<(x::UInt12, y::UInt12) = x.data < y.data
Base.:<=(x::UInt12, y::UInt12) = x.data <= y.data

Base.:(==)(x::UInt12, y::UInt12) = x.data == y.data

# bit operations

Base.:(~)(x::UInt12{T}) where T = UInt12{T}(~x.data & 0xfff)
Base.:(&)(x::UInt12{T}, y::UInt12{T}) where {T} = UInt12{T}(x.data & y.data)
Base.:(|)(x::UInt12{T}, y::UInt12{T}) where {T} = UInt12{T}(x.data | y.data)
Base.xor(x::UInt12{T}, y::UInt12{T}) where {T} = UInt12{T}( xor(x.data, y.data) )

Base.:>>(x::UInt12{T}, y::UBU) where T = UInt12{T}(x.data >> y)
Base.:>>>(x::UInt12{T}, y::UBU) where T = UInt12{T}(x.data >>> y)
Base.:<<(x::UInt12{T}, y::UBU) where T = UInt12{T}( (x.data << y) & 0xfff )

Base.count_ones(x::UInt12) = count_ones(x.data)
Base.leading_zeros(x::UInt12{UInt16}) = leading_zeros(x.data) - 4
Base.leading_zeros(x::UInt12{T}) where T = leading_zeros(x.data) - sizeof(T)*8 + 12
Base.trailing_zeros(x::UInt12) = trailing_zeros(x.data)

Base.isodd(x::UInt12) = isodd(x.data)

# arithmetic operations
Base.:(-)(x::UInt12{T}) where T = UInt12{T}( (-x.data) & 0xfff )
Base.:(-)(x::UInt12{T}, y::UInt12{T}) where T = UInt12{T}( (x.data - y.data) & 0xfff )
Base.:(+)(x::UInt12{T}, y::UInt12{T}) where T = UInt12{T}( (x.data + y.data) & 0xfff )
Base.:(*)(x::UInt12{T}, y::UInt12{T}) where T = UInt12{T}( (x.data * y.data) & 0xfff )

Base.div(x::UInt12{T}, y::UInt12{T}) where T = UInt12{T}( x.data ÷ y.data )
Base.rem(x::UInt12{T}, y::UInt12{T}) where T = UInt12{T}( rem(x.data, y.data) )

Base.checked_abs(x::UInt12) = x

Base.bitstring(x::UInt12) = string(x, pad=12, base = 2)

end