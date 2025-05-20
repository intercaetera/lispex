defmodule LispexTest do
  use ExUnit.Case

  import Lispex

  describe "evaluate:" do
    test "primitive expressions evaluate to themselves" do
      values = [42, true, fn x -> x end, "foobar"]
      results = Enum.map(values, &evaluate/1)

      assert values == results
    end

    test "symbols evaluate to their value in the environment" do
      env = fn :a -> 5 end

      assert evaluate(:a, env) == 5
    end
  end

  describe "special forms:" do
    test "lambda evaluates to a function" do
      fun = evaluate([:lambda, [:x], :x])
      assert is_function(fun)
      assert fun.([5]) == 5
    end 

    test "if evaluates its consequent correctly" do
      assert evaluate([:if, true, "ok", "error"]) == "ok"
    end

    test "if evaluates its alternative correctly" do
      assert evaluate([:if, false, "error", "ok"]) == "ok"
    end

    test "let places its definitions in the correct scope" do
      assert evaluate([:let, [x: 5], :x]) == 5
    end
  end

  describe "programs:" do
    test "k-combinator" do
      program = [
        [:lambda, [:x, :y], :x], 5, 7
      ]

      assert evaluate(program) == 5
    end

    test "factorial" do
      program = [[:lambda, [:n],
        [:if, [:=, :n, 0],
          1,
          [:*, :n, [:rec, [:dec, :n]]]]],
      6]

      assert evaluate(program) == 720
    end

    test "map" do
      program = [:let, [
        double: [:lambda, [:a], [:*, :a, 2]],
        xs: [:list, 1, 2, 3, 4, 5],
        map: [:lambda, [:fn, :as],
          [:if, [:nil?, :as],
            [:list],
            [:cons, [:fn, [:head, :as]], [:rec, :fn, [:tail, :as]]]]
        ]
      ], [:map, :double, :xs]]

      assert evaluate(program) == [2, 4, 6, 8, 10]
    end
  end
end
