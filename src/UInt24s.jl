module UInt24s

using BitIntegers
#using ..UInt12s

export UInt24

BitIntegers.@define_integers 24

const DEFAULT_TYPE = UInt16

# upper_and_lower(x::UInt24, ::Type{T} ) where T = ( T(x & 0xfff), T(x >> 12) )
first(::Type{T}, x::UInt24) where T = T(x & 0xfff)
last(::Type{T}, x::UInt24) where T = T(x >> 12)
Base.first(x::UInt24) = first(DEFAULT_TYPE, x)
Base.last(x::UInt24) = last(DEFAULT_TYPE, x)


end