# frozen_string_literal: true

module Affidavit
  class Presenter
    attr_reader :affidavit
    def initialize(affidavit)
      @affidavit = affidavit
    end

    def call
      normalized = normalize(affidavit)


    end

    def normalize(data)
      if data.nil?
        nil
      elsif data.is_a?(Array)
        data.map { normalize(_1) }
      elsif data.is_a?(Hash) && data["type"] == "affidavit.expression"
        value = data.fetch("value")
        receiver = normalize(data.dig("source", "receiver"))
        operation = normalize(data.dig("source", "operation"))
        args = normalize(data.dig("source", "args"))

        if args.any?
          { exp: [receiver, operation, args], value: value }
        elsif operation
          { exp: [receiver, operation], value: value }
        elsif data.dig("source", "receiver") == value
          value
        else
          load '~/pry.rb'; binding.pry
          { exp: [receiver], value: value }
        end
      else
        data.to_s
      end
    end

    def deroll(data, push=0)
      unpushed = (
        if data.nil?
          ""
        elsif data.is_a?(Array)
          data.map { deroll(_1) }.join(", ")
        elsif data.is_a?(Hash) && data["type"] == "affidavit.expression"
          value = data.fetch("value")
          receiver = deroll(data.dig("source", "receiver"))
          operation = deroll(data.dig("source", "operation"))
          args = deroll(data.dig("source", "args"))

          if data.dig("source", "args")&.count&.> 0
            "#{receiver}.#{operation}(#{args}) -> #{value}\n#{value}"
          elsif data.dig("source", "operation")
            "#{receiver}.#{operation}() -> #{value}\n#{value}"
          else
            "#{receiver} -> #{value}\n#{value}"
          end
        elsif data.is_a?(Hash) && data["type"] == "affidavit.conditional"
          value = data.fetch("value")
          conditionals = data.dig("source", "conditionals").map { deroll(_1, push + 1) }
          consequent = deroll(data.dig("source", "consequent"), push + 1)

          [conditionals.map { |c| "\nif (\n#{c})" }.join(", "), "-> #{consequent}\n#{value}"].join(" ")
        elsif data.is_a?(Hash)
          data
            .map { |k, v|
              if k.is_a?(String) && v.is_a?(String)
                "#{k}: #{v}"
              elsif (k.is_a?(Hash) && k.dig("type")&.match(/affidavit/)) || (v.is_a?(Hash) && v&.dig("type")&.match(/affidavit/))
                key = (
                  if k.is_a?(Hash)
                    "(#{deroll(k, push +1 )})"
                  else
                    k.to_s
                  end
                )
                value = (
                  if v.is_a?(Hash)
                    "(#{deroll(v, push +1 )})"
                  else
                    v.to_s
                  end
                )

                <<~STR
                  key: #{key}
                  value: #{value}
                STR
              else
                "#{deroll(k)}: #{deroll(v)}"
              end
          }
          .then {
            if _1.any? { |r| r.match(/\n/) }
              "{\n#{_1.join(",\n")}\n}"
            else
              "{ #{_1.join(", ")} }"
            end
          }
        else
          data.to_s
        end
      )

      unpushed.gsub(/^/, " "*push*2)
    end
  end
end
