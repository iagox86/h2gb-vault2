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


require 'h2gb/vault/error'

module H2gb
  module Vault
    class Memory
      class MemoryRefs
        def initialize(type:nil)
          @type = type
          @refs = {}
          @xrefs = {}
        end

        def insert(from:, to:)
          if !from.is_a?(Integer)
            raise(Error, "from must be an integer!")
          end
          if from < 0
            raise(Error, "from must not be negative!")
          end
          if !to.is_a?(Integer)
            raise(Error, "to must be an integer!")
          end
          if to < 0
            raise(Error, "to must not be negative!")
          end

          @refs[from] = @refs[from] || []
          @refs[from] << to

          @xrefs[to] = @xrefs[to] || []
          @xrefs[to] << from
        end

        def insert_all(from:, tos:)
          if !tos.is_a?(Array)
            raise(Error, "tos must be an Array")
          end

          tos.each do |to|
            insert(from: from, to: to)
          end
        end

        def delete(from:, to:)
          if @refs[from].nil?
            raise(Error, "No such reference: 0x%x" % from)
          end
          if @xrefs[to].nil?
            raise(Error, "A cross-reference is missing!")
          end

          from_index = @refs[from].find_index(to)
          if from_index.nil?
            raise(Error, "No such reference: 0x%x to 0x%x" % [from, to])
          end
          @refs[from].delete_at(from_index)

          to_index = @xrefs[to].find_index(from)
          if to_index.nil?
            raise(Error, "No such cross reference: 0x%x to 0x%x" % [from, to])
          end
          @xrefs[to].delete_at(to_index)
        end

        def get_refs(from:)
          if @refs[from].nil?
            return []
          end

          # Note: sort() implicitly clones this, which is what we want (so the
          # caller doesn't mess with the array)
          return @refs[from].sort()
        end

        def get_xrefs(to:)
          if @xrefs[to].nil?
            return []
          end

          # Note: sort() implicitly clones this, which is what we want (so the
          # caller doesn't mess with the array)
          return @xrefs[to].sort()
        end
      end
    end
  end
end
