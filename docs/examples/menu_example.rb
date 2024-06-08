$LOAD_PATH.unshift(File.expand_path(File.join(__dir__, "../../lib")))

require "affidavit"
require "date"

include Affidavit::Builder

# Scenario
#
# We run a restaurant where customers are charged a flat fee. Here are the
# rules for pricing:
#
#  - Charge each person $10 per day that they visited the cafeteria
#  - If the person has a coupon, charge them $5
#  - If it's the person's birthday, charge them $1
#
# We charge each customer at the end of the week based on how often they
# visited. For this example, let's assume everyone is always in the same
# group.
#
# Each visitor gets a bill that shows the total bill for the whole group
# as well as their own portion of it.

Visitor = Struct.new(
  :id,
  :days_visited,
  :birthday,
  :days_with_coupon,
  keyword_init: true
)

# Calculator one does not use Affidavit
class CalculatorOne
  def calculate(visitors)
    date_range = (Date.new(2020, 3, 1)..Date.new(2020, 3, 5))
    total = 0
    visitor_totals = Hash.new { |h, k| h[k] = 0 }

    date_range.each { |date|
      visitors.each do |visitor|
        price = price_for(visitor, date)

        total += price
        visitor_totals[visitor.id] += price
      end
    }

    { total: total, visitor_totals: visitor_totals }
  end

  private

  def price_for(visitor, date)
    if visitor.days_visited.include?(date)
      if visitor.birthday == date
        1
      elsif visitor.days_with_coupon.include?(date)
        5
      else
        10
      end
    else
      0
    end
  end
end

# Calculator two uses Affidavit
class CalculatorTwo
  include Affidavit::Builder

  def calculate(visitors)
    date_range = (Date.new(2020, 3, 1)..Date.new(2020, 3, 5))
    total = 0
    visitor_totals = Hash.new { |h, k| h[k] = x(0) }

    date_range.each { |date|
      visitors.map do |visitor|
        price = price_for(visitor, date)

        # The total is calculated from the visitor totals so we don't really
        # need to use Affidavit here since it would contain no information
        # beyond what the visitor price expressions hold.
        total += price.value

        # Here we want to capture everything. Note: Refactoring the code to
        # use `sum` would result in a cleaner affidavit, but it's left as-is
        # in order to mirror the other computation.
        visitor_totals[visitor.id] = (
          visitor_totals[visitor.id]
            .x(:+, price)
        )
      end
    }

    x({ total: total, visitor_totals: visitor_totals })
  end

  private

  def price_for(visitor, date)
    # Importantly, the expressions in the conditional are not
    # evaluated unless they need to be.
    price_for_date = cond(
      x(visitor, :birthday).x(:==, date) => 1,
      x(visitor, :days_with_coupon).x(:include?, date) => 5,
      true => 10 # the "else" clause
    )

    cond(
      x(visitor, :days_visited).x(:include?, date) => price_for_date,
      true => 0, # the "else" clause
      metadata: { label: "daily_price", visitor: visitor }
    )
  end
end

def visitors
  [
    Visitor.new(
      id: "id_1",
      days_visited: [
        Date.new(2020, 3, 1),
        Date.new(2020, 3, 2),
        Date.new(2020, 3, 3),
        Date.new(2020, 3, 4),
        Date.new(2020, 3, 5),
      ],
      birthday: Date.new(2020, 3, 3),
      days_with_coupon: [
        Date.new(2020, 3, 2),
        Date.new(2020, 3, 5)
      ]
    ),
    Visitor.new(
      id: "id_2",
      days_visited: [
        Date.new(2020, 3, 1),
        Date.new(2020, 3, 2),
      ],
      birthday: Date.new(2020, 3, 7),
      days_with_coupon: []
    ),
    Visitor.new(
      id: "id_3",
      days_visited: [
        Date.new(2020, 3, 2),
        Date.new(2020, 3, 3),
        Date.new(2020, 3, 4),
        Date.new(2020, 3, 5),
      ],
      birthday: Date.new(2020, 3, 4),
      days_with_coupon: [Date.new(2020, 3, 2)]
    )
  ]
end

calc_1_result = CalculatorOne.new.calculate(visitors)
puts "First calculation:\n#{calc_1_result.inspect}"
#=> { total: 77, visitor_totals: { "id_1" => 31, "id_2" => 20, "id_3" => 26 } },

expression = CalculatorTwo.new.calculate(visitors)

# confirm we get the same result
puts "---"
puts "Second calculation:\n#{expression.value.inspect}"
#=> { total: 77, visitor_totals: { "id_1" => 31, "id_2" => 20, "id_3" => 26 } },

# We have to tell Affidavit how to serialize our `Visitor` class:
Affidavit.configure do |config|
  config.serialize(Visitor) do |data, serializer|
    { "class" => "Visitor", "id" => data.id }
  end
end

# Now let's serialize this as though we stored it to our database
serialized_affidavit = expression.serialize

# Now it's a week later and we're asked to provide more info:
explorer = Affidavit::Explorer.new(serialized_affidavit)
daily_prices = explorer.select { |node|
  node.dig("metadata", "label") == "daily_price" && \
    node.dig("metadata", "visitor", "id") == "id_1"
}

puts "---"
puts "Visitor id_1's daily bills:"
puts daily_prices.map { _1.fetch("value") }.inspect
#=>  [5, 10, 1, 5, 10]


# The customer claims that the $10 charged on the second day
# is an incorrect computation because they had a coupon. We
# can review the information that the system knew at the time:
#
# We haven't attached any metadata to this particular piece of
# information. By poking around the raw data, we can see this
# conditional evaluated to `false`. We can see that the day
# in question ("2020-03-04") is not included in the list of
# "days_with_coupon" (["2020-03-02", "2020-03-05"])

puts "---"
pp(
  daily_prices[1]
  .dig("source", "consequent", "source", "conditionals")[1]
)
:ok
