# frozen_string_literal: true

require "test_helper"

class PresenterTest < Minitest::Test
  include Affidavit::Builder

  def test_presents_without_conditionals
    val_1 = x(1, metadata: { label: "id_1"})
    val_2 = x(2, metadata: { label: "id_2"})

    ar_1 = x([1, 2, 3], metadata: { name: "ar_1"})
    ar_2 = x([4, 5, 6], metadata: { name: "ar_2"})


    result = x([val_1]).x(:+, ar_1).x(:+, [val_2]).x(:+, ar_2)
    pp Affidavit::Presenter.new(result.serialize).call
  end


  def test_presents_with_conditionals
    val_1 = x(1, metadata: { label: "id_1"})
    val_2 = x(2, metadata: { label: "id_2"})
    val_3 = x(3, metadata: { label: "id_3"})

    ar_1 = x([1, 2, 3], metadata: { name: "ar_1"})
    ar_2 = x([4, 5, 6], metadata: { name: "ar_2"})

    cond_2 = cond(
      x(ar_2).x(:[], 0).x(:==, 6) => val_1,
      x(ar_2).x(:[], 1).x(:==, 6) => val_2,
      x(ar_2).x(:[], 2).x(:==, 6) => val_3,
    )

    cond_1 = cond(
      x(ar_1, :include?, 4) => 1,
      x(ar_2, :include?, 4) => cond_2
    )

    result = x({label: "result", stuff: cond_1})

    puts Affidavit::Presenter.new(result.serialize).call
  end
end
