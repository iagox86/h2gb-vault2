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
      def _validate_address(address:)
        if !address.is_a?(Integer) || address < 0
          raise MemoryError("address must be a positive integer")
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

        # Do the action
        case item[:action]
        when :define_basic_type
          _validate_address(address: item[:address])

          _define_basic_type(item: item)

          # Apply a comment if one exists
          if item[:comment]
            @memory.set_comment(address: item[:address], comment: item[:comment])
          end

          # Apply user-defined if it exists
          if item[:user_defined]
            @memory.replace_user_defined(address: item[:address], user_defined: item[:user_defined])
          end
        when :set_comment
          _validate_address(address: item[:address])
          @memory.set_comment(address: item[:address], comment: item[:comment])
          _validate_address(address: item[:address])
        when :add_refs
          _validate_address(address: item[:address])
          @memory.add_refs(type: item[:type], from: item[:address], tos: item[:tos])
        when :remove_refs
          _validate_address(address: item[:address])
          @memory.remove_refs(type: item[:type], from: item[:address], tos: item[:tos])
        when :undefine
          _validate_address(address: item[:address])
          @memory.undefine(address: item[:address], length: item[:length])
        else
          # TODO: This raise isn't working, but I plan to move MemoryError anyways
          raise H2gb::Vault::Memory::MemoryError("Unknown action: %s" % item[:action])
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
