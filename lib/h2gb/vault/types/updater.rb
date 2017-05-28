# encoding: ASCII-8BIT
##
# updater.rb
# By Ron Bowes
# Created May, 2017
#
# See LICENSE.md
##

require 'h2gb/vault/error'
require 'h2gb/vault/types/basic_types'
require 'h2gb/vault/workspace'

module H2gb
  module Vault
    class Updater
      include BasicTypes

      def initialize(workspace:)
        @workspace = workspace
      end

      private
      def _sanity_check(block_name:, address:, length:)
        if address < 0
          raise(Error, "address must be positive")
        end
        if address + length > @workspace.raw(block_name: block_name).length
          raise(Error, "definition would go outside of workspace")
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
        if item['block_name']
          item[:block_name] = item['block_name']
        end
        if item[:block_name].nil?
          raise Error("block_name is required!")
        end
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
          _define_basic_type(block_name: item[:block_name], item: item)

          # Apply a comment if one exists
          if item[:comment]
            @workspace.set_comment(block_name: item[:block_name], address: item[:address], comment: item[:comment])
          end

          # Apply user-defined if it exists
          if item[:user_defined]
            @workspace.replace_user_defined(block_name: item[:block_name], address: item[:address], user_defined: item[:user_defined])
          end
        when :define_custom_type
          @workspace.define(block_name: item[:block_name], address: item[:address], type: item[:type], value: item[:value], length: item[:length], refs: item[:refs] || {}, user_defined: item[:user_defined] || {}, comment: item[:comment])
        when :undefine
          @workspace.undefine(block_name: item[:block_name], address: item[:address], length: item[:length])
        when :set_comment
          @workspace.set_comment(block_name: item[:block_name], address: item[:address], comment: item[:comment])
        when :replace_user_defined
          @workspace.replace_user_defined(block_name: item[:block_name], address: item[:address], user_defined: item[:user_defined])
        when :update_user_defined
          @workspace.update_user_defined(block_name: item[:block_name], address: item[:address], user_defined: item[:user_defined])
        when :add_refs
          @workspace.add_refs(block_name: item[:block_name], type: item[:type], from: item[:address], tos: item[:tos])
        when :remove_refs
          @workspace.remove_refs(block_name: item[:block_name], type: item[:type], from: item[:address], tos: item[:tos])
        else
          raise Error("Unknown action: %s" % item[:action])
        end
      end

      public
      def do(definition)
        if !definition.is_a?(Array)
          raise Error("definition must be an Array!")
        end

        @workspace.transaction() do
          definition.each() do |item|
            _do_item(item: item)
          end
        end
      end
    end
  end
end
