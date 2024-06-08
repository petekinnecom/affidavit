# frozen_string_literal: true

require "test_helper"
require "securerandom"

class ExplorerTest < Minitest::Test
  include Affidavit::Builder

  def test_serializes_to_primitives
    skip
    v1 = x(1, metadata: { custom: "v1"} )
    v2 = x(2, metadata: { custom: "v2"} )

    exp1 = x(v1, :+, v2, metadata: { adding: "reason"} )
    exp2 = x(v1, :-, v2, metadata: { adding: "reason"} )

    result = cond(
      x(v1, :>, v2) => "first result",
      x(v1, :==, v2) => "second result",
      x(v1, :<, v2) => exp1.x(:+, exp2)
    )

    explorer = Affidavit::Explorer.new(result.serialize)
    explorer.each do |node|
      next unless node.affidavit.dig("metadata", "custom")

      puts node.affidavit.dig("metadata", "custom")
      puts "path: #{node.path}"
    end
  end
end
