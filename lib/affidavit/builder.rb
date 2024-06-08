# frozen_string_literal: true

module Affidavit
  module Builder
    extend self

    def x(...)
      exp(...)
    end

    def cond(...)
      Types::Conditional.new(...)
    end

    def exp(receiver, operation = nil, *args, metadata: {})
      Types::Expression.new(
        receiver,
        operation,
        *args,
        metadata: metadata
      )
    end
  end
end
