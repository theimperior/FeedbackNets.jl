@testset "FeedbackTrees" begin
    @testset "constructor" begin
        # 1. can construct a FeedbackTree like a normal chain
        c = FeedbackTree(Dense(10, 5), relu)
        @test length(c.layers) == 2
        # 2. can construct a FeedbackTree with forkers and mergers
        c = FeedbackTree(Merger("f1", identity, +), Dense(10, 10, relu), Splitter("f1"), Dense(10, 1))
        @test length(c.layers) == 4
    end # @testset "constructor"

    @testset "apply" begin
        h = Dict("f1" => rand(10))
        x = randn(10)
        # apply empty tree
        c = FeedbackTree()
        @test c(h, x) == (h, x)
        # apply tree without feedback
        c = FeedbackTree(x -> (2.0 .* x), x -> relu.(x), x -> x'x)
        state, y = c(Dict(), x)
        @test y ≈ relu.(2.0 .* x)'relu.(2.0 .* x)
        @test state isa Dict{String, Any}
        # apply tree with feedback
        l1 = Dense(10, 10, relu)
        l2 = Dense(10, 1)
        c = FeedbackTree(Merger("f1", identity, +), l1, Splitter("f1"), l2)
        state, y = c(h, x)
        @test y ≈ l2(h["f1"])
        @test haskey(state, "f1")
        @test state["f1"] ≈ l1(h["f1"] + x)
    end # @testset "apply"

    @testset "params" begin
        l1 = Dense(10, 10)
        l2 = Dense(7, 10)
        c = FeedbackTree(l1, l2)
        @test hcat(params(c)...) == hcat(params(l1)..., params(l2)...)
    end # @testset "params"

    @testset "recur" begin
        h = Dict("f1" => randn(10))
        x = randn(10)
        l1 = Dense(10, 10, relu)
        l2 = Dense(10, 1)
        c = FeedbackTree(Merger("f1", identity, +), l1, Splitter("f1"), l2)
        c = Flux.Recur(c, h)
        y = c(x)
        @test y ≈ l2(h["f1"])
        @test haskey(c.state, "f1")
        @test c.state["f1"] ≈ l1(h["f1"] + x)
    end # @testset "recur"
end # @testset "FeedbackTrees"
