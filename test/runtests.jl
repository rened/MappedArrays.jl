using MappedArrays, FixedPointNumbers, OffsetArrays
using Base.Test

a = [1,4,9,16]
s = view(a', 1:1, [1,2,4])

b = @inferred(mappedarray(sqrt, a))
@test parent(b) === a
@test eltype(b) == Float64
@test @inferred(getindex(b, 1)) == 1
@test b[2] == 2
@test b[3] == 3
@test b[4] == 4
@test_throws ErrorException b[3] = 0
@test isa(eachindex(b), AbstractUnitRange)
b = mappedarray(sqrt, a')
@test isa(eachindex(b), AbstractUnitRange)
b = mappedarray(sqrt, s)
@test isa(eachindex(b), CartesianRange)

c = @inferred(mappedarray((sqrt, x->x*x), a))
@test parent(c) === a
@test @inferred(getindex(c, 1)) == 1
@test c[2] == 2
@test c[3] == 3
@test c[4] == 4
c[3] = 2
@test a[3] == 4
@test_throws InexactError c[3] = 2.2  # because the backing array is Array{Int}
@test isa(eachindex(c), AbstractUnitRange)
b = @inferred(mappedarray(sqrt, a'))
@test isa(eachindex(b), AbstractUnitRange)
c = @inferred(mappedarray((sqrt, x->x*x), s))
@test isa(eachindex(c), CartesianRange)

sb = similar(b)
@test isa(sb, Array{Float64})
@test size(sb) == size(b)

a = [0x01 0x03; 0x02 0x04]
b = @inferred(mappedarray((y->N0f8(y,0),x->x.i), a))
for i = 1:4
    @test b[i] == N0f8(i/255)
end
b[2,1] = 10/255
@test a[2,1] == 0x0a

a = [0.1 0.3; 0.2 0.4]
b = @inferred(of_eltype(N0f8, a))
@test b[1,1] === N0f8(0.1)
b = @inferred(of_eltype(zero(N0f8), a))
@test b[1,1] === N0f8(0.1)
b[2,1] = N0f8(0.5)
@test a[2,1] == N0f8(0.5)
@test !(b === a)
b = @inferred(of_eltype(Float64, a))
@test b === a
b = @inferred(of_eltype(0.0, a))
@test b === a

# OffsetArrays
a = OffsetArray(randn(5), -2:2)
aabs = mappedarray(abs, a)
@test indices(aabs) == (-2:2,)
for i = -2:2
    @test aabs[i] == abs(a[i])
end

# issue #7
astr = @inferred(mappedarray(length, ["abc", "onetwothree"]))
@test eltype(astr) == Int
@test astr == [3, 11]
a = @inferred(mappedarray(x->x+0.5, Int[]))
@test eltype(a) == Float64

# typestable string
astr = @inferred(mappedarray(uppercase, ["abc", "def"]))
@test eltype(astr) == String
@test astr == ["ABC","DEF"]

# multiple arrays
a = reshape(1:6, 2, 3)
@test @inferred(indices(a)) == (Base.OneTo(2), Base.OneTo(3)) # prevents error on 0.7
b = fill(10.0f0, 2, 3)
M = @inferred(mappedarray(+, a, b))
@test @inferred(eltype(M)) == Float32
@test @inferred(IndexStyle(M)) == IndexLinear()
@test @inferred(IndexStyle(typeof(M))) == IndexLinear()
@test @inferred(indices(M)) === indices(a)
@test M == a + b
@test @inferred(M[1]) === 11.0f0
@test @inferred(M[CartesianIndex(1, 1)]) === 11.0f0

c = view(reshape(1:9, 3, 3), 1:2, :)
M = @inferred(mappedarray(+, c, b))
@test @inferred(eltype(M)) == Float32
@test @inferred(IndexStyle(M)) == IndexCartesian()
@test @inferred(IndexStyle(typeof(M))) == IndexCartesian()
@test @inferred(indices(M)) === indices(c)
@test M == c + b
@test @inferred(M[1]) === 11.0f0
@test @inferred(M[CartesianIndex(1, 1)]) === 11.0f0
