# frozen_string_literal: true

require "test_helper"
require "securerandom"

class TranscriptTest < Minitest::Test
  include Affidavit::Builder

  class CoercedClass1; end
  class CoercedClass2; end

  def setup
    Affidavit.configure do |config|
      config.serialize(CoercedClass1.name) do |thing, serializer|
        "Hi this was a CoercedClass1: #{thing.object_id}"
      end
    end
  end

  def test_serializes_to_primitives
    v1 = x(1, metadata: { custom: "v1"} )
    v2 = x(2, metadata: { custom: "v2"} )

    exp1 = x(v1, :+, v2, metadata: { adding: "reason"} )
    exp2 = x(v1, :-, v2, metadata: { adding: "reason"} )

    result = cond(
      x(v1, :>, v2) => "first result",
      x(v1, :==, v2) => "second result",
      x(v1, :<, v2) => exp1.x(:+, exp2)
    )
    prebaked_hash = {"type"=>"affidavit.conditional",
    "value"=>2,
    "source"=>
     {"conditionals"=>
       [{"type"=>"affidavit.expression",
         "value"=>false,
         "source"=>
          {"receiver"=>
            {"type"=>"affidavit.expression",
             "value"=>1,
             "source"=>{"receiver"=>1, "operation"=>nil, "args"=>[]},
             "metadata"=>{"custom"=>"v1"}},
           "operation"=>">",
           "args"=>
            [{"type"=>"affidavit.expression",
              "value"=>2,
              "source"=>{"receiver"=>2, "operation"=>nil, "args"=>[]},
              "metadata"=>{"custom"=>"v2"}}]},
         "metadata"=>{}},
        {"type"=>"affidavit.expression",
         "value"=>false,
         "source"=>
          {"receiver"=>
            {"type"=>"affidavit.expression",
             "value"=>1,
             "source"=>{"receiver"=>1, "operation"=>nil, "args"=>[]},
             "metadata"=>{"custom"=>"v1"}},
           "operation"=>"==",
           "args"=>
            [{"type"=>"affidavit.expression",
              "value"=>2,
              "source"=>{"receiver"=>2, "operation"=>nil, "args"=>[]},
              "metadata"=>{"custom"=>"v2"}}]},
         "metadata"=>{}},
        {"type"=>"affidavit.expression",
         "value"=>true,
         "source"=>
          {"receiver"=>
            {"type"=>"affidavit.expression",
             "value"=>1,
             "source"=>{"receiver"=>1, "operation"=>nil, "args"=>[]},
             "metadata"=>{"custom"=>"v1"}},
           "operation"=>"<",
           "args"=>
            [{"type"=>"affidavit.expression",
              "value"=>2,
              "source"=>{"receiver"=>2, "operation"=>nil, "args"=>[]},
              "metadata"=>{"custom"=>"v2"}}]},
         "metadata"=>{}}],
      "consequent"=>
       {"type"=>"affidavit.expression",
        "value"=>2,
        "source"=>
         {"receiver"=>
           {"type"=>"affidavit.expression",
            "value"=>3,
            "source"=>
             {"receiver"=>
               {"type"=>"affidavit.expression",
                "value"=>1,
                "source"=>{"receiver"=>1, "operation"=>nil, "args"=>[]},
                "metadata"=>{"custom"=>"v1"}},
              "operation"=>"+",
              "args"=>
               [{"type"=>"affidavit.expression",
                 "value"=>2,
                 "source"=>{"receiver"=>2, "operation"=>nil, "args"=>[]},
                 "metadata"=>{"custom"=>"v2"}}]},
            "metadata"=>{"adding"=>"reason"}},
          "operation"=>"+",
          "args"=>
           [{"type"=>"affidavit.expression",
             "value"=>-1,
             "source"=>
              {"receiver"=>
                {"type"=>"affidavit.expression",
                 "value"=>1,
                 "source"=>{"receiver"=>1, "operation"=>nil, "args"=>[]},
                 "metadata"=>{"custom"=>"v1"}},
               "operation"=>"-",
               "args"=>
                [{"type"=>"affidavit.expression",
                  "value"=>2,
                  "source"=>{"receiver"=>2, "operation"=>nil, "args"=>[]},
                  "metadata"=>{"custom"=>"v2"}}]},
             "metadata"=>{"adding"=>"reason"}}]},
        "metadata"=>{}}},
    "metadata"=>{}}

    assert_empty(
      Hashdiff.best_diff(prebaked_hash, result.serialize)
    )
  end

  def test_serializes_conditionals
    result = cond(
      x(1, :==, 1) => x(3, :+, 4),
      metadata: { label: "check_for_equality" }
    )

    expected = {"type"=>"affidavit.conditional",
    "value"=>7,
    "source"=>
     {"conditionals"=>
       [{"type"=>"affidavit.expression",
         "value"=>true,
         "source"=>{"receiver"=>1, "operation"=>"==", "args"=>[1]},
         "metadata"=>{}}],
      "consequent"=>
       {"type"=>"affidavit.expression",
        "value"=>7,
        "source"=>{"receiver"=>3, "operation"=>"+", "args"=>[4]},
        "metadata"=>{}}},
    "metadata"=>{"label"=>"check_for_equality"}}

    assert_empty Hashdiff.best_diff(expected, result.serialize)
  end

  def test_serialize_memoizes
    serialized_count = 0

    serializer = Affidavit::Serializer.new(
      Affidavit::Serializer::DEFAULT.merge(
        CoercedClass2.name => -> (d, c) { serialized_count += 1 }
      )
    )

    v1 = CoercedClass2.new
    serializer.call(x([v1, v1, v1, v1]))
    serializer.call(x([v1, v1, v1, v1]))

    assert_equal 1, serialized_count
  end
end
