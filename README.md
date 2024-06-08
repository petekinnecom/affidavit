# Affidavit

Build artifacts that compute and justify your app's business logic.

### "Huh? What?" -you (probably)

We programmers tend to write code with the sole aim of computing a certain result and storing it in the database (or presenting it or whatever). In the event that someone asks us how a specific result was achieved, we poke around in the database, trying to reconstruct the data at the time the result was computed. We then look at the code and read through it until we can come to a satisfactory explanation. (Oops, don't forget to check-out the correct version of the code that was deployed at the time the result was computed!)

This gem helps you write code that both computes the result *and* creates a data-structure that explicitly tells you how that result was achieved.

### Example!

A customer buys five $1 apple, one $10 banana. How much do they owe you?


Maybe you'd code up something like this:

```ruby

# Somewhere deep in the bowels of your system's code:
PRICES = {
  apple: 1,
  banana: 10
}

num_apples = 5
num_bananas = 1

amount_due = [
  num_apples * PRICES[:apple],
  num_bananas * PRICES[:banana]
].sum

Database.save(receipt_id: "1", amount_due: amount_due)
```

The data produced here is limited to the number `15`.

With Affidavit it could look like this:

```ruby
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

Database.save(
  receipt_id: "1",
  amount_due: amount_due.value,
  affidavit: amount_due.serialize
)
```

*Ugh*, you might think to yourself, *looks painful.* And if your only goal is to compute the result, then yes, coding this way would be silly. However, if you want to be able to understand your system's computations after-the-fact, then this is a small price to pay for a giant pile of auditable data.

Let's explore what data it provides:

```ruby
explorer = Affidavit::Explorer.new(serialized_affidavit)

prices = (
  explorer
    .filter_map { |node|
      next unless node.affidavit.dig("metadata", "label") == "price"

      [node.affidavit.dig("metadata", "fruit"), node.affidavit.dig("value")]
    }
    .to_h
)

quantities = (
  explorer
    .filter_map { |node|
      next unless node.affidavit.dig("metadata", "label") == "quantity"

      [node.affidavit.dig("metadata", "fruit"), node.affidavit.dig("value")]
    }
    .to_h
)

puts "prices: #{prices.inspect}"
puts "quantities: #{quantities.inspect}"

# prices: {"apple"=>1, "banana"=>10}
# quantities: {"apple"=>5, "banana"=>1}

# There's plenty more data in there:
puts amount_due.serialize
```

# Are you not entertained?

...more to come...
