# frozen_string_literal: true

module Affidavit
  class Explorer
    include Enumerable
    SOURCE_ATTRS = Types::SOURCE_ATTRIBUTES
    TYPES = Types::NODE_TYPES
    Key = Struct.new(:index) do
      def to_s
        "KEY[#{index}]"
      end
    end

    class Node
      include Enumerable

      attr_reader :affidavit, :path_array
      def initialize(affidavit, path_array, explorer)
        @affidavit = affidavit
        @path_array = path_array
        @explorer = explorer
      end

      def each(&)
        @iterables ||= @explorer.select { |n| n.path.start_with?(path) }
        @iterables.each(&)
      end

      def path
        @path ||= path_array.join(".")
      end

      def inspect(...)
        "<Affidavit::Explorer::Node @affidavit=#{affidavit}>"
      end
    end

    attr_reader :affidavit, :parent_path
    def initialize(affidavit, parent_path = [])
      @affidavit = affidavit
      @parent_path = parent_path
    end

    def each
      iterables.each do |node|
        yield(node)
      end
    end

    private

    def iterables
      @iterables ||= (
        nodes.lazy.map { |path|
          if path == "."
            Node.new(affidavit, parent_path + ["."], self)
          else
            Node.new(dig(path), parent_path + path, self)
          end
        }
      )
    end

    def nodes
      @nodes ||= (
        # to avoid a billion nested calls, we flatten the stack
        queue = []
        nodes = []

        queue += SOURCE_ATTRS[affidavit["type"]].map { ["source", _1] }
        nodes += ["."]

        until(queue.empty?) do
          path = queue.shift
          value = dig(path)
          if value.is_a?(Array)
            queue += value.each_with_index.map { path + [_2] }
          elsif value.is_a?(Hash) && SOURCE_ATTRS.key?(value["type"])
            queue += SOURCE_ATTRS[value["type"]].map { path + ["source", _1] }
            nodes << path
          elsif value.is_a?(Hash)
            queue += value.keys.each_with_index.map { path + [Key.new(_2)] }
            queue += value.keys.map { path + [_1] }
          end
        end
        nodes
      )
    end

    def dig(path)
      value = affidavit
      path.each do |next_key|
        if next_key.is_a?(Key)
          value = value.keys[next_key.index]
        else
          value = value[next_key]
        end
      end
      value
    end
  end
end
