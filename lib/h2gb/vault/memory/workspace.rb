##
# memory.rb
# Created April, 2017
# By Ron Bowes
#
# See: LICENSE.md
#
# Represents an abstraction of a process's memory, including addresses,
# references, cross-references, undo/redo, save/load, and more!
##

require 'yaml'

require 'h2gb/vault/error'
require 'h2gb/vault/memory/memory_block'
require 'h2gb/vault/memory/memory_entry'
require 'h2gb/vault/memory/memory_refs'
require 'h2gb/vault/memory/memory_transaction'

module H2gb
  module Vault
    class Memory
      class Workspace
        attr_reader :transactions, :memory_block

        ENTRY_DEFINE = :define
        ENTRY_UNDEFINE = :undefine

        UPDATE_USER_DEFINED_FORWARD = :update_user_defined_forward
        UPDATE_USER_DEFINED_BACKWARD = :update_user_defined_backward

        SET_COMMENT_FORWARD = :set_comment_forward
        SET_COMMENT_BACKWARD = :set_comment_backward

        ADD_REFS = :add_refs
        REMOVE_REFS = :remove_refs

        public
        def initialize(name:nil, raw:, base_address:0)
          # Create an initial memory_block
          # TODO: This is for compatibility, I'm going to get rid ofi t
          @memory_blocks[name] = MemoryBlock.new(
            name: name,
            raw: raw,
            base_address: base_address,
          )

          @transactions = MemoryTransaction.new(opposites: {
            ENTRY_DEFINE => ENTRY_UNDEFINE,
            ENTRY_UNDEFINE => ENTRY_DEFINE,

            UPDATE_USER_DEFINED_FORWARD => UPDATE_USER_DEFINED_BACKWARD,
            UPDATE_USER_DEFINED_BACKWARD => UPDATE_USER_DEFINED_FORWARD,

            SET_COMMENT_FORWARD => SET_COMMENT_BACKWARD,
            SET_COMMENT_BACKWARD => SET_COMMENT_FORWARD,

            ADD_REFS => REMOVE_REFS,
            REMOVE_REFS => ADD_REFS,
          })
          @in_transaction = false

          @refs = {}

          @mutex = Mutex.new()
        end

        public
        def create(name:nil, base_address:0, raw:)
        end

        public
        def raw(name:nil)
          return @memory_block[name].raw
        end

        public
        def transaction()
          @mutex.synchronize() do
            @in_transaction = true

            @transactions.increment()
            yield

            # TODO: Catch errors properly so we don't wind up in a bad state here

            @in_transaction = false
          end
        end

        private
        def _define_internal(entry:, name:)
          @memory_blocks[name].each_entry_in_range(address: entry.address, length: entry.length, include_undefined: false) do |this_address, this_entry, raw, refs, xrefs|
            # Remove refs from the address
            refs.each_pair do |type, tos|
              _remove_refs_internal(type: type, from: this_address, tos: tos)
            end

            # Remove any entry
            _undefine_internal(entry: this_entry)
          end

          @memory_blocks[name].define(entry: entry, revision: @transactions.revision)

          @transactions.add_to_current_transaction(type: ENTRY_DEFINE, entry: entry)
        end

        private
        def _undefine_internal(entry:, name:)
          @transactions.add_to_current_transaction(type: ENTRY_UNDEFINE, entry: entry)
          @memory_blocks[name].undefine(entry: entry, revision: @transactions.revision)
        end

        private
        def _update_user_defined_internal(entry:, new_user_defined:, name:)
          @transactions.add_to_current_transaction(type: UPDATE_USER_DEFINED_FORWARD, entry: {
            entry: entry,
            old_user_defined: entry.user_defined.clone(),
            new_user_defined: new_user_defined.clone(),
          })
          @memory_blocks[name].update_user_defined(entry: entry, user_defined: new_user_defined, revision: @transactions.revision)
        end

        private
        def _set_comment_internal(entry:, new_comment:, name:)
          @transactions.add_to_current_transaction(type: SET_COMMENT_FORWARD, entry: {
            entry: entry,
            old_comment: entry.comment,
            new_comment: new_comment,
          })
          @memory_blocks[name].set_comment(entry: entry, comment: new_comment, revision: @transactions.revision)
        end

        private
        def _add_refs_internal(type:, from:, tos:, name:)
          @transactions.add_to_current_transaction(type: ADD_REFS, entry: {
            type: type,
            from: from,
            tos:  tos,
          })
          @memory_blocks[name].add_refs(type: type, from: from, tos: tos, revision: @transactions.revision)
        end

        private
        def _remove_refs_internal(type:, from:, tos:, name:)
          @transactions.add_to_current_transaction(type: REMOVE_REFS, entry: {
            type: type,
            from: from,
            tos:  tos,
          })
          @memory_blocks[name].remove_refs(type: type, from: from, tos: tos, revision: @transactions.revision)
        end

        private
        def _apply(action:, entry:)
          if action == ENTRY_DEFINE
            _define_internal(entry: entry)
          elsif action == ENTRY_UNDEFINE
            _undefine_internal(entry: entry)
          elsif action == UPDATE_USER_DEFINED_FORWARD
            _update_user_defined_internal(entry: entry[:entry], new_user_defined: entry[:new_user_defined])
          elsif action == UPDATE_USER_DEFINED_BACKWARD
            _update_user_defined_internal(entry: entry[:entry], new_user_defined: entry[:old_user_defined])
          elsif action == SET_COMMENT_FORWARD
            _set_comment_internal(entry: entry[:entry], new_comment: entry[:new_comment])
          elsif action == SET_COMMENT_BACKWARD
            _set_comment_internal(entry: entry[:entry], new_comment: entry[:old_comment])
          elsif action == ADD_REFS
            _add_refs_internal(type: entry[:type], from: entry[:from], tos: entry[:tos])
          elsif action == REMOVE_REFS
            _remove_refs_internal(type: entry[:type], from: entry[:from], tos: entry[:tos])
          else
            raise(Error, "Unknown revision action: %s" % action)
          end
        end

        public
        def define(address:, type:, value:, length:, refs:{}, user_defined:{}, comment:nil)
          if !@in_transaction
            raise(Error, "Calls to define() must be wrapped in a transaction!")
          end
          if !refs.is_a?(Hash)
            raise(Error, "refs must be a Hash!")
          end
          refs.each_pair do |ref_type, tos|
            if !ref_type.is_a?(String) && !ref_type.is_a?(Symbol)
              raise(Error, "refs' keys must be either strings or symbols")
            end
            if !tos.is_a?(Array)
              raise(Error, "refs' values must be arrays")
            end
            tos.each do |ref|
              if !ref.is_a?(Integer)
                raise(Error, "refs' values must be arrays of integers")
              end
            end
          end

          entry = MemoryEntry.new(address: address, type: type, value: value, length: length, user_defined: user_defined, comment: comment)
          _define_internal(entry: entry)
          refs.each_pair do |ref_type, tos|
            _add_refs_internal(type: ref_type, from: address, tos: tos)
          end
        end

        public
        def undefine(address:, length:1, name:nil)
          if not @in_transaction
            raise(Error, "Calls to undefine() must be wrapped in a transaction!")
          end

          @m, name:emory_block.each_entry_in_range(address: address, length: length) do |this_address, entry, raw, refs, xrefs|
            refs.each_pair do |type, tos|
              _remove_refs_internal(type: type, from: this_address, tos: tos)
            end
            _undefine_internal(entry: entry)
          end
        end

        public
        def get_user_defined(address:, name:nil)
          entry = @memory_blocks.get(address: address)
          if entry.nil?
            return {}
          end

          return entry.user_defined
        end

        public
        def replace_user_defined(address:, user_defined:, name:nil)
          if not @in_transaction
            raise(Error, "Calls to replace_user_defined() must be wrapped in a transaction!")
          end

          entry, _ = @memory_blocks[name].get(address: address, define_by_default: false)

          # Automatically define the entry if it doesn't exist
          if entry.nil?
            entry = MemoryEntry.default(address: address, raw: @memory_blocks[name].raw[address].ord())
            _define_internal(entry: entry)
          end

          _update_user_defined_internal(entry: entry, new_user_defined: user_defined)
        end

        public
        def _get_or_define_entry(address:, name:)
          entry, _ = @memory_blocks[name].get(address: address, define_by_default: false)

          # Automatically define the entry if it doesn't exist
          if entry.nil?
            entry = MemoryEntry.default(address: address, raw: @memory_blocks[name].raw[address].ord())
            _define_internal(entry: entry)
          end

          return entry
        end

        public
        def update_user_defined(address:, user_defined:)
          if not @in_transaction
            raise(Error, "Calls to update_user_defined() must be wrapped in a transaction!")
          end

          entry = _get_or_define_entry(address: address)
          _update_user_defined_internal(entry: entry, new_user_defined: entry.user_defined.merge(user_defined))
        end

        public
        def set_comment(address:, comment:)
          if not @in_transaction
            raise(Error, "Calls to set_comment() must be wrapped in a transaction!")
          end

          entry = _get_or_define_entry(address: address)
          _set_comment_internal(entry: entry, new_comment: comment)
        end

        public
        def add_refs(type:, from:, tos:)
          if not @in_transaction
            raise(Error, "Calls to set_comment() must be wrapped in a transaction!")
          end

          _get_or_define_entry(address: from)
          _add_refs_internal(type: type, from: from, tos: tos)
        end

        public
        def remove_refs(type:, from:, tos:)
          if not @in_transaction
            raise(Error, "Calls to set_comment() must be wrapped in a transaction!")
          end

          _get_or_define_entry(address: from)
          _remove_refs_internal(type: type, from: from, tos: tos)
        end

        public
        def get(address:, length: 1, since: -1, name: nil)
          @mutex.synchronize() do
            result = {
              revision: @transactions.revision,
              entries: [],
            }

            @memory_blocks[name].each_entry_in_range(address: address, length: length, since: since) do |this_address, entry, raw, refs, xrefs|

              result[:entries] << {
                address:      this_address,
                type:         entry.type,
                value:        entry.value,
                length:       entry.length,
                user_defined: entry.user_defined,
                comment:      entry.comment,
                raw:          raw,
                refs:         refs,
                xrefs:        xrefs,
              }
            end

            return result
          end
        end

        public
        def get_single(address:)
          return get(address: address, length: 1, since: -1)[:entries].pop()
        end

        public
        def get_value(address:)
          return get_single(address: address)[:value]
        end

        public
        def [](address)
          return get_single(address: address)
        end

        public
        def get_all(name:nil)
          return get(address: 0, length: @memory_blocks[name].raw.length, since: -1)
        end

        public
        def undo()
          @mutex.synchronize() do
            @transactions.undo_transaction() do |action, entry|
              _apply(action: action, entry: entry)
            end
          end
        end

        public
        def redo()
          @mutex.synchronize() do
            @transactions.redo_transaction() do |action, entry|
              _apply(action: action, entry: entry)
            end
          end
        end

        public
        def to_s(name:nil)
          return [
            "Revision: %d" % @transactions.revision,
            "--",
            "%s" % [@memory_block.to_s()],
          ].join("\n")
        end

        public
        def dump()
          @mutex.synchronize() do
            return YAML::dump(self)
          end
        end

        public
        def self.load(str)
          memory = YAML::load(str)

          if memory.class != Workspace
            raise(Error, "Couldn't load the file")
          end

          return memory
        end
      end
    end
  end
end
