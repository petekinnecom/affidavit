require "test_helper"
require "json"
require "active_support/time"

class ReadmeExampleTest < Minitest::Test
  include Affidavit::Builder
  PRICES = {
    apple: x(1, metadata: { label: "price", fruit: "apple" }),
    banana: x(10, metadata: { label: "price", fruit: "banana" }),
  }

  def test_example

    num_apples = x(5, metadata: { label: "quantity", fruit: "apple" })
    num_bananas = x(1, metadata: { label: "quantity", fruit: "banana" })

    amount_due = [
      num_apples.x(:*, PRICES[:apple]),
      num_bananas.x(:*, PRICES[:banana])
    ].x(:sum)

  end

end
