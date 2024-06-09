$LOAD_PATH.unshift(File.expand_path(File.join(__dir__, "../../lib")))

require "affidavit"

include Affidavit::Builder

gl_account_ordering_by_name = x([
  :security_deposit,
  :rent,
  :pet_fees,
  :parking
])

GlAccount = Struct.new(:name)

Txn = Struct.new(:gl_account, :total, :amount_paid) do
  def initialize(gl_account, total, amount_paid)
    super(
      gl_account,
      x(total, metadata: { label: "total"}),
      x(amount_paid, metadata: { label: "amount_paid"} )
    )
  end


  def amount_due
    total.x(:-, amount_paid)
  end

  def fully_paid?
    total.x(:==, amount_paid)
  end
end

gl_accounts = [
  :security_deposit,
  :rent,
  :pet_fees,
  :parking,
  :late_fees,
  :other,
  :alien_abduction_fee
].map { [_1, GlAccount.new(_1)] }.to_h

txns = [
  { gl: :pet_fees, total: 50, amount_paid: 20 },
  { gl: :rent, total: 1000, amount_paid: 999 },
  { gl: :parking, total: 20, amount_paid: 20 },
  { gl: :rent, total: 100, amount_paid: 20 },
  { gl: :other, total: 100, amount_paid: 0 },
].map { |opts|
  Txn.new(
    gl_accounts.fetch(opts.fetch(:gl)),
    opts.fetch(:total),
    opts.fetch(:amount_paid),
  )
}

receipt_amount = x(1320, metadata: { label: "receipt_amount"})

amount_left_to_pay = receipt_amount

txns.sort_by

while (amount_left_to_pay.value > 0) do

end
