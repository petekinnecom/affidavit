# frozen_string_literal: true

module Affidavit
  class Serializer
    DEFAULT = {
      "Object" => ->(data, serializer) { {class: data.class.name, object_id: data.object_id } },
      "String" => ->(data, serializer) { data },
      "Array" => -> (data, serializer) { data.map { |o| serializer.(o) } },
      "Date" => -> (data, serializer) { data.iso8601 },
      "Time" => -> (data, serializer) { data.iso8601 },
      "DateTime" => -> (data, serializer) { data.iso8601 },
      "Hash" => -> (data, serializer) {
        data.map { |k, v| [serializer.(k), serializer.(v) ] }.to_h
      },
      "Numeric" => -> (data, serializer) { data },
      "BigDecimal" => -> (data, serializer) { data.to_digits },
      "Symbol" => -> (data, serializer) { data.to_s },
      "TrueClass" => -> (data, serializer) { data },
      "FalseClass" => -> (data, serializer) { data },
      "NilClass" => ->(*) {},
      "Affidavit::Types::Base" => -> (data, serializer) { serializer.(data.affidavit) }
    }

    attr_reader :serializers
    def initialize(serializers = DEFAULT)
      @serializers = serializers
      @class_serializers = {}
      @memoized = {}
    end

    def call(data)
      @memoized[data.object_id] ||= (
        serializer_for(data.class).(data, self)
      )
    end

    private

    def serializer_for(klass)
      @class_serializers[klass] ||= (
        serializer = nil
        klass.ancestors.each {
          serializer = serializers[_1.name]
          break unless serializer.nil?
        }
        serializer
      )
    end
  end
end
