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
    @test convert(Array{UInt16}, A) == A
    @test convert(UInt12Array, @view(A[1:end])) == A
    @test convert(UInt12Array, @view(A[1:3])) == A[1:3]
    @test convert(UInt12Array, @view(A[1:2])) == A[1:2]
    @test convert(UInt12Array, @view(A[1:1])) == A[1:1]
    @test_broken convert(UInt12Array, @view(A[2:end])) == A[2:end]
    @test convert(UInt12Array, @view(A[3:end])) == A[3:end]
    @test_broken convert(UInt12Array, @view(A[4:end])) == A[4:end]
    @test convert(Array{UInt16}, @view(A[1:end])) == A
    @test convert(Array{UInt16}, @view(A[1:3])) == A[1:3]
    @test convert(Array{UInt16}, @view(A[1:2])) == A[1:2]
    @test convert(Array{UInt16}, @view(A[1:1])) == A[1:1]
    @test convert(Array{UInt16}, @view(A[2:end])) == A[2:end]
    @test convert(Array{UInt16}, @view(A[3:end])) == A[3:end]
    @test convert(Array{UInt16}, @view(A[4:end])) == A[4:end]
    @test convert(Array, @view(A[1:1])) == A[1:1]
    @test convert(Array, @view(A[2:end])) == A[2:end]
    @test convert(Array, @view(A[3:end])) == A[3:end]
    @test convert(Array, @view(A[4:end])) == A[4:end]
    extended_data = [data; data[1:3]]
    A3 = UInt12Array(extended_data, 1, 2, 3)
    @test convert(Array{UInt16}, A3) == A3
    @test size(convert(Array{UInt16}, A3)) == (1,2,3)
    @test convert(Array{UInt16,3}, A3) == A3
    @test size(convert(Array{UInt16,3}, A3)) == (1,2,3)
    A3 = UInt12Array(extended_data, 3, 2, 1)
    @test convert(Array{UInt16}, A3) == A3
    @test size(convert(Array{UInt16}, A3)) == (3,2,1)
    @test convert(Array{UInt16,3}, A3) == A3
    @test size(convert(Array{UInt16,3}, A3)) == (3,2,1)
    data36 = rand(UInt8, 36)
    A36 = UInt12Array(data36, 2, 3, 4)
    @test convert(Array{UInt16}, A36) == A36
    @test size(convert(Array{UInt16}, A36)) == size(A36)
    @test convert(Array{UInt16, 3}, A36) == A36
    @test size(convert(Array{UInt16, 3}, A36)) == size(A36)
    data180 = rand(UInt8, 180)
    A180 = UInt12Array(data180, 4, 5, 6)
    @test convert(Array{UInt16}, A180) == A180
    @test size(convert(Array{UInt16}, A180)) == size(A180)
    @test convert(Array{UInt16, 3}, A180) == A180
    @test size(convert(Array{UInt16, 3}, A180)) == size(A180)
end
