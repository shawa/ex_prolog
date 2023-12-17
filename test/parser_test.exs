defmodule ExProlog.ParserTest do
  use ExUnit.Case

  import ExProlog.Parser

  describe "parse/1" do
    test "parses single assignments" do
      assert parse("X = 1") == {:=, [], [{:x, [], nil}, 1]}
    end

    test "parses atoms" do
      assert parse("atom") == :atom
    end

    test "parses compound terms" do
      assert parse("functor(1, [1,2])") == {:functor, [], [1, [1, 2]]}
    end
  end

  describe "parse_compound_line" do
    test "extracts assignments into keyword lists" do
      assert parse_compound_line("X = 1,\nY = 9") == [x: 1, y: 9]
    end
  end
end
