##
# memory_refs.rb
# Created May, 2017
# By Ron Bowes
#
# See LICENSE.md
#
# A class to handle references and cross-references, because it was getting too
# complex to handle them in-line.
##


require 'h2gb/vault/memory/memory_error'

module H2gb
  module Vault
    class Memory
      class MemoryRef
        attr_reader :address, :refs
        def initialize(address:)
          @address = address
          @refs = []
        end

        def add(refs)
          if !refs.is_a?(Array)
            raise(MemoryError, "refs must be an array!")
          end
          if refs.length() == 0
            raise(MemoryError, "refs must have at least one element!")
          end
          refs.each do |ref|
            if !ref.is_a?(Integer)
              raise(MemoryError, "Each ref must be an integer! '%s' is a %s" % [ref.to_s(), ref.class.to_s()])
            end
          end

          @refs = (@refs + refs).uniq().sort()
        end

        def delete(refs)
          if !refs.is_a?(Array)
            raise(MemoryError, "refs must be an array!")
          end
          if refs.length() == 0
            raise(MemoryError, "refs must have at least one element!")
          end

          @refs = (@refs - refs).uniq().sort()
        end

        def to_s()
          return "0x%08x => %s" % [@address, @refs.map() { |ref| "0x%04" % ref }.join(', ')]
        end
      end

      class MemoryRefs
        def initialize(type:nil)
          @type = type
          @refs = {}
          @xrefs = {}
        end

        def insert(address:, refs:)
          if !address.is_a?(Integer)
            raise(MemoryError, "address must be an integer!")
          end
          if address < 0
            raise(MemoryError, "address must not be negative!")
          end

          if @refs[address].nil?
            @refs[address] = MemoryRef.new(address: address)
          end
          @refs[address].add(refs)

          refs.each do |address_ref|
            @xrefs[address_ref] = @xrefs[address_ref] || []
            @xrefs[address_ref] << @refs[address]
          end

          return refs.uniq().sort()
        end

        def delete(address:, refs: nil)
          if refs.nil?
            refs = @refs[address]
          end
          if refs.nil?
            return []
          end

          @refs[address].delete(refs)

          refs.each do |ref|
            if @xrefs[ref].nil?
              raise(MemoryError, "A cross-reference is missing!")
            end
            @xrefs[ref].delete(ref)
          end

          return refs.uniq().sort()
        end

        def get_refs(address:)
          if @refs[address].nil?
            return []
          end
          return @refs[address].refs
        end

        def get_xrefs(address:)
          xrefs = @xrefs[address] || []
          return (xrefs.map() { |xref| xref.address }).uniq().sort()
        end

        def to_s()
          refs  = @refs.map()  { |ref|  ref.to_s }
          xrefs = @xrefs.map() { |xref| xref.to_s }

          return "Refs:\n%s\n\nXrefs:\n%s\n" % [refs, xrefs]
        end
      end
    end
  end
end
