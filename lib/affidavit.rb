# frozen_string_literal: true

require_relative "affidavit/version"
require_relative "affidavit/types"
require_relative "affidavit/builder"
require_relative "affidavit/serializer"
require_relative "affidavit/explorer"
require_relative "affidavit/presenter"

module Affidavit
  class Error < StandardError; end

  class Configuration
    attr_accessor :serializers

    def initialize
      @serializers = Serializer::DEFAULT
    end

    def serialize(klass_or_name, callable = nil, &block)
      klass_name = (
        if klass_or_name.is_a?(Class)
          klass_or_name.name
        else
          klass_or_name
        end
      )

      serializers[klass_name] = callable || block
    end
  end

  class << self
    def config
      @config ||= Configuration.new
    end

    def configure
      yield config
    end
  end
end
