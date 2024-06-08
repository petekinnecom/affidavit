# frozen_string_literal: true

module Affidavit
  module Types
    SOURCE_ATTRIBUTES = {
      "affidavit.expression" => [
        "receiver",
        "operation",
        "args"
      ],
      "affidavit.conditional" => [
        "conditionals",
        "consequent"
      ],
    }
    NODE_TYPES = SOURCE_ATTRIBUTES.keys

    T = self

    def self.reify(obj, lazy: false)
      enumerator = lazy ? :lazy : :itself

      if obj.is_a?(Array)
        obj.send(enumerator).map { reify(_1) }
      elsif obj.is_a?(Hash)
        obj.send(enumerator).map { [reify(_1), reify(_2)] }.to_h
      elsif obj.is_a?(Types::Base)
        obj.value
      else
        obj
      end
    end

    class Base
      def x(...)
        Builder.exp(self, ...)
      end

      def serialize
        Serializer
          .new(Affidavit.config.serializers)
          .call(self)
      end
    end

    class Expression < Base
      def initialize(receiver, operation = nil, *args, metadata: {})
        @args = args
        @metadata = metadata
        @operation = operation
        @receiver = receiver
      end

      def value
        return @value if defined?(@value)

        @value = (
          if @operation
            T.reify(@receiver).public_send(T.reify(@operation), *@args.map { T.reify(_1) })
          else
            T.reify(@receiver)
          end
        )
      end

      def affidavit
        {
          type: "affidavit.expression",
          value: value,
          source: {
            receiver: @receiver,
            operation: @operation,
            args: @args
          },
          metadata: @metadata,
        }
      end
    end

    class LazyExpression < Expression
      def value
        return @value if defined?(@value)

        @inspected = []
        @value = T.reify(@receiver).public_send(T.reify(@operation), *T.reify(@args)) { |c|
          @inspected << c
          T.reify(c).value
        }

        @value
      end

      def affidavit
        {
          type: "affidavit.expression",
          value: value,
          source: {
            receiver: @receiver,
            operation: @operation,
            args: @args
          },
          metadata: @metadata,
        }
      end
    end

    class Conditional < Base
      def initialize(conditions)
        @conditions = conditions
        @metadata = conditions.fetch(:metadata, {})
      end

      def value
        return @value if defined?(@value)

        @inspected = []
        @consequent = nil
        @value = (
          @conditions
            .find { |condition, _|
              next if condition == :metadata

              @inspected << condition
              T.reify(condition)
            }
            .last
            .then {
              @consequent = _1
              T.reify(_1)
            }
        )
      end

      def affidavit
        {
          type: "affidavit.conditional",
          value: value,
          source: {
            conditionals: @inspected,
            consequent: @consequent,
          },
          metadata: @metadata,
        }
      end
    end
  end
end
