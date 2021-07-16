# m = (0,1,1,2)
# shuffle_24_bytes_to_32 = Val( ntuple(i->m[mod1(i,4)] +  3( (i-1)÷4 ),32) )
const shuffle_24_bytes_to_32 =  (
     0,  1,  1,  2,
     3,  4,  4,  5,
     6,  7,  7,  8,
     9, 10, 10, 11,
    12, 13, 13, 14,
    15, 16, 16, 17,
    18, 19, 19, 20,
    21, 22, 22, 23
)

# AVX 256-bit (32 bytes)
const shuffle_24_bytes_to_32_val = Val{shuffle_24_bytes_to_32}()
const shuffle_24_bytes_to_32_m4_val = Val{shuffle_24_bytes_to_32 .+ 4}()
const shuffle_24_bytes_to_32_m8_val = Val{shuffle_24_bytes_to_32 .+ 8}()
const choose_even_odd_ints_16 = Val( ntuple(i->isodd(i-1)*16 + i -1, 16) )

"""
    unpack_uint12_to_uint16(A::Vector{UInt8}, out::Vector{UInt16}, [ i ])

    Unpack 12-bit integers into 16-bit integers. Two 12-bit integers are packed consecutively into three bytes.
"""
@inline function unpack_uint12_to_uint16(
    A::SIMD.FastContiguousArray{UInt8,1},
    out::SIMD.FastContiguousArray{UInt16,1},
    i,
    offset = 0,
    shuffle_24_bytes_to_32::Val{T} = shuffle_24_bytes_to_32_val
    ) where T

    # Load 32 bytes (we only use the first 24)
    a = @inbounds vload(Vec{32,UInt8}, A, i-offset)

    a16 = reinterpret( Vec{16,UInt16}, shufflevector(a, shuffle_24_bytes_to_32) )

    a16 = shufflevector(a16 & 0xfff, a16 >> 4, choose_even_odd_ints_16)

    @inbounds vstore(a16, out, 1 + 2( ( i-1 ) ÷ 3) )
end
@inline unpack_uint12_to_uint16_offset_m4(A, out, i) = unpack_uint12_to_uint16(A, out, i, 4, shuffle_24_bytes_to_32_m4_val)
@inline unpack_uint12_to_uint16_offset_m8(A, out, i) = unpack_uint12_to_uint16(A, out, i, 8, shuffle_24_bytes_to_32_m8_val)

"""
    unpack_uint12_to_uint16(A::SIMD.FastContiguousArray{UInt8,1}, out::Vector{UInt16})

    Unpack entire array with a preallocated out buffer for compressed data
"""
function unpack_uint12_to_uint16(A::SIMD.FastContiguousArray{UInt8,1}, out::SIMD.FastContiguousArray{UInt16,1})
    unpack_uint12_to_uint16(A, out, 1)
    idx = 25:24:length(A)
    @inbounds for i = idx[1:end-1]
        unpack_uint12_to_uint16_offset_m4(A, out, i)
    end
    extra_bytes = rem(length(A), 3)
    unpack_uint12_to_uint16_offset_m8(A, out, length(A) - 23 - extra_bytes)
    if extra_bytes == 1
        out[length(A) * 2 ÷ 3] = A[end]
    elseif extra_bytes == 2
        out[length(A) * 2 ÷ 3] = reinterpret(UInt16, A[end-1:end])[1] & 0xfff
    end
    out
end

"""
    unpack_uint12_to_uint16(A::SIMD.FastContiguousArray{UInt8,1})

    Unpack entire array, allocates and returns output buffer
"""
function unpack_uint12_to_uint16(A::SIMD.FastContiguousArray{UInt8,1})
    out = Vector{UInt16}(undef, length(A) * 2 ÷ 3)
    unpack_uint12_to_uint16(A, out)
end

"""
    unpack_uint12_to_uint16(filepath::AbstractString)

    Load file at filepath, memory map it and unpack
"""
function unpack_uint12_to_uint16(filepath::AbstractString)
    ios = open(filepath, "r")
    A = Mmap.mmap(ios)
    unpack_uint12_to_uint16(A);
    close(ios)
end

function unpack_uint12_to_uint16_partitioned(inn, out = Array{UInt16,1}(undef, div(length(inn), 3, RoundUp)*2))
    partition_length = div( length(inn), Threads.nthreads(), RoundUp)
    # Ensure that partition length is a multiple of three
    partition_length += 3 - mod1(partition_length, 3)
    @debug "Partition Length: " partition_length partition_length ÷ 3 * 2
    inp = collect(Iterators.partition(inn, partition_length))
    outp = collect(Iterators.partition(out, partition_length ÷ 3 * 2))
    @inbounds Threads.@threads for i in eachindex(inp)
        unpack_uint12_to_uint16(inp[i], outp[i])
    end
    out
end

#=

=#
const shiftvec = reinterpret(Vec{16,UInt16},Vec{8,UInt32}(0x00040000))
const andvec = reinterpret(Vec{16,UInt16}, Vec{8,UInt32}(0xffff0fff))
@inline function unpack_uint12_to_uint16_one_shuffle(
    A::SIMD.FastContiguousArray{UInt8,1},
    out::SIMD.FastContiguousArray{UInt16,1},
    i,
    offset = 0,
    shuffle_24_bytes_to_32::Val{T} = shuffle_24_bytes_to_32_val,
    ) where T
    # Load 32 bytes (we only use the first 24)
    a = @inbounds vload(Vec{32,UInt8}, A, i-offset)

    a16 = reinterpret( Vec{16,UInt16}, shufflevector(a, shuffle_24_bytes_to_32) )

    a16 = a16 >> shiftvec & andvec

    @inbounds vstore(a16, out, 1 + 2( ( i-1 ) ÷ 3) )
end