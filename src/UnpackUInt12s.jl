module UnpackUInt12s

    using SIMD
    using ..UInt24s
    import ..UInt12ArraysBase: UInt12Array, map_idx_to_byte

    include( joinpath("unpack", "unpack_simd_256.jl") )
    include( joinpath("unpack", "unpack_simd_512.jl") )

    function _convert_to_UInt16(data::AbstractVector{UInt8}, size)
        bytes_required = cld((prod(size) * 3), 2)
        bytes_available = length(data)
        if bytes_available < bytes_required
            throw(BoundsError(data, (firstindex(data) + bytes_required - 1,)))
        end
        n, r = fldmod(bytes_required, 3)
        out = Array{UInt16}(undef, size)
        @inbounds for i in 0:n-1
            a = data[begin+3*i+0]
            b = data[begin+3*i+1]
            c = data[begin+3*i+2]
            merged = UInt32(a) | UInt32(b)<<8 | UInt32(c)<<16
            out[begin+2*i+0] = merged%UInt16 & 0x0FFF
            out[begin+2*i+1] = (merged>>12)%UInt16
        end
        @inbounds if r == 2
            out[end] = (UInt16(data[begin+3*n]) | UInt16(data[begin+3*n+1])<<8) & 0x0FFF
        end
        out
    end

    function Base.convert(::Type{Array{UInt16,N}}, A::UInt12Array{UInt16,B,N})::Array{UInt16,N} where {B <: SIMD.FastContiguousArray{UInt8,1}, N}
        len = length(A)
        if len < 64
            return _convert_to_UInt16(A.data, size(A))
        else
            @debug "Using SIMD" len
            return reshape(unpack_uint12_to_uint16(A.data), size(A))
        end
    end
    function Base.convert(::Type{Array{UInt16,N}}, A::UInt12Array{UInt16,B,N})::Array{UInt16,N} where {B, N}
        _convert_to_UInt16(A.data, size(A))
    end
 
    Base.convert(::Type{Array{UInt16}}, A::UInt12Array{UInt16,B,N}) where {B <: SIMD.FastContiguousArray{UInt8,1}, N} =
        Base.convert(Array{UInt16,N}, A)

    function Base.convert(::Type{Array{UInt16,1}}, S::SubArray{UInt16, 1, UInt12Array{UInt16, B, 1}, <: Tuple{UnitRange}}) where {B <: SIMD.FastContiguousArray{UInt8,1}}
        try
            if S |> parentindices |> first |> first |> isodd
                convert(Vector{UInt16}, convert(UInt12Array{UInt16}, S))
            elseif length(S) < 16
                Array{UInt16,1}(S)
            else
                out = Array{UInt16,1}(undef, length(S))
                # Copy first element
                out[1] = S[1]
                # Convert the rest using SIMD
                Arest = convert(UInt12Array{UInt16}, @view S[2:end])
                unpack_uint12_to_uint16(Arest.data, @view out[2:end])
                out
            end
        catch err
            @warn "Unable to convert using SIMD. Defaulting to slower element-wise conversion." err
            Array{UInt16,1}(S)
        end
    end
    Base.convert(::Type{Vector}, S::SubArray{UInt16, 1, UInt12Array{UInt16, B, 1}, <: Tuple{UnitRange}}) where {B <: SIMD.FastContiguousArray{UInt8,1}} =
        Base.convert(Vector{UInt16}, S)
    Base.convert(::Type{Array}, S::SubArray{UInt16, 1, UInt12Array{UInt16, B, 1}, <: Tuple{UnitRange}}) where {B <: SIMD.FastContiguousArray{UInt8,1}} =
        Base.convert(Vector{UInt16}, S)
end
