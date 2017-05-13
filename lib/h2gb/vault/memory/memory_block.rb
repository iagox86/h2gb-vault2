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

require 'h2gb/vault/memory/memory_refs'

module H2gb
  module Vault
    class Memory
      class MemoryBlock
        attr_reader :raw

        def initialize(raw:, revision:0)
          @raw = raw
          @memory = {}
          @last_revision = -1
          @refs = {}

          @raw.bytes().each_with_index() do |_, index|
            @memory[index] = {
              revision: revision,
              entry: nil,
            }
          end
        end

        private
        def _check_revision(revision:)
          # Make sure the revision can never decrement, or weird stuff will happen
          if revision < @last_revision
            raise(MemoryError, "Tried to use a lower revision!")
          end
          @last_revision = revision
        end

        private
        def _poke_revision(address:, revision:)
          _check_revision(revision: revision)
          @memory[address] = @memory[address] || {}
          @memory[address][:revision] = revision
        end

        public
        def add_refs(address:, type:, refs:, revision:)
          # Create the refs type if it doesn't exist
          @refs[type] = @refs[type] || MemoryRefs.new(type: type)

          refs.each do |ref|
            _poke_revision(revision: revision, address: address)
            @refs[type].insert(address: address, ref: ref)
          end
#          @refs[type].insert(address: entry.address, refs: refs).each() do |address|
#            _poke_revision(revision: revision, address: address)
#          end
        end

        public
        def insert(entry:, revision:, refs: nil)
          _check_revision(revision: revision)

          # Validate before we start making changes
          entry.each_address() do |i|
            if @memory[i].nil?
              raise(MemoryError, "Tried to define an entry that's out of range")
            end
            if @memory[i][:entry]
              raise(MemoryError, "Tried to re-define an entry")
            end
          end
          refs = refs || {}
          if !refs.is_a?(Hash)
            raise(MemoryError, "refs must be a hash (or nil)!")
          end

          # Define each address
          entry.each_address() do |i|
            @memory[i] = {
              revision: revision,
              entry: entry,
            }
          end

          # Deal with references
          refs.each_pair() do |type, ref_list|
            add_refs(address: entry.address, type: type, refs: ref_list, revision: revision)
          end
        end

        def delete(entry:, revision:)
          _check_revision(revision: revision)

          # Validate before we start making changes
          entry.each_address() do |i|
            if @memory[i][:entry].nil?
              raise(MemoryError, "Tried to clear memory that's not in use")
            end
          end

          entry.each_address() do |i|
            @memory[i] = {
              revision: revision,
              entry: nil,
            }
          end

          @refs.each_pair do |type, memory_refs|
            memory_refs.delete(address: entry.address).each() do |address|
              _poke_revision(revision: revision, address: address)
            end
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

        # TODO: I still need to do some re-thinking on how refs work, the
        # other places are kludgy and this is just plain bleh
        def add_reference(entry:, to:, type:, revision:)
          entry.add_reference(to: to, type: type)

          @refs[type] = @refs[type] || MemoryRefs.new(type: type)
          @refs[type].insert(address: entry.address, refs: [to]).each() do |address|
            _poke_revision(revision: revision, address: address)
          end
        end

        def remove_reference(entry:, to:, type:, revision:)
          entry.remove_reference(to: to, type: type)

          @refs[type] = @refs[type] || MemoryRefs.new()
          @refs[type].delete(address: entry.address, refs: [to]).each() do |address|
            _poke_revision(revision: revision, address: address)
          end
        end

        def _get_raw(entry:)
          return @raw[entry.address, entry.length].bytes()
        end

        def _get_entry(address:, include_undefined: true)
          if @memory[address].nil?
            raise(MemoryError, "Tried to retrieve an entry outside of the range")
          end
          entry = @memory[address][:entry]

          # Make sure that we always have an entry to work from
          if entry.nil?
            if !include_undefined
              return nil, {}
            end

            entry = MemoryEntry.default(address: address, raw: @raw[address].ord())
          end

          xrefs = {}
          @refs.each_pair() do |type, memory_refs|
            these_xrefs = memory_refs.get_xrefs(address: entry.address)

            # Only add the element if there's more than one
            if these_xrefs.length() > 0
              xrefs[type] = memory_refs.get_xrefs(address: entry.address)
            end
          end

          return entry, xrefs
        end

        def each_entry_in_range(address:, length:, since: 0, include_undefined: true)
          i = address

          while i < address + length
            entry, xrefs = _get_entry(address: i, include_undefined: include_undefined)
            if entry.nil? # TODO: I don't think this is necessary
              i += 1
              next
            end
            revision = @memory[i][:revision]

            # Pre-compute the next value of i, in case we're deleting the memory
            next_i = entry.address + entry.length

            if revision > since
              yield(entry.address, entry, _get_raw(entry: entry), xrefs)
            end

            i = next_i
          end
        end

        def each_entry(since: 0)
          each_entry_in_range(address: 0, length: @raw.length, since: since) do |address, entry, raw, xrefs|
            yield(address, entry, raw, xrefs)
          end
        end

        def get(address:, define_by_default: true)
          return _get_entry(address: address, include_undefined: define_by_default)
        end

        def to_s()
          return @memory.to_s()
        end
      end
    end
  end
end
