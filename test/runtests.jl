using UInt12Arrays
using Test

@testset "UInt12Arrays.jl" begin
    data = UInt8[0x21, 0x43, 0x65, 0xba, 0xdc, 0xfe]
    A = UInt12Vector(data)
    T = eltype(A)
    @test size(A) == (4,)
    @test A[1] == 0x0321
    @test A[2] == 0x0654
    @test A[3] == 0x0cba
    @test A[4] == 0x0fed
    @test T == UInt12Arrays.default_eltype
    @test typeof(A[1]) == T
    resize!(A, 5)
    @test size(A) == (5,)
    A[5] = 0x0987
    @test A[5] == 0x0987
    @test size(data) == (8,)
    push!(A, 0x777)
    @test A[end] == 0x777
    @test_throws InexactError A[end] = 0x7777
    reference_array = [0x321, 0x654, 0xcba, 0xfed, 0x987, 0x777]
    @test UInt12Vector{UInt16}(data, 6) == reference_array
    @test UInt12Vector{UInt12}(data, 6) == reference_array
    @test UInt12Array(data) == reference_array
    @test UInt12Array{UInt16, Vector{UInt8}, 1}(data, (6,)) == reference_array
    B = UInt12Vector(undef, 5)
    @test size(B) == (5,)
    @test size(B.data) == (8,)
    C = UInt12Vector(undef, 6)
    @test size(C) == (6,)
    @test size(C.data) == (9,)
end
