##
# memory_transaction.rb
# Created April, 2017
# By Ron Bowes
#
# See: LICENSE.md
#
# Represents a series of undo-able and redo-able transactions.
##

require 'h2gb/vault/error'

module H2gb
  module Vault
    class Memory
      class MemoryTransaction
        attr_reader :revision

        def initialize(opposites:)
          @opposites = opposites

          @revision = 0
          @redo_buffer = []
          @revisions = []
        end

        def increment(undoable: true, kill_redo_buffer: true)
          @revision += 1
          @revisions[@revision] = {
            undoable: undoable,
            entries: [],
          }

          if kill_redo_buffer
            @redo_buffer = []
          end
        end

        def add_to_current_transaction(type:, entry:)
          @revisions[@revision][:entries] << {
            type: type,
            entry: entry,
          }
        end

        def undo_transaction()
          # Go back until we find the first undoable revision
          undo_revision = 0
          @revision.step(0, -1) do |revision|
            if revision == 0
              return
            end

            if @revisions[revision][:undoable]
              undo_revision = revision
              break
            end
          end

          if undo_revision == 0
            return
          end

          # Create a new entry in the revisions list
          increment(undoable: false, kill_redo_buffer: false)

          # Mark the revision as no longer undoable (since we can't undo an undo)
          @revisions[undo_revision][:undoable] = false

          # Go through the current undo_revision backwards, and unapply each one
          @revisions[undo_revision][:entries].reverse().each do |forward_entry|
            type = @opposites[forward_entry[:type]]
            if type.nil?
              raise(Error, "Unknown revision type: %s" % forward_entry[:type])
            end

            yield(type, forward_entry[:entry])
          end

          # Add the entry to the redo buffer
          @redo_buffer << @revisions[undo_revision]
        end

        def redo_transaction()
          # If there's nothing in our redo buffer, just return
          if @redo_buffer.length == 0
            return
          end

          # Create a new undoable entry in the revisions list
          increment(undoable: true, kill_redo_buffer: false)

          # Go through the current @undo_revision backwards, and unapply each one
          redo_revision = @redo_buffer.pop()
          redo_revision[:entries].each do |redo_entry|
            yield(redo_entry[:type], redo_entry[:entry])
          end

          return true
        end

        def _test_get_transaction(revision:)
          return @revisions[revision]
        end

        def to_s()
          out = []
          out << "Undo buffer:"
          @revisions.each_with_index do |value, key|
            out << " %d: %s" % [key, value]
          end
          out << ""
          out << "Redo buffer:"
          @redo_buffer.each_with_index do |value, key|
            out << " %d: %s" % [key, value]
          end

          return out
        end
      end
    end
  end
end
