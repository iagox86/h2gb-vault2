##
# updater.rb
# By Ron Bowes
# Created May, 2017
#
# See LICENSE.md
##

require 'h2gb/vault/memory/memory'
require 'h2gb/vault/memory/memory_error'
require 'h2gb/vault/types/basic_types'

module H2gb
  module Vault
    class Updater
      include BasicTypes

      def initialize(memory:)
        @memory = memory
      end

      private
      def _sanity_check(address:, length:)
        if address < 0
          raise(H2gb::Vault::Memory::MemoryError, "address must be positive")
        end
        if address + length > @memory.raw.length
          raise(H2gb::Vault::Memory::MemoryError, "definition would go outside of memory")
        end
      end

      private
      def _do_item(item:)
        if item[:action].is_a?(String)
          item[:action] = item[:action].to_sym()
        end
        if !item[:action].is_a?(Symbol)
          raise MemoryError("action must be a String or Symbol")
        end
        if !item[:address].is_a?(Integer) || item[:address] < 0
          raise MemoryError("address must be a positive integer")
        end

        case item[:action]
        when :define_basic_type
          _define_basic_type(item: item)
        else
          raise MemoryError("unknown action: %s" % item[:action])
        end
      end

      public
      def do(definition)
        if !definition.is_a?(Array)
          raise MemoryError("definition must be an Array!")
        end

        @memory.transaction() do
          definition.each() do |item|
            _do_item(item: item)
          end
        end
      end
    end
  end
end
