module UnpackUInt12s

    using SIMD
    using ..UInt24s
    import ..UInt12ArraysBase: UInt12Array, map_idx_to_byte

    include( joinpath("unpack", "unpack_simd_256.jl") )
    include( joinpath("unpack", "unpack_simd_512.jl") )
   
    # 64 megabtyes when initialized
    const LUT = Ref{Vector{UInt32}}()

    make_lut(x) = make_lut(UInt32(x))
    function make_lut(x::UInt32)
        ( (x & 0xfff000) << 4) | (x & 0x000fff)
    end
    function init_lut()
        if !isdefined(LUT,1) || isempty(LUT[])
            LUT[] = make_lut.( UInt32(0):UInt32(2^24-1) )
        end
    end
    function clear_lut()
        empty!(LUT[])
    end
    function lutConvertToUInt16(A)
        A = reinterpret(UInt24, A)
        init_lut()
        result = LUT[][A .+ 1]
        reinterpret(UInt16, result)
    end

    function Base.convert(::Type{Array{UInt16,N}}, A::UInt12Array{UInt16,B,N}) where {B <: SIMD.FastContiguousArray{UInt8,1}, N}
        len = length(A)
        if len < 64
            if len < 16 || mod(len, 2) == 1
                @debug "Using copy" len
                return copy(A)
            else
                @debug "Using LUT" len
                return reshape(lutConvertToUInt16(A.data), size(A))
            end
        else
            @debug "Using SIMD" len
            return reshape(unpack_uint12_to_uint16(A.data), size(A))
        end
    end
    function Base.convert(::Type{Array{UInt16,N}}, A::UInt12Array{UInt16,B,N}) where {B, N}
        len = length(A)
        if len < 16 || mod(len, 2) == 1
            @debug "Using copy" len
            return copy(A)
        else
            @debug "Using LUT" len
            return lutConvertToUInt16(A.data)
        end
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
