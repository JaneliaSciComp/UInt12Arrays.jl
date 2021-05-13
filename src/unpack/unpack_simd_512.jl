# AVX-512 (64 bytes)
const shuffle_48_bytes_to_64 = ( shuffle_24_bytes_to_32..., shuffle_24_bytes_to_32 .+ 24... )
const shuffle_48_bytes_to_64_val = Val{shuffle_48_bytes_to_64}()
const shuffle_48_bytes_to_64_m8_val = Val{shuffle_48_bytes_to_64 .+ 8}()
const shuffle_48_bytes_to_64_m16_val = Val{shuffle_48_bytes_to_64 .+ 16}()
const choose_even_odd_ints_32 = Val( ntuple(i->isodd(i-1)*32 + i -1, 32) )

"""
    unpack_uint12_to_uint16_512bits(A::Vector{UInt8}, out::Vector{UInt16}, [ i ])

    Unpack 12-bit integers into 16-bit integers. Two 12-bit integers are packed consecutively into three bytes.
"""
@inline function unpack_uint12_to_uint16_512bits(
    A::SIMD.FastContiguousArray{UInt8,1},
    out::SIMD.FastContiguousArray{UInt16,1},
    i,
    offset = 0,
    shuffle_48_bytes_to_64::Val{T} = shuffle_48_bytes_to_64_val,
    ) where T
    # Load 32 bytes (we only use the first 24)
    a = @inbounds vload(Vec{64,UInt8}, A, i-offset)

    a16 = reinterpret( Vec{32, UInt16}, shufflevector(a, shuffle_48_bytes_to_64) )

    a16 = shufflevector(a16 & 0xfff, a16 >> 4, choose_even_odd_ints_32)

    @inbounds vstore(a16, out, 1 + 2( ( i-1 ) ÷ 3) )
end
@inline unpack_uint12_to_uint16_512bits_m8(A, out, i) = unpack_uint12_to_uint16_512bits(A, out, i, 8, shuffle_48_bytes_to_64_m8_val)
@inline unpack_uint12_to_uint16_512bits_m16(A, out, i) = unpack_uint12_to_uint16_512bits(A, out, i, 16, shuffle_48_bytes_to_64_m16_val)

"""
    unpack_uint12_to_uint16_512bits(A::SIMD.FastContiguousArray{UInt8,1}, out::Vector{UInt16})

    Unpack entire array with a preallocated out buffer for compressed data
"""
function unpack_uint12_to_uint16_512bits(A::SIMD.FastContiguousArray{UInt8,1}, out::SIMD.FastContiguousArray{UInt16,1})
    unpack_uint12_to_uint16_512bits(A, out, 1)
    idx = 49:48:length(A)
    @inbounds for i = idx[1:end-1]
       unpack_uint12_to_uint16_512bits_m8(A, out, i)
    end
    unpack_uint12_to_uint16_512bits_m16(A, out, length(A)-47)
    out
end

"""
    unpack_uint12_to_uint16_512bits(A::SIMD.FastContiguousArray{UInt8,1})

    Unpack entire array, allocates and returns output buffer
"""
function unpack_uint12_to_uint16_512bits(A::SIMD.FastContiguousArray{UInt8,1})
    out = Vector{UInt16}(undef, length(A) ÷ 3 * 2)
    unpack_uint12_to_uint16_512bits(A, out)
end