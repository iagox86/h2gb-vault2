##
# updater.rb
# By Ron Bowes
# Created May, 2017
#
# See LICENSE.md
##

require 'h2gb/vault/error'
require 'h2gb/vault/memory/memory'
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
          raise(Error, "address must be positive")
        end
        if address + length > @memory.raw.length
          raise(Error, "definition would go outside of memory")
        end
      end

      private
      def _validate_address(address:)
        if !address.is_a?(Integer) || address < 0
          raise Error("address must be a positive integer")
        end
      end

      private
      def _do_item(item:)
        puts(item.to_s)
        if item['action']
          item[:action] = item['action'] # TODO: Use strings by default (or find another way)
        end
        if item['address']
          item[:address] = item['address']
        end
        if item['type']
          item[:type] = item['type'].to_sym
        end

        if item[:action].is_a?(String)
          item[:action] = item[:action].to_sym()
        end
        if !item[:action].is_a?(Symbol)
          raise Error("action must be a String or Symbol")
        end
        _validate_address(address: item[:address])

        # Do the action
        case item[:action]
        when :define_basic_type
          _define_basic_type(item: item)

          # Apply a comment if one exists
          if item[:comment]
            @memory.set_comment(address: item[:address], comment: item[:comment])
          end

          # Apply user-defined if it exists
          if item[:user_defined]
            @memory.replace_user_defined(address: item[:address], user_defined: item[:user_defined])
          end
        when :define_custom_type
          @memory.define(address: item[:address], type: item[:type], value: item[:value], length: item[:length], refs: item[:refs] || {}, user_defined: item[:user_defined] || {}, comment: item[:comment])
        when :undefine
          @memory.undefine(address: item[:address], length: item[:length])
        when :set_comment
          @memory.set_comment(address: item[:address], comment: item[:comment])
        when :replace_user_defined
          @memory.replace_user_defined(address: item[:address], user_defined: item[:user_defined])
        when :update_user_defined
          @memory.update_user_defined(address: item[:address], user_defined: item[:user_defined])
        when :add_refs
          @memory.add_refs(type: item[:type], from: item[:address], tos: item[:tos])
        when :remove_refs
          @memory.remove_refs(type: item[:type], from: item[:address], tos: item[:tos])
        else
          raise Error("Unknown action: %s" % item[:action])
        end
      end

      public
      def do(definition)
        if !definition.is_a?(Array)
          raise Error("definition must be an Array!")
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
