##
# memory_block.rb
# Created April, 2017
# By Ron Bowes
#
# See: LICENSE.md
#
# Represents a memory layout as a series of multi-byte entries with associated
# data.
##

require 'h2gb/vault/error'
require 'h2gb/vault/memory/memory_entry'
require 'h2gb/vault/memory/memory_refs'

module H2gb
  module Vault
    module Memory
      class MemoryBlock
        attr_reader :raw, :base_address, :name

        def initialize(raw:, base_address:, name:, revision:0)
          @raw = raw.force_encoding('ASCII-8BIT')
          @base_address = base_address
          @name = name
          @entries = {}
          @last_revision = -1
          @memory_refs = {}

          @raw.bytes().each_with_index() do |_, index|
            @entries[index] = {
              revision: revision,
              entry: nil,
            }
          end
        end

        private
        def _check_revision(revision:)
          # Make sure the revision can never decrement, or weird stuff will happen
          if revision < @last_revision
            raise(Error, "Tried to use a lower revision!")
          end
          @last_revision = revision
        end

        private
        def _poke_revision(address:, revision:)
          _check_revision(revision: revision)
          @entries[address] = @entries[address] || {}
          @entries[address][:revision] = revision
        end

        public
        def add_refs(type:, from:, tos:, revision:)
          _check_revision(revision: revision)

          # Make sure there's an entry (references have to be from an entry)
          if get(address: from, define_by_default: false).nil?
            raise(Error, "Trying to create a ref from an undefined address!")
          end

          # Create the refs type if it doesn't exist
          @memory_refs[type] = @memory_refs[type] || MemoryRefs.new(type: type)

          tos.each do |to|
            @memory_refs[type].insert(from: from, to: to)
            _poke_revision(revision: revision, address: to)
          end
          _poke_revision(revision: revision, address: from)
        end

        public
        def remove_refs(type:, from:, tos:, revision:)
          # TODO: I don't think I should allow 'tos' to be nil here
          _check_revision(revision: revision)

          # Make sure there's an entry (references have to be from an entry)
          if get(address: from, define_by_default: false).nil?
            raise(Error, "Trying to remove a ref from an undefined address!")
          end

          if @memory_refs[type].nil?
            raise(Error, "No such reference type %s on address 0x%x" % [type, from])
          end

          if tos.nil?
            tos = @memory_refs[type].delete_all(from: from)
          else
            tos.each() do |to|
              @memory_refs[type].delete(from: from, to: to)
            end
          end

          tos.each() do |to|
            _poke_revision(revision: revision, address: to)
          end
          _poke_revision(revision: revision, address: from)
        end

        public
        def get_refs(from:)
          result = {}
          @memory_refs.each_pair do |type, memory_refs|
            refs = memory_refs.get_refs(from: from)
            if refs.length > 0
              result[type] = refs
            end
          end

          return result
        end

        public
        def get_xrefs(to:)
          result = {}
          @memory_refs.each_pair do |type, memory_refs|
            xrefs = memory_refs.get_xrefs(to: to)
            if xrefs.length > 0
              result[type] = xrefs
            end
          end

          return result
        end

        public
        def define(entry:, revision:)
          _check_revision(revision: revision)

          # Validate before we start making changes
          entry.each_address() do |i|
            if @entries[i].nil?
              raise(Error, "Tried to define an entry that's out of range")
            end
            if @entries[i][:entry]
              raise(Error, "Tried to re-define an entry")
            end
          end

          # Define each address
          entry.each_address() do |i|
            @entries[i] = {
              revision: revision,
              entry: entry,
            }
          end
        end

        def undefine(entry:, revision:)
          _check_revision(revision: revision)

          # Validate before we start making changes
          entry.each_address() do |i|
            if @entries[i][:entry].nil?
              raise(Error, "Tried to clear memory that's not in use")
            end
          end

          entry.each_address() do |i|
            @entries[i] = {
              revision: revision,
              entry: nil,
            }
          end
        end

        def update_user_defined(entry:, user_defined:, revision:)
          entry.user_defined = user_defined
          _poke_revision(revision: revision, address: entry.address)
        end

        def set_comment(entry:, comment:, revision:)
          entry.comment = comment
          _poke_revision(revision: revision, address: entry.address)
        end

        def _get_raw(entry:)
          return @raw[entry.address, entry.length].bytes()
        end

        def _get_entry(address:, include_undefined: true)
          if @entries[address].nil?
            raise(Error, "Tried to retrieve an entry outside of the range")
          end
          entry = @entries[address][:entry]

          # Make sure that we always have an entry to work from
          if entry.nil?
            if !include_undefined
              return nil
            end

            entry = MemoryEntry.default(address: address, raw: @raw[address].ord())
          end

          return entry
        end

        def each_entry_in_range(address:, length:, since: 0, include_undefined: true)
          i = address

          while i < address + length
            entry = _get_entry(address: i, include_undefined: include_undefined)

            if entry.nil?
              i += 1
              next
            end

            revision = @entries[i][:revision]

            if revision > since
              yield(entry.address, entry, _get_raw(entry: entry), get_refs(from: entry.address), get_xrefs(to: entry.address))
            end

            i = entry.address + entry.length
          end
        end

        def each_entry(since: 0)
          each_entry_in_range(address: 0, length: @raw.length, since: since) do |address, entry, raw, refs, xrefs|
            yield(address, entry, raw, refs, xrefs)
          end
        end

        def get(address:, define_by_default: true)
          return _get_entry(address: address, include_undefined: define_by_default)
        end

        def to_s()
          return @entries.to_s()
        end
      end
    end
  end
end
