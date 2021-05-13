module UnpackUInt12s

    using SIMD
    using ..UInt24s
    import ..UInt12ArraysBase: UInt12Array

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
                return lutConvertToUInt16(A.data)
            end
        else
            @debug "Using SIMD" len
            return unpack_uint12_to_uint16(A.data)
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
end