##
# memory_transaction.rb
# Created April, 2017
# By Ron Bowes
#
# See: LICENSE.md
#
# Represents a series of undo-able and redo-able transactions.
##
module H2gb
  module Vault
    class Memory
      class MemoryTransaction
        attr_reader :revision

        def initialize(opposites:)
          @opposites = opposites

          @revision = 0
          @undo_revision = 0
          @redo_buffer = []
          @revisions = []
        end

        def increment(undoable:, kill_redo_buffer:)
          @revision += 1
          @revisions[@revision] = {
            undoable: undoable,
            entries: [],
          }

          if kill_redo_buffer
            @undo_revision = @revision
            @redo_buffer = []
          end
        end

        def add_to_current_transaction(type:, entry:)
          @revisions[@revision][:entries] << {
            action: type,
            entry:  entry,
          }
        end

        def undo_transaction()
          # Go back until we find the first undoable revision
          @undo_revision.step(0, -1) do |revision|
            if revision == 0
              @undo_revision = 0
              return
            end

            if @revisions[revision][:undoable]
              @undo_revision = revision
              break
            end
          end

          # Create a new entry in the revisions list
          increment(undoable: false, kill_redo_buffer: false)

          # Mark the revision as no longer undoable (since we can't undo an undo)
          @revisions[@undo_revision][:undoable] = false

          # Go through the current @undo_revision backwards, and unapply each one
          @revisions[@undo_revision][:entries].reverse().each do |forward_entry|
            action = @opposites[forward_entry[:action]]
            if action.nil?
              raise(MemoryError, "Unknown revision action: %d" % forward_entry[:action])
            end

            yield(action, forward_entry[:entry])
          end

          # Add the entry to the redo buffer
          @redo_buffer << @revisions[@undo_revision]
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
            yield(redo_entry[:action], redo_entry[:entry])
          end

          return true
        end
      end
    end
  end
end
