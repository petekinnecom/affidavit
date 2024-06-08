# frozen_string_literal: true

require "test_helper"

class AffidavitTest < Minitest::Test
  A = Affidavit::Builder
  include A

  Counter = Struct.new(:i) do
    def increment
      self.i += 1
      false
    end
  end

  def test_cond
    exp = A.cond(
      false => 1,
      true => 2,
    )
    assert_equal 2, exp.value

    exp = A.cond(
      x(false) => x(1),
      x(true) => x(2),
    )
    assert_equal 2, exp.value
  end

  def test_mixing_vals_and_primitives
    age = A.exp(1)
    years = 2

    assert_equal 3, A.exp(age, :+, years).value
    assert_equal 3, A.exp(years, :+, age).value
  end

  def test_mixing_vals_and_primitives_in_array
    ages = [A.x(1), 2, A.exp(1, :+, 2)]
    years = 2

    new_ages = ages.map { A.exp(_1, :+, years) }
    assert_equal [3, 4, 5], new_ages.map(&:value)

    new_ages_exp = A.exp(new_ages, :itself)
    assert_equal [3, 4, 5], new_ages_exp.value
  end

  def test_mixing_vals_and_primitives_in_hash
    ages = {
      a: 0,
      b: A.x(1),
      A.x(:c) => 2,
      A.x(:d) => A.exp(1, :+, 2)
    }
    years = 2

    new_ages = (
      ages
        .map { |k, v| [k, A.exp(v, :+, years)] }
        .to_h
        .then { A.x(_1) }
    )

    expected = { a: 2, b: 3, c: 4, d: 5 }
    assert_equal expected, new_ages.value
  end

  def test_chaining
    assert_equal 5, x(2).x(:+, 3).value
  end
end
