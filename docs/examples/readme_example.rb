$LOAD_PATH.unshift(File.expand_path(File.join(__dir__, "../../lib")))

require "affidavit"

include Affidavit::Builder

PRICES = {
  apple: x(1, metadata: { label: "price", fruit: "apple" }),
  banana: x(10, metadata: { label: "price", fruit: "banana" }),
}

num_apples = x(5, metadata: { label: "quantity", fruit: "apple" })
num_bananas = x(1, metadata: { label: "quantity", fruit: "banana" })

amount_due = x([
  num_apples.x(:*, PRICES[:apple]),
  num_bananas.x(:*, PRICES[:banana])
]).x(:sum)

explorer = Affidavit::Explorer.new(amount_due.serialize)

prices = (
  explorer
    .filter_map { |node|
      next unless node.dig("metadata", "label") == "price"

      [node.dig("metadata", "fruit"), node.dig("value")]
    }
    .to_h
)

quantities = (
  explorer
    .filter_map { |node|
      next unless node.dig("metadata", "label") == "quantity"

      [node.dig("metadata", "fruit"), node.dig("value")]
    }
    .to_h
)

puts "prices: #{prices.inspect}"
puts "quantities: #{quantities.inspect}"
puts "---"
puts "All of the data:"
pp amount_due.serialize
