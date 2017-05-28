require 'test_helper'

require 'h2gb/vault/workspace'

# Generate a nice simple test memory map
RAW = (0..255).to_a().map() { |b| b.chr() }.join()

def _test_define(block_name: nil, workspace:, address:, type: :type, value: "value", length:, refs: {}, user_defined: {}, comment: nil, do_transaction: true)
  if do_transaction
    workspace.transaction() do
      workspace.define(
        block_name: block_name,
        address: address,
        type: type,
        value: value,
        length: length,
        refs: refs,
        user_defined: user_defined,
        comment: comment,
      )
    end
  else
    workspace.define(
      block_name: block_name,
      address: address,
      type: type,
      value: value,
      length: length,
      refs: refs,
      user_defined: user_defined,
      comment: comment,
    )
  end
end

def _test_undefine(block_name:nil, workspace:, address:, length:, do_transaction:true)
  if do_transaction
    workspace.transaction() do
      workspace.undefine(block_name: block_name, address: address, length: length)
    end
  else
    workspace.undefine(block_name: block_name, address: address, length: length)
  end
end

module H2gb
  module Vault
    class InsertTest < Test::Unit::TestCase
      def setup()
        @workspace = Workspace.new(raw: RAW)
      end

      def test_empty()
        result = @workspace.get(address: 0x00, length: 0xFF, since:0)
        expected = {
          revision: 0x00,
          entries: [],
        }
        assert_equal(expected, result)
      end

      def test_single_entry()
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0001)

        result = @workspace.get(address: 0x00, length: 0x01, since:0)
        expected = {
          revision: 0x01,
          entries: [
            TestHelper.test_entry(address: 0x00, length: 0x01, raw: [0x00])
          ]
        }

        assert_equal(expected, result)
      end

      def test_get_longer_entry()
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0008)

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x01,
          entries: [
            TestHelper.test_entry(address: 0x00, length: 0x08, raw: "\x00\x01\x02\x03\x04\x05\x06\x07".bytes())
          ]
        }

        assert_equal(expected, result)
      end

      def test_get_entry_in_middle()
        _test_define(workspace: @workspace, address: 0x0080, length: 0x0004)

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x01,
          entries: [
            TestHelper.test_entry(address: 0x80, length: 0x04, raw: "\x80\x81\x82\x83".bytes())
          ]
        }

        assert_equal(expected, result)
      end

      def test_two_adjacent()
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0002)
        _test_define(workspace: @workspace, address: 0x0002, length: 0x0002)

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)

        expected = {
          revision: 0x02,
          entries: [
            TestHelper.test_entry(address: 0x00, length: 0x02, raw: "\x00\x01".bytes()),
            TestHelper.test_entry(address: 0x02, length: 0x02, raw: "\x02\x03".bytes()),
          ]
        }

        assert_equal(expected, result)
      end

      def test_two_adjacent_in_same_transaction()
        @workspace.transaction do
          _test_define(workspace: @workspace, address: 0x0000, length: 0x0002, do_transaction: false)
          _test_define(workspace: @workspace, address: 0x0002, length: 0x0002, do_transaction: false)
        end

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)

        expected = {
          revision: 1,
          entries: [
            TestHelper.test_entry(address: 0x00, length: 0x02, raw: "\x00\x01".bytes()),
            TestHelper.test_entry(address: 0x02, length: 0x02, raw: "\x02\x03".bytes()),
          ]
        }

        assert_equal(expected, result)
      end

      def test_two_not_adjacent()
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0002)
        _test_define(workspace: @workspace, address: 0x0080, length: 0x0002)

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)

        expected = {
          revision: 0x02,
          entries: [
            TestHelper.test_entry(address: 0x00, length: 0x02, raw: "\x00\x01".bytes()),
            TestHelper.test_entry(address: 0x80, length: 0x02, raw: "\x80\x81".bytes()),
          ]
        }

        assert_equal(expected, result)
      end

      def test_overwrite()
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0002, user_defined: { test: 'A'} )
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0002, user_defined: { test: 'B'} )

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x02,
          entries: [
            TestHelper.test_entry(address: 0x00, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'B'} ),
          ]
        }

        assert_equal(expected, result)
      end

      def test_overwrite_by_shorter()
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0004, user_defined: { test: 'A'} )
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0001, user_defined: { test: 'B'} )

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x02,
          entries: [
            TestHelper.test_entry(address: 0x00, length: 0x01, raw: "\x00".bytes(), user_defined: { test: 'B'} ),
            TestHelper.test_entry_deleted(address: 0x01, raw: "\x01".bytes()),
            TestHelper.test_entry_deleted(address: 0x02, raw: "\x02".bytes()),
            TestHelper.test_entry_deleted(address: 0x03, raw: "\x03".bytes()),
          ]
        }

        assert_equal(expected, result)
      end

      def test_overwrite_middle()
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0008, user_defined: { test: 'A'} )
        _test_define(workspace: @workspace, address: 0x0004, length: 0x0002, user_defined: { test: 'B'} )

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x02,
          entries: [
            TestHelper.test_entry_deleted(address: 0x00, raw: "\x00".bytes()),
            TestHelper.test_entry_deleted(address: 0x01, raw: "\x01".bytes()),
            TestHelper.test_entry_deleted(address: 0x02, raw: "\x02".bytes()),
            TestHelper.test_entry_deleted(address: 0x03, raw: "\x03".bytes()),
            TestHelper.test_entry(address: 0x04, length: 0x02, raw: "\x04\x05".bytes(), user_defined: { test: 'B'} ),
            TestHelper.test_entry_deleted(address: 0x06, raw: "\x06".bytes()),
            TestHelper.test_entry_deleted(address: 0x07, raw: "\x07".bytes()),
          ]
        }

        assert_equal(expected, result)
      end

      def test_overwrite_multiple()
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0002, user_defined: { test: 'A'} )
        _test_define(workspace: @workspace, address: 0x0002, length: 0x0002, user_defined: { test: 'B'} )
        _test_define(workspace: @workspace, address: 0x0001, length: 0x0002, user_defined: { test: 'C'} )

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x03,
          entries: [
            TestHelper.test_entry_deleted(address: 0x00, raw: "\x00".bytes()),
            TestHelper.test_entry(address: 0x01, length: 0x02, raw: "\x01\x02".bytes(), user_defined: { test: 'C'} ),
            TestHelper.test_entry_deleted(address: 0x03, raw: "\x03".bytes()),
          ]
        }

        assert_equal(expected, result)
      end

      def test_overwrite_multiple_with_gap()
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0002, user_defined: { test: 'A'} )
        _test_define(workspace: @workspace, address: 0x0010, length: 0x0010, user_defined: { test: 'B'} )
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0080, user_defined: { test: 'C'} )

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x03,
          entries: [
            TestHelper.test_entry(address: 0x00, length: 0x80, raw: (0x00..0x7F).to_a(), user_defined: { test: 'C'} ),
          ]
        }

        assert_equal(expected, result)
      end

      def test_refs()
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0001, refs: { code: [0x10], data: [0x20] })

        result = @workspace.get(address: 0x00, length: 0xFF, since:0)
        expected = {
          revision: 0x01,
          entries: [
            TestHelper.test_entry(address: 0x00, length: 0x01, raw: [0x00], refs: { code: [0x10], data: [0x20] }),
            TestHelper.test_entry_deleted(address: 0x10, raw: "\x10".bytes(), xrefs: { code: [0x0000] }),
            TestHelper.test_entry_deleted(address: 0x20, raw: "\x20".bytes(), xrefs: { data: [0x0000] }),
          ]
        }

        assert_equal(expected, result)
      end

      def test_undefine()
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0002)
        _test_undefine(workspace: @workspace, address: 0x0000, length: 0x0001)

        result = @workspace.get(address: 0x00, length: 0xFF, since:0)
        expected = {
          revision: 0x02,
          entries: [
            TestHelper.test_entry_deleted(address: 0x00, raw: "\x00".bytes()),
            TestHelper.test_entry_deleted(address: 0x01, raw: "\x01".bytes()),
          ]
        }

        assert_equal(expected, result)
      end

      def test_undefine_multiple()
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0001)
        _test_define(workspace: @workspace, address: 0x0001, length: 0x0002)
        _test_define(workspace: @workspace, address: 0x0004, length: 0x0002)
        _test_define(workspace: @workspace, address: 0x0007, length: 0x0002)
        _test_undefine(workspace: @workspace, address: 1, length: 4)

        result = @workspace.get(address: 0x00, length: 0xFF, since:0)
        expected = {
          revision: 0x05,
          entries: [
            TestHelper.test_entry(address: 0x00, length: 0x01, raw: "\x00".bytes()),
            TestHelper.test_entry_deleted(address: 0x01, raw: "\x01".bytes()),
            TestHelper.test_entry_deleted(address: 0x02, raw: "\x02".bytes()),
            TestHelper.test_entry_deleted(address: 0x04, raw: "\x04".bytes()),
            TestHelper.test_entry_deleted(address: 0x05, raw: "\x05".bytes()),
            TestHelper.test_entry(address: 0x07, length: 0x02, raw: "\x07\x08".bytes()),
          ]
        }

        assert_equal(expected, result)
      end

      def test_undefine_refs()
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0001, refs: {code: [0x10], data: [0x20]})
        _test_undefine(workspace: @workspace, address: 0x0000, length: 0x0001)

        result = @workspace.get(address: 0x00, length: 0xFF, since:0)
        expected = {
          revision: 0x02,
          entries: [
            TestHelper.test_entry_deleted(address: 0x00, raw: "\x00".bytes()),
            TestHelper.test_entry_deleted(address: 0x10, raw: "\x10".bytes()),
            TestHelper.test_entry_deleted(address: 0x20, raw: "\x20".bytes()),
          ]
        }

        assert_equal(expected, result)
      end

      def test_automatic_undefine_handles_references()
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0001, refs: {code: [0x10], data: [0x20]})
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0001)

        result = @workspace.get(address: 0x00, length: 0xFF, since:0)
        expected = {
          revision: 0x02,
          entries: [
            TestHelper.test_entry(address: 0x00, length: 0x0001, raw: "\x00".bytes()),
            TestHelper.test_entry_deleted(address: 0x10, raw: "\x10".bytes()),
            TestHelper.test_entry_deleted(address: 0x20, raw: "\x20".bytes()),
          ]
        }

        assert_equal(expected, result)
      end

      def test_define_invalid()
        assert_raises(Error) do
          _test_define(workspace: @workspace, address: 0x0100, length: 0x01)
        end
      end

      # I accidentally created a bug by doing this in the API, so making sure I test for it
      def test_define_invalid_refs_string()
        assert_raises(Error) do
          _test_define(workspace: @workspace, address: 0x0000, length: 0x0001, refs: {code: [nil]})
        end
      end
    end

    ##
    # Since we already use transactions throughout other tests, this will simply
    # ensure that transactions are required.
    ##
    class TransactionTest < Test::Unit::TestCase
      def setup()
        @workspace = Workspace.new(raw: RAW)
      end

      def test_add_transaction()
        assert_raises(Error) do
          _test_define(workspace: @workspace, address: 0x0000, length: 0x0002, do_transaction: false)
        end
      end

      def test_undefine_transaction()
        assert_raises(Error) do
          _test_undefine(workspace: @workspace, address: 0x0000, length: 0x0002, do_transaction: false)
        end
      end

      def test_revision_increment()
        result = @workspace.get(address: 0x00, length: 0x00, since: 0)
        assert_equal(0, result[:revision])

        @workspace.transaction() do
        end

        result = @workspace.get(address: 0x00, length: 0x00, since: 0)
        assert_equal(1, result[:revision])
      end
    end

    class DeleteTest < Test::Unit::TestCase
      def setup()
        @workspace = Workspace.new(raw: RAW)
      end

      def test_delete_nothing()
        _test_undefine(workspace: @workspace, address: 0x00, length: 0xFF)

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)

        expected = {
          revision: 0x01,
          entries: [],
        }
        assert_equal(expected, result)
      end

      def test_delete_one_byte()
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0001, user_defined: { test: 'A'} )
        _test_undefine(workspace: @workspace, address: 0x0000, length: 0x0001)

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x02,
          entries: [
            TestHelper.test_entry_deleted(address: 0x0000, raw: "\x00".bytes()),
          ],
        }

        assert_equal(expected, result)
      end

      def test_delete_multi_bytes()
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0004, user_defined: { test: 'A'} )
        _test_undefine(workspace: @workspace, address: 0, length: 1)

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x02,
          entries: [
            TestHelper.test_entry_deleted(address: 0x0000, raw: "\x00".bytes()),
            TestHelper.test_entry_deleted(address: 0x0001, raw: "\x01".bytes()),
            TestHelper.test_entry_deleted(address: 0x0002, raw: "\x02".bytes()),
            TestHelper.test_entry_deleted(address: 0x0003, raw: "\x03".bytes()),
          ],
        }

        assert_equal(expected, result)
      end

      def test_delete_zero_bytes()
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0010, user_defined: { test: 'A'} )
        _test_undefine(workspace: @workspace, address: 8, length: 0)

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x02,
          entries: [
            TestHelper.test_entry(address: 0x00, length: 0x10, raw: (0x00..0x0F).to_a(), user_defined: { test: 'A'} ),
          ],
        }

        assert_equal(expected, result)
      end

      def test_delete_just_start()
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0004, user_defined: { test: 'A'} )
        _test_undefine(workspace: @workspace, address: 0000, length: 0x0001)

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x02,
          entries: [
            TestHelper.test_entry_deleted(address: 0x0000, raw: "\x00".bytes()),
            TestHelper.test_entry_deleted(address: 0x0001, raw: "\x01".bytes()),
            TestHelper.test_entry_deleted(address: 0x0002, raw: "\x02".bytes()),
            TestHelper.test_entry_deleted(address: 0x0003, raw: "\x03".bytes()),
          ],
        }

        assert_equal(expected, result)
      end

      def test_delete_just_middle()
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0004, user_defined: { test: 'A'} )
        _test_undefine(workspace: @workspace, address: 0002, length: 0x0001)

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x02,
          entries: [
            TestHelper.test_entry_deleted(address: 0x0000, raw: "\x00".bytes()),
            TestHelper.test_entry_deleted(address: 0x0001, raw: "\x01".bytes()),
            TestHelper.test_entry_deleted(address: 0x0002, raw: "\x02".bytes()),
            TestHelper.test_entry_deleted(address: 0x0003, raw: "\x03".bytes()),
          ],
        }

        assert_equal(expected, result)
      end

      def test_delete_multiple_entries()
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0004, user_defined: { test: 'A'} )
        _test_define(workspace: @workspace, address: 0x0004, length: 0x0004, user_defined: { test: 'B'} )
        _test_define(workspace: @workspace, address: 0x0008, length: 0x0004, user_defined: { test: 'C'} )
        _test_undefine(workspace: @workspace, address: 0x0000, length: 0xFF)

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x04,
          entries: [
            TestHelper.test_entry_deleted(address: 0x0000, raw: "\x00".bytes()),
            TestHelper.test_entry_deleted(address: 0x0001, raw: "\x01".bytes()),
            TestHelper.test_entry_deleted(address: 0x0002, raw: "\x02".bytes()),
            TestHelper.test_entry_deleted(address: 0x0003, raw: "\x03".bytes()),
            TestHelper.test_entry_deleted(address: 0x0004, raw: "\x04".bytes()),
            TestHelper.test_entry_deleted(address: 0x0005, raw: "\x05".bytes()),
            TestHelper.test_entry_deleted(address: 0x0006, raw: "\x06".bytes()),
            TestHelper.test_entry_deleted(address: 0x0007, raw: "\x07".bytes()),
            TestHelper.test_entry_deleted(address: 0x0008, raw: "\x08".bytes()),
            TestHelper.test_entry_deleted(address: 0x0009, raw: "\x09".bytes()),
            TestHelper.test_entry_deleted(address: 0x000a, raw: "\x0a".bytes()),
            TestHelper.test_entry_deleted(address: 0x000b, raw: "\x0b".bytes()),
          ],
        }

        assert_equal(expected, result)
      end

      def test_delete_but_leave_adjacent()
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0004, user_defined: { test: 'A'} )
        _test_define(workspace: @workspace, address: 0x0004, length: 0x0004, user_defined: { test: 'B'} )
        _test_define(workspace: @workspace, address: 0x0008, length: 0x0004, user_defined: { test: 'C'} )
        _test_undefine(workspace: @workspace, address: 0x0004, length: 0x04)

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x04,
          entries: [
            TestHelper.test_entry(address: 0x0000, length: 0x04, raw: "\x00\x01\x02\x03".bytes(), user_defined: { test: 'A'} ),
            TestHelper.test_entry_deleted(address: 0x0004, raw: "\x04".bytes()),
            TestHelper.test_entry_deleted(address: 0x0005, raw: "\x05".bytes()),
            TestHelper.test_entry_deleted(address: 0x0006, raw: "\x06".bytes()),
            TestHelper.test_entry_deleted(address: 0x0007, raw: "\x07".bytes()),
            TestHelper.test_entry(address: 0x0008, length: 0x04, raw: "\x08\x09\x0a\x0b".bytes(), user_defined: { test: 'C'} ),
          ],
        }

        assert_equal(expected, result)
      end

      def test_delete_multi_but_leave_adjacent()
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0004, user_defined: { test: 'A'} )
        _test_define(workspace: @workspace, address: 0x0004, length: 0x0004, user_defined: { test: 'B'} )
        _test_define(workspace: @workspace, address: 0x0008, length: 0x0004, user_defined: { test: 'C'} )
        _test_define(workspace: @workspace, address: 0x000c, length: 0x0004, user_defined: { test: 'D'} )
        _test_undefine(workspace: @workspace, address: 0x0004, length: 0x08)

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x05,
          entries: [
            TestHelper.test_entry(address: 0x0000, length: 0x04, raw: "\x00\x01\x02\x03".bytes(), user_defined: { test: 'A'} ),
            TestHelper.test_entry_deleted(address: 0x0004, raw: "\x04".bytes()),
            TestHelper.test_entry_deleted(address: 0x0005, raw: "\x05".bytes()),
            TestHelper.test_entry_deleted(address: 0x0006, raw: "\x06".bytes()),
            TestHelper.test_entry_deleted(address: 0x0007, raw: "\x07".bytes()),
            TestHelper.test_entry_deleted(address: 0x0008, raw: "\x08".bytes()),
            TestHelper.test_entry_deleted(address: 0x0009, raw: "\x09".bytes()),
            TestHelper.test_entry_deleted(address: 0x000a, raw: "\x0a".bytes()),
            TestHelper.test_entry_deleted(address: 0x000b, raw: "\x0b".bytes()),
            TestHelper.test_entry(address: 0x000c, length: 0x04, raw: "\x0c\x0d\x0e\x0f".bytes(), user_defined: { test: 'D'} ),
          ],
        }

        assert_equal(expected, result)
      end
    end

    class UndoTest < Test::Unit::TestCase
      def setup()
        @workspace = Workspace.new(raw: RAW)
      end

      def test_basic_undo()
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0002, user_defined: { test: 'A'} )
        _test_define(workspace: @workspace, address: 0x0002, length: 0x0002, user_defined: { test: 'B'} )

        @workspace.undo()

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x03,
          entries: [
            TestHelper.test_entry(address: 0x0000, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'A'} ),
            TestHelper.test_entry_deleted(address: 0x0002, raw: "\x02".bytes()),
            TestHelper.test_entry_deleted(address: 0x0003, raw: "\x03".bytes()),
          ],
        }

        assert_equal(expected, result)
      end

      def test_undo_multiple_steps()
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0002, user_defined: { test: 'A'} )
        _test_define(workspace: @workspace, address: 0x0002, length: 0x0002, user_defined: { test: 'B'} )
        _test_define(workspace: @workspace, address: 0x0004, length: 0x0002, user_defined: { test: 'C'} )

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x03,
          entries: [
            TestHelper.test_entry(address: 0x0000, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'A'} ),
            TestHelper.test_entry(address: 0x0002, length: 0x02, raw: "\x02\x03".bytes(), user_defined: { test: 'B'} ),
            TestHelper.test_entry(address: 0x0004, length: 0x02, raw: "\x04\x05".bytes(), user_defined: { test: 'C'} ),
          ]
        }
        assert_equal(expected, result)

        @workspace.undo()
        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x04,
          entries: [
            TestHelper.test_entry(address: 0x0000, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'A'} ),
            TestHelper.test_entry(address: 0x0002, length: 0x02, raw: "\x02\x03".bytes(), user_defined: { test: 'B'} ),
            TestHelper.test_entry_deleted(address: 0x0004, raw: "\x04".bytes()),
            TestHelper.test_entry_deleted(address: 0x0005, raw: "\x05".bytes()),
          ]
        }
        assert_equal(expected, result)

        @workspace.undo()
        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x05,
          entries: [
            TestHelper.test_entry(address: 0x0000, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'A'} ),
            TestHelper.test_entry_deleted(address: 0x0002, raw: "\x02".bytes()),
            TestHelper.test_entry_deleted(address: 0x0003, raw: "\x03".bytes()),
            TestHelper.test_entry_deleted(address: 0x0004, raw: "\x04".bytes()),
            TestHelper.test_entry_deleted(address: 0x0005, raw: "\x05".bytes()),
          ]
        }
        assert_equal(expected, result)

        @workspace.undo()
        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x06,
          entries: [
            TestHelper.test_entry_deleted(address: 0x0000, raw: "\x00".bytes()),
            TestHelper.test_entry_deleted(address: 0x0001, raw: "\x01".bytes()),
            TestHelper.test_entry_deleted(address: 0x0002, raw: "\x02".bytes()),
            TestHelper.test_entry_deleted(address: 0x0003, raw: "\x03".bytes()),
            TestHelper.test_entry_deleted(address: 0x0004, raw: "\x04".bytes()),
            TestHelper.test_entry_deleted(address: 0x0005, raw: "\x05".bytes()),
          ],
        }
        assert_equal(expected, result)
      end

      def test_undo_then_set()
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0002, user_defined: { test: 'A'} )
        _test_define(workspace: @workspace, address: 0x0002, length: 0x0002, user_defined: { test: 'B'} )
        @workspace.undo()
        _test_define(workspace: @workspace, address: 0x0004, length: 0x0002, user_defined: { test: 'C'} )

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 4,
          entries: [
            TestHelper.test_entry(address: 0x0000, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'A'} ),
            TestHelper.test_entry_deleted(address: 0x0002, raw: "\x02".bytes()),
            TestHelper.test_entry_deleted(address: 0x0003, raw: "\x03".bytes()),
            TestHelper.test_entry(address: 0x0004, length: 0x02, raw: "\x04\x05".bytes(), user_defined: { test: 'C'} ),
          ]
        }

        assert_equal(expected, result)
      end

      ##
      # Attempts to exercise the situation where an undo would inappropriately undo
      # another undo.
      ##
      def test_undo_across_other_undos()
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0002, user_defined: { test: 'A'} )
        _test_define(workspace: @workspace, address: 0x0002, length: 0x0002, user_defined: { test: 'B'} )

        @workspace.undo() # undo B

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x03,
          entries: [
            TestHelper.test_entry(address: 0x0000, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'A'} ),
            TestHelper.test_entry_deleted(address: 0x0002, raw: "\x02".bytes()),
            TestHelper.test_entry_deleted(address: 0x0003, raw: "\x03".bytes()),
          ],
        }
        assert_equal(expected, result)

        _test_define(workspace: @workspace, address: 0x0004, length: 0x0002, user_defined: { test: 'C'} )

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x04,
          entries: [
            TestHelper.test_entry(address: 0x0000, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'A'} ),
            TestHelper.test_entry_deleted(address: 0x0002, raw: "\x02".bytes()),
            TestHelper.test_entry_deleted(address: 0x0003, raw: "\x03".bytes()),
            TestHelper.test_entry(address: 0x0004, length: 0x02, raw: "\x04\x05".bytes(), user_defined: { test: 'C'} ),
          ],
        }
        assert_equal(expected, result)

        @workspace.undo() # undo C

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x05,
          entries: [
            TestHelper.test_entry(address: 0x0000, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'A'} ),
            TestHelper.test_entry_deleted(address: 0x0002, raw: "\x02".bytes()),
            TestHelper.test_entry_deleted(address: 0x0003, raw: "\x03".bytes()),
            TestHelper.test_entry_deleted(address: 0x0004, raw: "\x04".bytes()),
            TestHelper.test_entry_deleted(address: 0x0005, raw: "\x05".bytes()),
          ],
        }
        assert_equal(expected, result)

        @workspace.undo() # undo A

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x06,
          entries: [
            TestHelper.test_entry_deleted(address: 0x0000, raw: "\x00".bytes()),
            TestHelper.test_entry_deleted(address: 0x0001, raw: "\x01".bytes()),
            TestHelper.test_entry_deleted(address: 0x0002, raw: "\x02".bytes()),
            TestHelper.test_entry_deleted(address: 0x0003, raw: "\x03".bytes()),
            TestHelper.test_entry_deleted(address: 0x0004, raw: "\x04".bytes()),
            TestHelper.test_entry_deleted(address: 0x0005, raw: "\x05".bytes()),
          ],
        }
        assert_equal(expected, result)
      end

      def test_undo_then_set_then_undo_again()
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0002, user_defined: { test: 'A'} )
        _test_define(workspace: @workspace, address: 0x0002, length: 0x0002, user_defined: { test: 'B'} )

        @workspace.undo()

        _test_define(workspace: @workspace, address: 0x0004, length: 0x0002, user_defined: { test: 'C'} )

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x04,
          entries: [
            TestHelper.test_entry(address: 0x0000, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'A'} ),
            TestHelper.test_entry_deleted(address: 0x0002, raw: "\x02".bytes()),
            TestHelper.test_entry_deleted(address: 0x0003, raw: "\x03".bytes()),
            TestHelper.test_entry(address: 0x0004, length: 0x02, raw: "\x04\x05".bytes(), user_defined: { test: 'C'} ),
          ]
        }
        assert_equal(expected, result)

        @workspace.undo()
        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x05,
          entries: [
            TestHelper.test_entry(address: 0x0000, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'A'} ),
            TestHelper.test_entry_deleted(address: 0x0002, raw: "\x02".bytes()),
            TestHelper.test_entry_deleted(address: 0x0003, raw: "\x03".bytes()),
            TestHelper.test_entry_deleted(address: 0x0004, raw: "\x04".bytes()),
            TestHelper.test_entry_deleted(address: 0x0005, raw: "\x05".bytes()),
          ]
        }
        assert_equal(expected, result)
      end

      def test_undo_too_much()
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0002, user_defined: { test: 'A'} )

        @workspace.undo()
        @workspace.undo()
        @workspace.undo()
        @workspace.undo()
        @workspace.undo()
        @workspace.undo()

        _test_define(workspace: @workspace, address: 0x0001, length: 0x0002, user_defined: { test: 'B'} )
        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)

        expected = {
          revision: 0x03,
          entries: [
            TestHelper.test_entry_deleted(address: 0x0000, raw: "\x00".bytes()),
            TestHelper.test_entry(address: 0x0001, length: 0x02, raw: "\x01\x02".bytes(), user_defined: { test: 'B'} ),
          ]
        }

        assert_equal(expected, result)
      end

      def test_undo_overwrite()
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0002, user_defined: { test: 'A'} )
        _test_define(workspace: @workspace, address: 0x0001, length: 0x0002, user_defined: { test: 'B'} )

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x02,
          entries: [
            TestHelper.test_entry_deleted(address: 0x0000, raw: "\x00".bytes()),
            TestHelper.test_entry(address: 0x0001, length: 0x02, raw: "\x01\x02".bytes(), user_defined: { test: 'B'} ),
          ]
        }
        assert_equal(expected, result)

        @workspace.undo()
        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x03,
          entries: [
            TestHelper.test_entry(address: 0x0000, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'A'} ),
            TestHelper.test_entry_deleted(address: 0x0002, raw: "\x02".bytes()),
          ]
        }
        assert_equal(expected, result)
      end

      def test_transaction_undo()
        @workspace.transaction() do
          _test_define(workspace: @workspace, address: 0x0000, length: 0x0002, user_defined: { test: 'A'}, do_transaction: false )
          _test_define(workspace: @workspace, address: 0x0002, length: 0x0002, user_defined: { test: 'B'}, do_transaction: false )
        end

        @workspace.transaction() do
          _test_define(workspace: @workspace, address: 0x0001, length: 0x0002, user_defined: { test: 'C'}, do_transaction: false )
          _test_define(workspace: @workspace, address: 0x0003, length: 0x0002, user_defined: { test: 'D'}, do_transaction: false )
        end

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x02,
          entries: [
            TestHelper.test_entry_deleted(address: 0x0000, raw: "\x00".bytes()),
            TestHelper.test_entry(address: 0x0001, length: 0x02, raw: "\x01\x02".bytes(), user_defined: { test: 'C'} ),
            TestHelper.test_entry(address: 0x0003, length: 0x02, raw: "\x03\x04".bytes(), user_defined: { test: 'D'} ),
          ]
        }
        assert_equal(expected, result)

        @workspace.undo()

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x03,
          entries: [
            { address: 0x00, data: "A", length: 0x02, refs: [], raw: [0x00, 0x01], xrefs: [] },
            { address: 0x02, data: "B", length: 0x02, refs: [], raw: [0x02, 0x03], xrefs: [] },
            { address: 0x04, data: nil, length: 0x01, refs: [], raw: [0x04], xrefs: [] },
          ]
        }
        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x03,
          entries: [
            TestHelper.test_entry(address: 0x0000, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'A'} ),
            TestHelper.test_entry(address: 0x0002, length: 0x02, raw: "\x02\x03".bytes(), user_defined: { test: 'B'} ),
            TestHelper.test_entry_deleted(address: 0x0004, raw: "\x04".bytes()),
          ]
        }
        assert_equal(expected, result)
      end

      def test_repeat_undo_redo()
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0002, user_defined: { test: 'A'} )
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0002, user_defined: { test: 'B'} )

        @workspace.undo()

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x03,
          entries: [
            TestHelper.test_entry(address: 0x0000, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'A'} ),

          ],
        }
        assert_equal(expected, result)

        @workspace.redo()

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x04,
          entries: [
            TestHelper.test_entry(address: 0x0000, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'B'} ),
          ],
        }
        assert_equal(expected, result)

        @workspace.undo()

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x05,
          entries: [
            TestHelper.test_entry(address: 0x0000, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'A'} ),
          ],
        }
        assert_equal(expected, result)

        @workspace.redo()

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x06,
          entries: [
            TestHelper.test_entry(address: 0x0000, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'B'} ),
          ],
        }
        assert_equal(expected, result)

        @workspace.undo()

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x07,
          entries: [
            TestHelper.test_entry(address: 0x0000, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'A'} ),
          ],
        }
        assert_equal(expected, result)

        @workspace.redo()

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x08,
          entries: [
            TestHelper.test_entry(address: 0x0000, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'B'} ),
          ],
        }
        assert_equal(expected, result)
      end
    end

    class RedoTest < Test::Unit::TestCase
      def setup()
        @workspace = Workspace.new(raw: RAW)
      end

      def test_basic_redo()
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0002, user_defined: { test: 'A'} )
        _test_define(workspace: @workspace, address: 0x0002, length: 0x0002, user_defined: { test: 'B'} )
        @workspace.undo()
        @workspace.redo()

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)

        expected = {
          revision: 0x04,
          entries: [
            TestHelper.test_entry(address: 0x0000, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'A'} ),
            TestHelper.test_entry(address: 0x0002, length: 0x02, raw: "\x02\x03".bytes(), user_defined: { test: 'B'} ),
          ]
        }

        assert_equal(expected, result)
      end

      def test_redo_multiple_steps()
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0002, user_defined: { test: 'A'} )
        _test_define(workspace: @workspace, address: 0x0002, length: 0x0002, user_defined: { test: 'B'} )
        _test_define(workspace: @workspace, address: 0x0004, length: 0x0002, user_defined: { test: 'C'} )

        @workspace.undo()
        @workspace.undo()
        @workspace.undo()

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x06,
          entries: [
            TestHelper.test_entry_deleted(address: 0x0000, raw: "\x00".bytes()),
            TestHelper.test_entry_deleted(address: 0x0001, raw: "\x01".bytes()),
            TestHelper.test_entry_deleted(address: 0x0002, raw: "\x02".bytes()),
            TestHelper.test_entry_deleted(address: 0x0003, raw: "\x03".bytes()),
            TestHelper.test_entry_deleted(address: 0x0004, raw: "\x04".bytes()),
            TestHelper.test_entry_deleted(address: 0x0005, raw: "\x05".bytes()),
          ]
        }
        assert_equal(expected, result)

        @workspace.redo()
        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x07,
          entries: [
            TestHelper.test_entry(address: 0x0000, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'A'} ),
            TestHelper.test_entry_deleted(address: 0x0002, raw: "\x02".bytes()),
            TestHelper.test_entry_deleted(address: 0x0003, raw: "\x03".bytes()),
            TestHelper.test_entry_deleted(address: 0x0004, raw: "\x04".bytes()),
            TestHelper.test_entry_deleted(address: 0x0005, raw: "\x05".bytes()),
          ]
        }
        assert_equal(expected, result)

        @workspace.redo()
        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x08,
          entries: [
            TestHelper.test_entry(address: 0x0000, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'A'} ),
            TestHelper.test_entry(address: 0x0002, length: 0x02, raw: "\x02\x03".bytes(), user_defined: { test: 'B'} ),
            TestHelper.test_entry_deleted(address: 0x0004, raw: "\x04".bytes()),
            TestHelper.test_entry_deleted(address: 0x0005, raw: "\x05".bytes()),
          ]
        }
        assert_equal(expected, result)

        @workspace.redo()
        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x09,
          entries: [
            TestHelper.test_entry(address: 0x0000, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'A'} ),
            TestHelper.test_entry(address: 0x0002, length: 0x02, raw: "\x02\x03".bytes(), user_defined: { test: 'B'} ),
            TestHelper.test_entry(address: 0x0004, length: 0x02, raw: "\x04\x05".bytes(), user_defined: { test: 'C'} ),
          ]
        }
        assert_equal(expected, result)
      end

      def test_redo_then_set()
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0002, user_defined: { test: 'A'} )
        _test_define(workspace: @workspace, address: 0x0002, length: 0x0002, user_defined: { test: 'B'} )
        @workspace.undo()
        @workspace.redo()
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0002, user_defined: { test: 'C'} )

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)

        expected = {
          revision: 0x05,
          entries: [
            TestHelper.test_entry(address: 0x0000, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'C'} ),
            TestHelper.test_entry(address: 0x0002, length: 0x02, raw: "\x02\x03".bytes(), user_defined: { test: 'B'} ),
          ]
        }

        assert_equal(expected, result)
      end

      ##
      # Attempts to exercise the situation where an undo would inappropriately undo
      # another undo.
      ##
      def test_redo_across_other_undos()
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0002, user_defined: { test: 'A'} )
        _test_define(workspace: @workspace, address: 0x0002, length: 0x0002, user_defined: { test: 'B'} )

        @workspace.undo() # undo B

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x03,
          entries: [
            TestHelper.test_entry(address: 0x0000, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'A'} ),
            TestHelper.test_entry_deleted(address: 0x0002, raw: "\x02".bytes() ),
            TestHelper.test_entry_deleted(address: 0x0003, raw: "\x03".bytes() ),
          ],
        }
        assert_equal(expected, result)

        _test_define(workspace: @workspace, address: 0x0004, length: 0x0002, user_defined: { test: 'C'} )

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x04,
          entries: [
            TestHelper.test_entry(address: 0x0000, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'A'} ),
            TestHelper.test_entry_deleted(address: 0x0002, raw: "\x02".bytes() ),
            TestHelper.test_entry_deleted(address: 0x0003, raw: "\x03".bytes() ),
            TestHelper.test_entry(address: 0x0004, length: 0x02, raw: "\x04\x05".bytes(), user_defined: { test: 'C'} ),
          ],
        }
        assert_equal(expected, result)

        @workspace.undo() # undo C

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x05,
          entries: [
            TestHelper.test_entry(address: 0x0000, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'A'} ),
            TestHelper.test_entry_deleted(address: 0x0002, raw: "\x02".bytes() ),
            TestHelper.test_entry_deleted(address: 0x0003, raw: "\x03".bytes() ),
            TestHelper.test_entry_deleted(address: 0x0004, raw: "\x04".bytes() ),
            TestHelper.test_entry_deleted(address: 0x0005, raw: "\x05".bytes() ),
          ],
        }
        assert_equal(expected, result)

        @workspace.undo() # undo A

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x06,
          entries: [
            TestHelper.test_entry_deleted(address: 0x0000, raw: "\x00".bytes() ),
            TestHelper.test_entry_deleted(address: 0x0001, raw: "\x01".bytes() ),
            TestHelper.test_entry_deleted(address: 0x0002, raw: "\x02".bytes() ),
            TestHelper.test_entry_deleted(address: 0x0003, raw: "\x03".bytes() ),
            TestHelper.test_entry_deleted(address: 0x0004, raw: "\x04".bytes() ),
            TestHelper.test_entry_deleted(address: 0x0005, raw: "\x05".bytes() ),
          ],
        }
        assert_equal(expected, result)

        @workspace.redo() # redo A

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x07,
          entries: [
            TestHelper.test_entry(address: 0x0000, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'A'} ),
            TestHelper.test_entry_deleted(address: 0x0002, raw: "\x02".bytes() ),
            TestHelper.test_entry_deleted(address: 0x0003, raw: "\x03".bytes() ),
            TestHelper.test_entry_deleted(address: 0x0004, raw: "\x04".bytes() ),
            TestHelper.test_entry_deleted(address: 0x0005, raw: "\x05".bytes() ),
          ],
        }
        assert_equal(expected, result)

        @workspace.redo() # redo C

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x08,
          entries: [
            TestHelper.test_entry(address: 0x0000, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'A'} ),
            TestHelper.test_entry_deleted(address: 0x0002, raw: "\x02".bytes() ),
            TestHelper.test_entry_deleted(address: 0x0003, raw: "\x03".bytes() ),
            TestHelper.test_entry(address: 0x0004, length: 0x02, raw: "\x04\x05".bytes(), user_defined: { test: 'C'} ),
          ],
        }
        assert_equal(expected, result)

        @workspace.redo() # Should do nothing
        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x08,
          entries: [
            TestHelper.test_entry(address: 0x0000, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'A'} ),
            TestHelper.test_entry_deleted(address: 0x0002, raw: "\x02".bytes() ),
            TestHelper.test_entry_deleted(address: 0x0003, raw: "\x03".bytes() ),
            TestHelper.test_entry(address: 0x0004, length: 0x02, raw: "\x04\x05".bytes(), user_defined: { test: 'C'} ),
          ],
        }
        assert_equal(expected, result)
      end

      def test_redo_goes_away_after_edit()
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0002, user_defined: { test: 'A'} )
        _test_define(workspace: @workspace, address: 0x0002, length: 0x0002, user_defined: { test: 'B'} )
        _test_define(workspace: @workspace, address: 0x0004, length: 0x0002, user_defined: { test: 'C'} )

        @workspace.undo()
        @workspace.undo()
        @workspace.undo()

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        assert_equal({
          revision: 0x06,
          entries: [
            TestHelper.test_entry_deleted(address: 0x0000, raw: "\x00".bytes() ),
            TestHelper.test_entry_deleted(address: 0x0001, raw: "\x01".bytes() ),
            TestHelper.test_entry_deleted(address: 0x0002, raw: "\x02".bytes() ),
            TestHelper.test_entry_deleted(address: 0x0003, raw: "\x03".bytes() ),
            TestHelper.test_entry_deleted(address: 0x0004, raw: "\x04".bytes() ),
            TestHelper.test_entry_deleted(address: 0x0005, raw: "\x05".bytes() ),
          ],
        }, result)

        @workspace.redo()

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x07,
          entries: [
            TestHelper.test_entry(address: 0x0000, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'A'} ),
            TestHelper.test_entry_deleted(address: 0x0002, raw: "\x02".bytes() ),
            TestHelper.test_entry_deleted(address: 0x0003, raw: "\x03".bytes() ),
            TestHelper.test_entry_deleted(address: 0x0004, raw: "\x04".bytes() ),
            TestHelper.test_entry_deleted(address: 0x0005, raw: "\x05".bytes() ),
          ]
        }
        assert_equal(expected, result)

        _test_define(workspace: @workspace, address: 0x0006, length: 0x0002, user_defined: { test: 'D'} )

        @workspace.redo() # Should do nothing

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x08,
          entries: [
            TestHelper.test_entry(address: 0x0000, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'A'} ),
            TestHelper.test_entry_deleted(address: 0x0002, raw: "\x02".bytes() ),
            TestHelper.test_entry_deleted(address: 0x0003, raw: "\x03".bytes() ),
            TestHelper.test_entry_deleted(address: 0x0004, raw: "\x04".bytes() ),
            TestHelper.test_entry_deleted(address: 0x0005, raw: "\x05".bytes() ),
            TestHelper.test_entry(address: 0x0006, length: 0x02, raw: "\x06\x07".bytes(), user_defined: { test: 'D'} ),
          ]
        }
        assert_equal(expected, result)
      end

      def test_redo_too_much()
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0002, user_defined: { test: 'A'} )
        @workspace.undo()
        @workspace.undo()
        @workspace.redo()
        @workspace.redo()
        @workspace.redo()
        @workspace.redo()

        _test_define(workspace: @workspace, address: 0x0002, length: 0x0002, user_defined: { test: 'B'} )
        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)

        expected = {
          revision: 0x04,
          entries: [
            TestHelper.test_entry(address: 0x0000, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'A'} ),
            TestHelper.test_entry(address: 0x0002, length: 0x02, raw: "\x02\x03".bytes(), user_defined: { test: 'B'} ),
          ]
        }

        assert_equal(expected, result)
      end

      def test_redo_overwrite()
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0002, user_defined: { test: 'A'} )
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0001, user_defined: { test: 'B'} )
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0003, user_defined: { test: 'C'} )

        @workspace.undo()
        @workspace.undo()
        @workspace.undo()
        @workspace.redo()
        @workspace.redo()
        @workspace.redo()

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x09,
          entries: [
            TestHelper.test_entry(address: 0x0000, length: 0x03, raw: "\x00\x01\x02".bytes(), user_defined: { test: 'C'} ),
          ]
        }
        assert_equal(expected, result)
      end

      def test_transaction_redo()
        @workspace.transaction() do
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0002, user_defined: { test: 'A'}, do_transaction: false)
        _test_define(workspace: @workspace, address: 0x0002, length: 0x0002, user_defined: { test: 'B'}, do_transaction: false)
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0002, user_defined: { test: 'C'}, do_transaction: false)
        _test_define(workspace: @workspace, address: 0x0004, length: 0x0002, user_defined: { test: 'D'}, do_transaction: false)
        end

        @workspace.transaction() do
        _test_define(workspace: @workspace, address: 0x0001, length: 0x0002, user_defined: { test: 'E'}, do_transaction: false)
        _test_define(workspace: @workspace, address: 0x0006, length: 0x0002, user_defined: { test: 'F'}, do_transaction: false)
        end

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)

        @workspace.undo()
        @workspace.undo()

        @workspace.redo()

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x05,
          entries: [
            TestHelper.test_entry(address: 0x0000, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'C'} ),
            TestHelper.test_entry(address: 0x0002, length: 0x02, raw: "\x02\x03".bytes(), user_defined: { test: 'B'} ),
            TestHelper.test_entry(address: 0x0004, length: 0x02, raw: "\x04\x05".bytes(), user_defined: { test: 'D'} ),
            TestHelper.test_entry_deleted(address: 0x0006, raw: "\x06".bytes() ),
            TestHelper.test_entry_deleted(address: 0x0007, raw: "\x07".bytes() ),
          ]
        }
        assert_equal(expected, result)


        @workspace.redo()

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x06,
          entries: [
            TestHelper.test_entry_deleted(address: 0x0000, raw: "\x00".bytes() ),
            TestHelper.test_entry(address: 0x0001, length: 0x02, raw: "\x01\x02".bytes(), user_defined: { test: 'E'} ),
            TestHelper.test_entry_deleted(address: 0x0003, raw: "\x03".bytes() ),
            TestHelper.test_entry(address: 0x0004, length: 0x02, raw: "\x04\x05".bytes(), user_defined: { test: 'D'} ),
            TestHelper.test_entry(address: 0x0006, length: 0x02, raw: "\x06\x07".bytes(), user_defined: { test: 'F'} ),
          ]
        }
        assert_equal(expected, result)
      end
    end

    class GetChangesSinceTest < Test::Unit::TestCase
      def setup()
        @workspace = Workspace.new(raw: RAW)
      end


      def test_get_from_minus_one()
        _test_define(workspace: @workspace, address: 0x0001, length: 0x0002, user_defined: { test: 'A'})

        result = @workspace.get(address: 0x00, length: 0x04, since: -1)
        expected = {
          revision: 0x1,
          entries: [
            TestHelper.test_entry_deleted(address: 0x0000, raw: "\x00".bytes() ),
            TestHelper.test_entry(address: 0x0001, length: 0x02, raw: "\x01\x02".bytes(), user_defined: { test: 'A'} ),
            TestHelper.test_entry_deleted(address: 0x0003, raw: "\x03".bytes() ),
          ]
        }

        assert_equal(expected, result)
      end

      def test_add_one()
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0001, user_defined: { test: 'A'})

        result = @workspace.get(address: 0x00, length: 0x10, since: 0)
        expected = {
          revision: 0x1,
          entries: [
            TestHelper.test_entry(address: 0x0000, length: 0x01, raw: "\x00".bytes(), user_defined: { test: 'A'} ),
          ]
        }

        assert_equal(expected, result)
      end

      def test_add_multiple()
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0004, user_defined: { test: 'A'})
        _test_define(workspace: @workspace, address: 0x0004, length: 0x0004, user_defined: { test: 'B'})
        _test_define(workspace: @workspace, address: 0x0008, length: 0x0004, user_defined: { test: 'C'})

        result = @workspace.get(address: 0x00, length: 0x10, since: 0)
        expected = {
          revision: 0x3,
          entries: [
            TestHelper.test_entry(address: 0x0000, length: 0x04, raw: "\x00\x01\x02\x03".bytes(), user_defined: { test: 'A'} ),
            TestHelper.test_entry(address: 0x0004, length: 0x04, raw: "\x04\x05\x06\x07".bytes(), user_defined: { test: 'B'} ),
            TestHelper.test_entry(address: 0x0008, length: 0x04, raw: "\x08\x09\x0a\x0b".bytes(), user_defined: { test: 'C'} ),
          ]
        }
        assert_equal(expected, result)

        result = @workspace.get(address: 0x00, length: 0x10, since: 1)
        expected = {
          revision: 0x3,
          entries: [
            TestHelper.test_entry(address: 0x0004, length: 0x04, raw: "\x04\x05\x06\x07".bytes(), user_defined: { test: 'B'} ),
            TestHelper.test_entry(address: 0x0008, length: 0x04, raw: "\x08\x09\x0a\x0b".bytes(), user_defined: { test: 'C'} ),
          ]
        }
        assert_equal(expected, result)

        result = @workspace.get(address: 0x00, length: 0x10, since: 2)
        expected = {
          revision: 0x3,
          entries: [
            TestHelper.test_entry(address: 0x0008, length: 0x04, raw: "\x08\x09\x0a\x0b".bytes(), user_defined: { test: 'C'} ),
          ]
        }
        assert_equal(expected, result)

        result = @workspace.get(address: 0x00, length: 0x10, since: 3)
        expected = {
          revision: 0x3,
          entries: []
        }
        assert_equal(expected, result)
      end

      def test_overwrite()
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0004, user_defined: { test: 'A'})
        _test_define(workspace: @workspace, address: 0x0002, length: 0x0004, user_defined: { test: 'B'})
        _test_define(workspace: @workspace, address: 0x0004, length: 0x0004, user_defined: { test: 'C'})

        result = @workspace.get(address: 0x00, length: 0x10, since: 0)
        expected = {
          revision: 0x3,
          entries: [
            TestHelper.test_entry_deleted(address: 0x0000, raw: "\x00".bytes() ),
            TestHelper.test_entry_deleted(address: 0x0001, raw: "\x01".bytes() ),
            TestHelper.test_entry_deleted(address: 0x0002, raw: "\x02".bytes() ),
            TestHelper.test_entry_deleted(address: 0x0003, raw: "\x03".bytes() ),
            TestHelper.test_entry(address: 0x0004, length: 0x04, raw: "\x04\x05\x06\x07".bytes(), user_defined: { test: 'C'} ),
          ]
        }
        assert_equal(expected, result)

        result = @workspace.get(address: 0x00, length: 0x10, since: 1)
        expected = {
          revision: 0x3,
          entries: [
            TestHelper.test_entry_deleted(address: 0x0000, raw: "\x00".bytes() ),
            TestHelper.test_entry_deleted(address: 0x0001, raw: "\x01".bytes() ),
            TestHelper.test_entry_deleted(address: 0x0002, raw: "\x02".bytes() ),
            TestHelper.test_entry_deleted(address: 0x0003, raw: "\x03".bytes() ),
            TestHelper.test_entry(address: 0x0004, length: 0x04, raw: "\x04\x05\x06\x07".bytes(), user_defined: { test: 'C'} ),
          ]
        }
        assert_equal(expected, result)

        result = @workspace.get(address: 0x00, length: 0x10, since: 2)
        expected = {
          revision: 0x3,
          entries: [
            TestHelper.test_entry_deleted(address: 0x0002, raw: "\x02".bytes() ),
            TestHelper.test_entry_deleted(address: 0x0003, raw: "\x03".bytes() ),
            TestHelper.test_entry(address: 0x0004, length: 0x04, raw: "\x04\x05\x06\x07".bytes(), user_defined: { test: 'C'} ),
          ]
        }
        assert_equal(expected, result)

        result = @workspace.get(address: 0x00, length: 0x10, since: 3)
        expected = {
          revision: 0x3,
          entries: []
        }
        assert_equal(expected, result)
      end

      def test_undo()
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0002, user_defined: { test: 'A'})
        _test_define(workspace: @workspace, address: 0x0004, length: 0x0002, user_defined: { test: 'B'})
        _test_define(workspace: @workspace, address: 0x0008, length: 0x0002, user_defined: { test: 'C'})
        @workspace.undo()
        @workspace.undo()
        @workspace.undo()

        result = @workspace.get(address: 0x00, length: 0x10, since: 0)
        expected = {
          revision: 0x06,
          entries: [
            TestHelper.test_entry_deleted(address: 0x0000, raw: "\x00".bytes() ),
            TestHelper.test_entry_deleted(address: 0x0001, raw: "\x01".bytes() ),
            TestHelper.test_entry_deleted(address: 0x0004, raw: "\x04".bytes() ),
            TestHelper.test_entry_deleted(address: 0x0005, raw: "\x05".bytes() ),
            TestHelper.test_entry_deleted(address: 0x0008, raw: "\x08".bytes() ),
            TestHelper.test_entry_deleted(address: 0x0009, raw: "\x09".bytes() ),
          ]
        }
        assert_equal(expected, result)

        result = @workspace.get(address: 0x00, length: 0x10, since: 3)
        expected = {
          revision: 0x06,
          entries: [
            TestHelper.test_entry_deleted(address: 0x0000, raw: "\x00".bytes() ),
            TestHelper.test_entry_deleted(address: 0x0001, raw: "\x01".bytes() ),
            TestHelper.test_entry_deleted(address: 0x0004, raw: "\x04".bytes() ),
            TestHelper.test_entry_deleted(address: 0x0005, raw: "\x05".bytes() ),
            TestHelper.test_entry_deleted(address: 0x0008, raw: "\x08".bytes() ),
            TestHelper.test_entry_deleted(address: 0x0009, raw: "\x09".bytes() ),
          ]
        }
        assert_equal(expected, result)

        result = @workspace.get(address: 0x00, length: 0x10, since: 4)
        expected = {
          revision: 0x06,
          entries: [
            TestHelper.test_entry_deleted(address: 0x0000, raw: "\x00".bytes() ),
            TestHelper.test_entry_deleted(address: 0x0001, raw: "\x01".bytes() ),
            TestHelper.test_entry_deleted(address: 0x0004, raw: "\x04".bytes() ),
            TestHelper.test_entry_deleted(address: 0x0005, raw: "\x05".bytes() ),
          ]
        }
        assert_equal(expected, result)

        result = @workspace.get(address: 0x00, length: 0x10, since: 5)
        expected = {
          revision: 0x06,
          entries: [
            TestHelper.test_entry_deleted(address: 0x0000, raw: "\x00".bytes() ),
            TestHelper.test_entry_deleted(address: 0x0001, raw: "\x01".bytes() ),
          ]
        }
        assert_equal(expected, result)

        result = @workspace.get(address: 0x00, length: 0x10, since: 6)
        expected = {
          revision: 0x06,
          entries: [],
        }
        assert_equal(expected, result)
      end

      def test_redo()
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0004, user_defined: { test: 'A'})
        _test_define(workspace: @workspace, address: 0x0002, length: 0x0004, user_defined: { test: 'B'})
        _test_define(workspace: @workspace, address: 0x0008, length: 0x0002, user_defined: { test: 'C'})
        @workspace.undo()
        @workspace.undo()
        @workspace.undo()
        @workspace.redo()
        @workspace.redo()
        @workspace.redo()

        result = @workspace.get(address: 0x00, length: 0x10, since: 0)
        expected = {
          revision: 0x09,
          entries: [
            TestHelper.test_entry_deleted(address: 0x0000, raw: "\x00".bytes() ),
            TestHelper.test_entry_deleted(address: 0x0001, raw: "\x01".bytes() ),
            TestHelper.test_entry(address: 0x0002, length: 0x04, raw: "\x02\x03\x04\x05".bytes(), user_defined: { test: 'B'} ),
            TestHelper.test_entry(address: 0x0008, length: 0x02, raw: "\x08\x09".bytes(), user_defined: { test: 'C'} ),
          ]
        }
        assert_equal(expected, result)

        result = @workspace.get(address: 0x00, length: 0x10, since: 6)
        expected = {
          revision: 0x09,
          entries: [
            TestHelper.test_entry_deleted(address: 0x0000, raw: "\x00".bytes() ),
            TestHelper.test_entry_deleted(address: 0x0001, raw: "\x01".bytes() ),
            TestHelper.test_entry(address: 0x0002, length: 0x04, raw: "\x02\x03\x04\x05".bytes(), user_defined: { test: 'B'} ),
            TestHelper.test_entry(address: 0x0008, length: 0x02, raw: "\x08\x09".bytes(), user_defined: { test: 'C'} ),
          ]
        }
        assert_equal(expected, result)

        result = @workspace.get(address: 0x00, length: 0x10, since: 7)
        expected = {
          revision: 0x09,
          entries: [
            TestHelper.test_entry_deleted(address: 0x0000, raw: "\x00".bytes() ),
            TestHelper.test_entry_deleted(address: 0x0001, raw: "\x01".bytes() ),
            TestHelper.test_entry(address: 0x0002, length: 0x04, raw: "\x02\x03\x04\x05".bytes(), user_defined: { test: 'B'} ),
            TestHelper.test_entry(address: 0x0008, length: 0x02, raw: "\x08\x09".bytes(), user_defined: { test: 'C'} ),
          ]
        }
        assert_equal(expected, result)

        result = @workspace.get(address: 0x00, length: 0x10, since: 8)
        expected = {
          revision: 0x09,
          entries: [
            TestHelper.test_entry(address: 0x0008, length: 0x02, raw: "\x08\x09".bytes(), user_defined: { test: 'C'} ),
          ]
        }
        assert_equal(expected, result)
      end
    end

    class XrefsTest < Test::Unit::TestCase
      def setup()
        @workspace = Workspace.new(raw: RAW)
      end

      def test_basic_xref()
       _test_define(workspace: @workspace, address: 0x0000, length: 0x0004, user_defined: { test: 'A'})
       _test_define(workspace: @workspace, address: 0x0004, length: 0x0004, user_defined: { test: 'B'}, refs: {code: [0x0000]})

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x02,
          entries: [
            TestHelper.test_entry(address: 0x0000, length: 0x04, raw: "\x00\x01\x02\x03".bytes(), user_defined: { test: 'A'}, xrefs: {code: [0x0004]} ),
            TestHelper.test_entry(address: 0x0004, length: 0x04, raw: "\x04\x05\x06\x07".bytes(), user_defined: { test: 'B'}, refs: {code: [0x0000]} ),
          ]
        }
        assert_equal(expected, result)
      end

      def test_different_xref_types()
       _test_define(workspace: @workspace, address: 0x0000, length: 0x0004, user_defined: { test: 'A'})
       _test_define(workspace: @workspace, address: 0x0004, length: 0x0004, user_defined: { test: 'B'}, refs: {data: [0x0000], code: [0x0000, 0x0004]})

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x02,
          entries: [
            TestHelper.test_entry(address: 0x0000, length: 0x04, raw: "\x00\x01\x02\x03".bytes(), user_defined: { test: 'A'}, xrefs: {data: [0x0004], code: [0x0004]} ),
            TestHelper.test_entry(address: 0x0004, length: 0x04, raw: "\x04\x05\x06\x07".bytes(), user_defined: { test: 'B'}, refs: {data: [0x0000], code: [0x0000, 0x0004]}, xrefs: {code: [0x0004]} ),
          ]
        }
        assert_equal(expected, result)
      end

      def test_xref_to_middle()
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0004, user_defined: { test: 'A'})
        _test_define(workspace: @workspace, address: 0x0004, length: 0x0004, user_defined: { test: 'B'}, refs: {code: [0x0002]})

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x02,
          entries: [
            TestHelper.test_entry(address: 0x0000, length: 0x04, raw: "\x00\x01\x02\x03".bytes(), user_defined: { test: 'A'} ),
            TestHelper.test_entry(address: 0x0004, length: 0x04, raw: "\x04\x05\x06\x07".bytes(), user_defined: { test: 'B'}, refs: {code: [0x0002]} ),
          ]
        }
        assert_equal(expected, result)
      end

      def test_multiple_same_refs()
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0004, user_defined: { test: 'A'})
        _test_define(workspace: @workspace, address: 0x0004, length: 0x0004, user_defined: { test: 'B'}, refs: {code: [0x0000, 0x0000, 0x0002]})

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x02,
          entries: [
            TestHelper.test_entry(address: 0x0000, length: 0x04, raw: "\x00\x01\x02\x03".bytes(), user_defined: { test: 'A'}, xrefs: {code: [0x0004, 0x0004]} ),
            TestHelper.test_entry(address: 0x0004, length: 0x04, raw: "\x04\x05\x06\x07".bytes(), user_defined: { test: 'B'}, refs: {code: [0x0000, 0x0000, 0x0002]} ),
          ]
        }
        assert_equal(expected, result)
      end

      def test_multiple_refs()
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0004, user_defined: { test: 'A'}, refs: {code: [0x0004, 0x0008, 0x0009]})
        _test_define(workspace: @workspace, address: 0x0004, length: 0x0004, user_defined: { test: 'B'}, refs: {})
        _test_define(workspace: @workspace, address: 0x0008, length: 0x0004, user_defined: { test: 'C'}, refs: {})

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x03,
          entries: [
            TestHelper.test_entry(address: 0x0000, length: 0x04, raw: "\x00\x01\x02\x03".bytes(), user_defined: { test: 'A'}, refs: {code: [0x0004, 0x0008, 0x0009]} ),
            TestHelper.test_entry(address: 0x0004, length: 0x04, raw: "\x04\x05\x06\x07".bytes(), user_defined: { test: 'B'}, xrefs: {code: [0x0000]}),
            TestHelper.test_entry(address: 0x0008, length: 0x04, raw: "\x08\x09\x0a\x0b".bytes(), user_defined: { test: 'C'}, xrefs: {code: [0x0000]}),
          ]
        }
        assert_equal(expected, result)
      end

      def test_multiple_xrefs()
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0004, user_defined: { test: 'A'}, refs: {code: [0x0004, 0x0008, 0x0009]})
        _test_define(workspace: @workspace, address: 0x0004, length: 0x0004, user_defined: { test: 'B'}, refs: {code: [0x0008]})
        _test_define(workspace: @workspace, address: 0x0008, length: 0x0004, user_defined: { test: 'C'}, refs: {})

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x03,
          entries: [
            TestHelper.test_entry(address: 0x0000, length: 0x04, raw: "\x00\x01\x02\x03".bytes(), user_defined: { test: 'A'}, refs: { code: [0x0004, 0x0008, 0x0009]} ),
            TestHelper.test_entry(address: 0x0004, length: 0x04, raw: "\x04\x05\x06\x07".bytes(), user_defined: { test: 'B'}, refs: { code: [0x0008] }, xrefs: {code: [0x0000]} ),
            TestHelper.test_entry(address: 0x0008, length: 0x04, raw: "\x08\x09\x0a\x0b".bytes(), user_defined: { test: 'C'}, xrefs: { code: [0x000, 0x0004] } ),
          ]
        }
        assert_equal(expected, result)
      end

      def test_self_ref()
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0004, user_defined: { test: 'A'}, refs: { code: [0x0000]})
        _test_define(workspace: @workspace, address: 0x0004, length: 0x0004, user_defined: { test: 'B'}, refs: { code: [0x0005]})

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x02,
          entries: [
            TestHelper.test_entry(address: 0x0000, length: 0x04, raw: "\x00\x01\x02\x03".bytes(), user_defined: { test: 'A'}, refs: { code: [0x0000] }, xrefs: { code: [0x0000]} ),
            TestHelper.test_entry(address: 0x0004, length: 0x04, raw: "\x04\x05\x06\x07".bytes(), user_defined: { test: 'B'}, refs: { code: [0x0005] }, xrefs: {} ),
          ]
        }
        assert_equal(expected, result)
      end

      def test_overwrite_self_ref()
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0004, user_defined: { test: 'A'}, refs: { code: [0x0000]})
        _test_define(workspace: @workspace, address: 0x0002, length: 0x0004, user_defined: { test: 'B'}, refs: { code: [0x0002]})

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x02,
          entries: [
            TestHelper.test_entry_deleted(address: 0x0000, raw: "\x00".bytes()),
            TestHelper.test_entry_deleted(address: 0x0001, raw: "\x01".bytes()),
            TestHelper.test_entry(address: 0x0002, length: 0x04, raw: "\x02\x03\x04\x05".bytes(), user_defined: { test: 'B'}, refs: { code: [0x0002] }, xrefs: { code: [0x0002]} ),
          ]
        }
        assert_equal(expected, result)
      end

      def test_delete_ref()
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0004, user_defined: { test: 'A'}, refs: {code: [0x0004, 0x0008, 0x0009]})
        _test_define(workspace: @workspace, address: 0x0004, length: 0x0004, user_defined: { test: 'B'}, refs: {code: [0x0000, 0x0002, 0x000a]})
        _test_define(workspace: @workspace, address: 0x0008, length: 0x0004, user_defined: { test: 'C'}, refs: {})

        _test_undefine(workspace: @workspace, address: 0x0000, length: 0x01)

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x04,
          entries: [
            TestHelper.test_entry_deleted(address: 0x0000, raw: "\x00".bytes(), xrefs: { code: [0x0004] }),
            TestHelper.test_entry_deleted(address: 0x0001, raw: "\x01".bytes()),
            TestHelper.test_entry_deleted(address: 0x0002, raw: "\x02".bytes(), xrefs: { code: [0x0004] }),
            TestHelper.test_entry_deleted(address: 0x0003, raw: "\x03".bytes()),
            TestHelper.test_entry(address: 0x0004, length: 0x04, raw: "\x04\x05\x06\x07".bytes(), user_defined: { test: 'B'}, refs: { code: [0x0000, 0x0002, 0x000a] }),
            TestHelper.test_entry(address: 0x0008, length: 0x04, raw: "\x08\x09\x0a\x0b".bytes(), user_defined: { test: 'C'}, refs: {} ),
          ]
        }
        assert_equal(expected, result)
      end

      def test_xref_after_undos_and_redos()
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0004, user_defined: { test: 'A'}, refs: { code: [0x0004, 0x0008, 0x0009]})
        _test_define(workspace: @workspace, address: 0x0004, length: 0x0004, user_defined: { test: 'B'}, refs: { code: [0x0000, 0x0002, 0x000a]})
        _test_define(workspace: @workspace, address: 0x0008, length: 0x0004, user_defined: { test: 'C'}, refs: { code: [0x0007]})
        _test_undefine(workspace: @workspace, address: 0x0000, length: 0x0001)

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x04,
          entries: [
            TestHelper.test_entry_deleted(address: 0x0000, raw: "\x00".bytes(), xrefs: { code: [0x04] }),
            TestHelper.test_entry_deleted(address: 0x0001, raw: "\x01".bytes()),
            TestHelper.test_entry_deleted(address: 0x0002, raw: "\x02".bytes(), xrefs: { code: [0x04] }),
            TestHelper.test_entry_deleted(address: 0x0003, raw: "\x03".bytes()),
            TestHelper.test_entry(address: 0x0004, length: 0x04, raw: "\x04\x05\x06\x07".bytes(), user_defined: { test: 'B'}, refs: { code: [0x0000, 0x0002, 0x000a] }),
            TestHelper.test_entry(address: 0x0008, length: 0x04, raw: "\x08\x09\x0a\x0b".bytes(), user_defined: { test: 'C'}, refs: { code: [0x0007] }),
          ]
        }
        assert_equal(expected, result)

        @workspace.undo()

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x05,
          entries: [
            TestHelper.test_entry(address: 0x0000, length: 0x04, raw: "\x00\x01\x02\x03".bytes(), user_defined: { test: 'A'}, refs: { code: [0x0004, 0x0008, 0x0009] }, xrefs: { code: [0x04] }),
            TestHelper.test_entry(address: 0x0004, length: 0x04, raw: "\x04\x05\x06\x07".bytes(), user_defined: { test: 'B'}, refs: { code: [0x0000, 0x0002, 0x000a] }, xrefs: { code: [0x00] }),
            TestHelper.test_entry(address: 0x0008, length: 0x04, raw: "\x08\x09\x0a\x0b".bytes(), user_defined: { test: 'C'}, refs: { code: [0x0007] }, xrefs: { code: [0x00] }),
          ]
        }
        assert_equal(expected, result)

        @workspace.undo()

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x06,
          entries: [
            TestHelper.test_entry(address: 0x0000, length: 0x04, raw: "\x00\x01\x02\x03".bytes(), user_defined: { test: 'A'}, refs: { code: [0x0004, 0x0008, 0x0009] }, xrefs: { code: [0x04] }),
            TestHelper.test_entry(address: 0x0004, length: 0x04, raw: "\x04\x05\x06\x07".bytes(), user_defined: { test: 'B'}, refs: { code: [0x0000, 0x0002, 0x000a] }, xrefs: { code: [0x00] }),
            TestHelper.test_entry_deleted(address: 0x0008, raw: "\x08".bytes(), xrefs: { code: [0x00] }),
            TestHelper.test_entry_deleted(address: 0x0009, raw: "\x09".bytes(), xrefs: { code: [0x00] }),
            TestHelper.test_entry_deleted(address: 0x000a, raw: "\x0a".bytes(), xrefs: { code: [0x04] }),
            TestHelper.test_entry_deleted(address: 0x000b, raw: "\x0b".bytes()),
          ]
        }
        assert_equal(expected, result)

        @workspace.undo()

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x07,
          entries: [
            TestHelper.test_entry(address: 0x0000, length: 0x04, raw: "\x00\x01\x02\x03".bytes(), user_defined: { test: 'A'}, refs: { code: [0x0004, 0x0008, 0x0009] }),
            TestHelper.test_entry_deleted(address: 0x0004, raw: "\x04".bytes(), xrefs: { code: [0x00] }),
            TestHelper.test_entry_deleted(address: 0x0005, raw: "\x05".bytes()),
            TestHelper.test_entry_deleted(address: 0x0006, raw: "\x06".bytes()),
            TestHelper.test_entry_deleted(address: 0x0007, raw: "\x07".bytes()),
            TestHelper.test_entry_deleted(address: 0x0008, raw: "\x08".bytes(), xrefs: { code: [0x00] }),
            TestHelper.test_entry_deleted(address: 0x0009, raw: "\x09".bytes(), xrefs: { code: [0x00] }),
            TestHelper.test_entry_deleted(address: 0x000a, raw: "\x0a".bytes()),
            TestHelper.test_entry_deleted(address: 0x000b, raw: "\x0b".bytes()),
          ]
        }
        assert_equal(expected, result)

        @workspace.undo()

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x08,
          entries: [
            TestHelper.test_entry_deleted(address: 0x0000, raw: "\x00".bytes()),
            TestHelper.test_entry_deleted(address: 0x0001, raw: "\x01".bytes()),
            TestHelper.test_entry_deleted(address: 0x0002, raw: "\x02".bytes()),
            TestHelper.test_entry_deleted(address: 0x0003, raw: "\x03".bytes()),
            TestHelper.test_entry_deleted(address: 0x0004, raw: "\x04".bytes()),
            TestHelper.test_entry_deleted(address: 0x0005, raw: "\x05".bytes()),
            TestHelper.test_entry_deleted(address: 0x0006, raw: "\x06".bytes()),
            TestHelper.test_entry_deleted(address: 0x0007, raw: "\x07".bytes()),
            TestHelper.test_entry_deleted(address: 0x0008, raw: "\x08".bytes()),
            TestHelper.test_entry_deleted(address: 0x0009, raw: "\x09".bytes()),
            TestHelper.test_entry_deleted(address: 0x000a, raw: "\x0a".bytes()),
            TestHelper.test_entry_deleted(address: 0x000b, raw: "\x0b".bytes()),
          ]
        }
        assert_equal(expected, result)

        @workspace.redo()

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x09,
          entries: [
            TestHelper.test_entry(address: 0x0000, length: 0x04, raw: "\x00\x01\x02\x03".bytes(), user_defined: { test: 'A'}, refs: { code: [0x0004, 0x0008, 0x0009] }),
            TestHelper.test_entry_deleted(address: 0x0004, raw: "\x04".bytes(), xrefs: { code: [0x00] }),
            TestHelper.test_entry_deleted(address: 0x0005, raw: "\x05".bytes()),
            TestHelper.test_entry_deleted(address: 0x0006, raw: "\x06".bytes()),
            TestHelper.test_entry_deleted(address: 0x0007, raw: "\x07".bytes()),
            TestHelper.test_entry_deleted(address: 0x0008, raw: "\x08".bytes(), xrefs: { code: [0x00] }),
            TestHelper.test_entry_deleted(address: 0x0009, raw: "\x09".bytes(), xrefs: { code: [0x00] }),
            TestHelper.test_entry_deleted(address: 0x000a, raw: "\x0a".bytes()),
            TestHelper.test_entry_deleted(address: 0x000b, raw: "\x0b".bytes()),
          ]
        }
        assert_equal(expected, result)

        @workspace.redo()

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x0a,
          entries: [
            TestHelper.test_entry(address: 0x0000, length: 0x04, raw: "\x00\x01\x02\x03".bytes(), user_defined: { test: 'A'}, refs: { code: [0x0004, 0x0008, 0x0009] }, xrefs: { code: [0x04] }),
            TestHelper.test_entry(address: 0x0004, length: 0x04, raw: "\x04\x05\x06\x07".bytes(), user_defined: { test: 'B'}, refs: { code: [0x0000, 0x0002, 0x000a] }, xrefs: { code: [0x00] }),
            TestHelper.test_entry_deleted(address: 0x0008, raw: "\x08".bytes(), xrefs: { code: [0x00] }),
            TestHelper.test_entry_deleted(address: 0x0009, raw: "\x09".bytes(), xrefs: { code: [0x00] }),
            TestHelper.test_entry_deleted(address: 0x000a, raw: "\x0a".bytes(), xrefs: { code: [0x04] }),
            TestHelper.test_entry_deleted(address: 0x000b, raw: "\x0b".bytes()),
          ]
        }
        assert_equal(expected, result)

        @workspace.redo()

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x0b,
          entries: [
            TestHelper.test_entry(address: 0x0000, length: 0x04, raw: "\x00\x01\x02\x03".bytes(), user_defined: { test: 'A'}, refs: { code: [0x0004, 0x0008, 0x0009] }, xrefs: { code: [0x04] }),
            TestHelper.test_entry(address: 0x0004, length: 0x04, raw: "\x04\x05\x06\x07".bytes(), user_defined: { test: 'B'}, refs: { code: [0x0000, 0x0002, 0x000a] }, xrefs: { code: [0x00] }),
            TestHelper.test_entry(address: 0x0008, length: 0x04, raw: "\x08\x09\x0a\x0b".bytes(), user_defined: { test: 'C'}, refs: { code: [0x0007] }, xrefs: { code: [0x00] }),
          ]
        }
        assert_equal(expected, result)

        @workspace.redo()

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x0c,
          entries: [
            TestHelper.test_entry_deleted(address: 0x0000, raw: "\x00".bytes(), xrefs: { code: [0x04] }),
            TestHelper.test_entry_deleted(address: 0x0001, raw: "\x01".bytes()),
            TestHelper.test_entry_deleted(address: 0x0002, raw: "\x02".bytes(), xrefs: { code: [0x04] }),
            TestHelper.test_entry_deleted(address: 0x0003, raw: "\x03".bytes()),
            TestHelper.test_entry(address: 0x0004, length: 0x04, raw: "\x04\x05\x06\x07".bytes(), user_defined: { test: 'B'}, refs: { code: [0x0000, 0x0002, 0x000a] }),
            TestHelper.test_entry(address: 0x0008, length: 0x04, raw: "\x08\x09\x0a\x0b".bytes(), user_defined: { test: 'C'}, refs: { code: [0x0007] }),
          ]
        }
        assert_equal(expected, result)
      end

      def test_xref_with_since()
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0004, user_defined: { test: 'A'}, refs: {code: [0x0004, 0x0005]})
        _test_define(workspace: @workspace, address: 0x0004, length: 0x0004, user_defined: { test: 'B'}, refs: {code: [0x0004]})
        _test_define(workspace: @workspace, address: 0x0005, length: 0x0004, user_defined: { test: 'C'}, refs: {code: [0x0005, 0x000a]})

        result = @workspace.get(address: 0x00, length: 0x10, since: 0)
        expected = {
          revision: 0x03,
          entries: [
            TestHelper.test_entry(address: 0x0000, length: 0x04, raw: "\x00\x01\x02\x03".bytes(), user_defined: { test: 'A'}, refs: { code: [0x0004, 0x0005] }),
            TestHelper.test_entry_deleted(address: 0x0004, raw: "\x04".bytes(), xrefs: { code: [0x00] }),
            TestHelper.test_entry(address: 0x0005, length: 0x04, raw: "\x05\x06\x07\x08".bytes(), user_defined: { test: 'C'}, refs: { code: [0x0005, 0x000a] }, xrefs: { code: [0x0000, 0x0005] }),
            TestHelper.test_entry_deleted(address: 0x000a, raw: "\x0a".bytes(), xrefs: { code: [0x0005] }),
          ]
        }
        assert_equal(expected, result)

        result = @workspace.get(address: 0x00, length: 0x10, since: 1)
        expected = {
          revision: 0x03,
          entries: [
            TestHelper.test_entry_deleted(address: 0x0004, raw: "\x04".bytes(), xrefs: { code: [0x00] }),
            TestHelper.test_entry(address: 0x0005, length: 0x04, raw: "\x05\x06\x07\x08".bytes(), user_defined: { test: 'C'}, refs: { code: [0x0005, 0x000a] }, xrefs: { code: [0x0000, 0x0005] }),
            TestHelper.test_entry_deleted(address: 0x000a, raw: "\x0a".bytes(), xrefs: { code: [0x0005] }),
          ]
        }
        assert_equal(expected, result)

        result = @workspace.get(address: 0x00, length: 0x10, since: 2)
        expected = {
          revision: 0x03,
          entries: [
            TestHelper.test_entry_deleted(address: 0x0004, raw: "\x04".bytes(), xrefs: { code: [0x00] }),
            TestHelper.test_entry(address: 0x0005, length: 0x04, raw: "\x05\x06\x07\x08".bytes(), user_defined: { test: 'C'}, refs: { code: [0x0005, 0x000a] }, xrefs: { code: [0x0000, 0x0005] }),
            TestHelper.test_entry_deleted(address: 0x000a, raw: "\x0a".bytes(), xrefs: { code: [0x0005] }),
          ]
        }
        assert_equal(expected, result)

        @workspace.undo()
        @workspace.undo()
        @workspace.undo()

        result = @workspace.get(address: 0x00, length: 0x10, since: 3)
        expected = {
          revision: 0x06,
          entries: [
            TestHelper.test_entry_deleted(address: 0x0000, raw: "\x00".bytes()),
            TestHelper.test_entry_deleted(address: 0x0001, raw: "\x01".bytes()),
            TestHelper.test_entry_deleted(address: 0x0002, raw: "\x02".bytes()),
            TestHelper.test_entry_deleted(address: 0x0003, raw: "\x03".bytes()),
            TestHelper.test_entry_deleted(address: 0x0004, raw: "\x04".bytes()),
            TestHelper.test_entry_deleted(address: 0x0005, raw: "\x05".bytes()),
            TestHelper.test_entry_deleted(address: 0x0006, raw: "\x06".bytes()),
            TestHelper.test_entry_deleted(address: 0x0007, raw: "\x07".bytes()),
            TestHelper.test_entry_deleted(address: 0x0008, raw: "\x08".bytes()),
            TestHelper.test_entry_deleted(address: 0x000a, raw: "\x0a".bytes()),
          ]
        }
        assert_equal(expected, result)

        result = @workspace.get(address: 0x00, length: 0x10, since: 4)
        expected = {
          revision: 0x06,
          entries: [
            TestHelper.test_entry_deleted(address: 0x0000, raw: "\x00".bytes()),
            TestHelper.test_entry_deleted(address: 0x0001, raw: "\x01".bytes()),
            TestHelper.test_entry_deleted(address: 0x0002, raw: "\x02".bytes()),
            TestHelper.test_entry_deleted(address: 0x0003, raw: "\x03".bytes()),
            TestHelper.test_entry_deleted(address: 0x0004, raw: "\x04".bytes()),
            TestHelper.test_entry_deleted(address: 0x0005, raw: "\x05".bytes()),
            TestHelper.test_entry_deleted(address: 0x0006, raw: "\x06".bytes()),
            TestHelper.test_entry_deleted(address: 0x0007, raw: "\x07".bytes()),
          ]
        }
        assert_equal(expected, result)

        result = @workspace.get(address: 0x00, length: 0x10, since: 5)
        expected = {
          revision: 0x06,
          entries: [
            TestHelper.test_entry_deleted(address: 0x0000, raw: "\x00".bytes()),
            TestHelper.test_entry_deleted(address: 0x0001, raw: "\x01".bytes()),
            TestHelper.test_entry_deleted(address: 0x0002, raw: "\x02".bytes()),
            TestHelper.test_entry_deleted(address: 0x0003, raw: "\x03".bytes()),
            TestHelper.test_entry_deleted(address: 0x0004, raw: "\x04".bytes()),
            TestHelper.test_entry_deleted(address: 0x0005, raw: "\x05".bytes()),
          ]
        }
        assert_equal(expected, result)

        @workspace.redo()
        @workspace.redo()
        @workspace.redo()

        result = @workspace.get(address: 0x00, length: 0x10, since: 6)
        expected = {
          revision: 0x09,
          entries: [
            TestHelper.test_entry(address: 0x0000, length: 0x04, raw: "\x00\x01\x02\x03".bytes(), user_defined: { test: 'A'}, refs: { code: [0x0004, 0x0005] }),
            TestHelper.test_entry_deleted(address: 0x0004, raw: "\x04".bytes(), xrefs: { code: [0x00] }),
            TestHelper.test_entry(address: 0x0005, length: 0x04, raw: "\x05\x06\x07\x08".bytes(), user_defined: { test: 'C'}, refs: { code: [0x0005, 0x000a] }, xrefs: { code: [0x0000, 0x0005] }),
            TestHelper.test_entry_deleted(address: 0x000a, raw: "\x0a".bytes(), xrefs: { code: [0x0005] }),
          ]
        }
        assert_equal(expected, result)

        result = @workspace.get(address: 0x00, length: 0x10, since: 7)
        expected = {
          revision: 0x09,
          entries: [
            TestHelper.test_entry_deleted(address: 0x0004, raw: "\x04".bytes(), xrefs: { code: [0x00] }),
            TestHelper.test_entry(address: 0x0005, length: 0x04, raw: "\x05\x06\x07\x08".bytes(), user_defined: { test: 'C'}, refs: { code: [0x0005, 0x000a] }, xrefs: { code: [0x0000, 0x0005] }),
            TestHelper.test_entry_deleted(address: 0x000a, raw: "\x0a".bytes(), xrefs: { code: [0x0005] }),
          ]
        }
        assert_equal(expected, result)

        result = @workspace.get(address: 0x00, length: 0x10, since: 8)
        expected = {
          revision: 0x09,
          entries: [
            TestHelper.test_entry_deleted(address: 0x0004, raw: "\x04".bytes(), xrefs: { code: [0x00] }),
            TestHelper.test_entry(address: 0x0005, length: 0x04, raw: "\x05\x06\x07\x08".bytes(), user_defined: { test: 'C'}, refs: { code: [0x0005, 0x000a] }, xrefs: { code: [0x0000, 0x0005] }),
            TestHelper.test_entry_deleted(address: 0x000a, raw: "\x0a".bytes(), xrefs: { code: [0x0005] }),
          ]
        }
        assert_equal(expected, result)
      end

      def test_add_refs()
       _test_define(workspace: @workspace, address: 0x0000, length: 0x0004, user_defined: { test: 'A'})
       _test_define(workspace: @workspace, address: 0x0004, length: 0x0004, user_defined: { test: 'B'})
       @workspace.transaction do
         @workspace.add_refs(type: :code, from: 0x0004, tos: [0x0000])
       end

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x03,
          entries: [
            TestHelper.test_entry(address: 0x0000, length: 0x04, raw: "\x00\x01\x02\x03".bytes(), user_defined: { test: 'A'}, xrefs: {code: [0x0004]} ),
            TestHelper.test_entry(address: 0x0004, length: 0x04, raw: "\x04\x05\x06\x07".bytes(), user_defined: { test: 'B'}, refs: {code: [0x0000]} ),
          ]
        }
        assert_equal(expected, result)
      end

      def test_remove_refs()
       _test_define(workspace: @workspace, address: 0x0000, length: 0x0004, user_defined: { test: 'A'})
       _test_define(workspace: @workspace, address: 0x0004, length: 0x0004, user_defined: { test: 'B'}, refs: { code: [0x0000]} )
       @workspace.transaction do
         @workspace.remove_refs(type: :code, from: 0x0004, tos: [0x0000])
       end

        result = @workspace.get(address: 0x00, length: 0xFF, since: 0)
        expected = {
          revision: 0x03,
          entries: [
            TestHelper.test_entry(address: 0x0000, length: 0x04, raw: "\x00\x01\x02\x03".bytes(), user_defined: { test: 'A'}, xrefs: {} ),
            TestHelper.test_entry(address: 0x0004, length: 0x04, raw: "\x04\x05\x06\x07".bytes(), user_defined: { test: 'B'}, refs: {} ),
          ]
        }
        assert_equal(expected, result)
      end
    end

    class SaveRestoreTest < Test::Unit::TestCase
      def test_save_load()
        workspace = Workspace.new(raw: RAW)

        _test_define(workspace: workspace, address: 0x0000, length: 0x0004, user_defined: { test: 'A'}, refs: { code: [0x0004, 0x0005] })
        _test_define(workspace: workspace, address: 0x0004, length: 0x0004, user_defined: { test: 'B'}, refs: { code: [0x0004] })
        _test_define(workspace: workspace, address: 0x0005, length: 0x0004, user_defined: { test: 'C'}, refs: { code: [0x0005, 0x000a] })

        # Save/load throughout this function to make sure it's working right
        workspace = Workspace.load(workspace.dump())
        assert_not_nil(workspace)

        result = workspace.get(address: 0x00, length: 0x10, since: 0)
        expected = {
          revision: 0x03,
          entries: [
            TestHelper.test_entry(address: 0x0000, length: 0x04, raw: "\x00\x01\x02\x03".bytes(), user_defined: { test: 'A'}, refs: { code: [0x0004, 0x0005] }),
            TestHelper.test_entry_deleted(address: 0x0004, raw: "\x04".bytes(), xrefs: { code: [0x00] }),
            TestHelper.test_entry(address: 0x0005, length: 0x04, raw: "\x05\x06\x07\x08".bytes(), user_defined: { test: 'C'}, refs: { code: [0x0005, 0x000a] }, xrefs: { code: [0x0000, 0x0005] }),
            TestHelper.test_entry_deleted(address: 0x000a, raw: "\x0a".bytes(), xrefs: { code: [0x0005] }),
          ]
        }
        assert_equal(expected, result)

        result = workspace.get(address: 0x00, length: 0x10, since: 1)
        expected = {
          revision: 0x03,
          entries: [
            TestHelper.test_entry_deleted(address: 0x0004, raw: "\x04".bytes(), xrefs: { code: [0x00] }),
            TestHelper.test_entry(address: 0x0005, length: 0x04, raw: "\x05\x06\x07\x08".bytes(), user_defined: { test: 'C'}, refs: { code: [0x0005, 0x000a] }, xrefs: { code: [0x0000, 0x0005] }),
            TestHelper.test_entry_deleted(address: 0x000a, raw: "\x0a".bytes(), xrefs: { code: [0x0005] }),
          ]
        }
        assert_equal(expected, result)

        result = workspace.get(address: 0x00, length: 0x10, since: 2)
        expected = {
          revision: 0x03,
          entries: [
            TestHelper.test_entry_deleted(address: 0x0004, raw: "\x04".bytes(), xrefs: { code: [0x00] }),
            TestHelper.test_entry(address: 0x0005, length: 0x04, raw: "\x05\x06\x07\x08".bytes(), user_defined: { test: 'C'}, refs: { code: [0x0005, 0x000a] }, xrefs: { code: [0x0000, 0x0005] }),
            TestHelper.test_entry_deleted(address: 0x000a, raw: "\x0a".bytes(), xrefs: { code: [0x0005] }),
          ]
        }
        assert_equal(expected, result)

        workspace.undo()
        workspace.undo()
        workspace.undo()

        result = workspace.get(address: 0x00, length: 0x10, since: 3)
        expected = {
          revision: 0x06,
          entries: [
            TestHelper.test_entry_deleted(address: 0x0000, raw: "\x00".bytes()),
            TestHelper.test_entry_deleted(address: 0x0001, raw: "\x01".bytes()),
            TestHelper.test_entry_deleted(address: 0x0002, raw: "\x02".bytes()),
            TestHelper.test_entry_deleted(address: 0x0003, raw: "\x03".bytes()),
            TestHelper.test_entry_deleted(address: 0x0004, raw: "\x04".bytes()),
            TestHelper.test_entry_deleted(address: 0x0005, raw: "\x05".bytes()),
            TestHelper.test_entry_deleted(address: 0x0006, raw: "\x06".bytes()),
            TestHelper.test_entry_deleted(address: 0x0007, raw: "\x07".bytes()),
            TestHelper.test_entry_deleted(address: 0x0008, raw: "\x08".bytes()),
            TestHelper.test_entry_deleted(address: 0x000a, raw: "\x0a".bytes()),
          ]
        }
        assert_equal(expected, result)

        result = workspace.get(address: 0x00, length: 0x10, since: 4)
        expected = {
          revision: 0x06,
          entries: [
            TestHelper.test_entry_deleted(address: 0x0000, raw: "\x00".bytes()),
            TestHelper.test_entry_deleted(address: 0x0001, raw: "\x01".bytes()),
            TestHelper.test_entry_deleted(address: 0x0002, raw: "\x02".bytes()),
            TestHelper.test_entry_deleted(address: 0x0003, raw: "\x03".bytes()),
            TestHelper.test_entry_deleted(address: 0x0004, raw: "\x04".bytes()),
            TestHelper.test_entry_deleted(address: 0x0005, raw: "\x05".bytes()),
            TestHelper.test_entry_deleted(address: 0x0006, raw: "\x06".bytes()),
            TestHelper.test_entry_deleted(address: 0x0007, raw: "\x07".bytes()),
          ]
        }
        assert_equal(expected, result)

        result = workspace.get(address: 0x00, length: 0x10, since: 5)
        expected = {
          revision: 0x06,
          entries: [
            TestHelper.test_entry_deleted(address: 0x0000, raw: "\x00".bytes()),
            TestHelper.test_entry_deleted(address: 0x0001, raw: "\x01".bytes()),
            TestHelper.test_entry_deleted(address: 0x0002, raw: "\x02".bytes()),
            TestHelper.test_entry_deleted(address: 0x0003, raw: "\x03".bytes()),
            TestHelper.test_entry_deleted(address: 0x0004, raw: "\x04".bytes()),
            TestHelper.test_entry_deleted(address: 0x0005, raw: "\x05".bytes()),
          ]
        }
        assert_equal(expected, result)

        workspace.redo()
        workspace.redo()
        workspace.redo()

        result = workspace.get(address: 0x00, length: 0x10, since: 6)
        expected = {
          revision: 0x09,
          entries: [
            TestHelper.test_entry(address: 0x0000, length: 0x04, raw: "\x00\x01\x02\x03".bytes(), user_defined: { test: 'A'}, refs: { code: [0x0004, 0x0005] }),
            TestHelper.test_entry_deleted(address: 0x0004, raw: "\x04".bytes(), xrefs: { code: [0x00] }),
            TestHelper.test_entry(address: 0x0005, length: 0x04, raw: "\x05\x06\x07\x08".bytes(), user_defined: { test: 'C'}, refs: { code: [0x0005, 0x000a] }, xrefs: { code: [0x0000, 0x0005] }),
            TestHelper.test_entry_deleted(address: 0x000a, raw: "\x0a".bytes(), xrefs: { code: [0x0005] }),
          ]
        }
        assert_equal(expected, result)

        result = workspace.get(address: 0x00, length: 0x10, since: 7)
        expected = {
          revision: 0x09,
          entries: [
            TestHelper.test_entry_deleted(address: 0x0004, raw: "\x04".bytes(), xrefs: { code: [0x00] }),
            TestHelper.test_entry(address: 0x0005, length: 0x04, raw: "\x05\x06\x07\x08".bytes(), user_defined: { test: 'C'}, refs: { code: [0x0005, 0x000a] }, xrefs: { code: [0x0000, 0x0005] }),
            TestHelper.test_entry_deleted(address: 0x000a, raw: "\x0a".bytes(), xrefs: { code: [0x0005] }),
          ]
        }
        assert_equal(expected, result)

        result = workspace.get(address: 0x00, length: 0x10, since: 8)
        expected = {
          revision: 0x09,
          entries: [
            TestHelper.test_entry_deleted(address: 0x0004, raw: "\x04".bytes(), xrefs: { code: [0x00] }),
            TestHelper.test_entry(address: 0x0005, length: 0x04, raw: "\x05\x06\x07\x08".bytes(), user_defined: { test: 'C'}, refs: { code: [0x0005, 0x000a] }, xrefs: { code: [0x0000, 0x0005] }),
            TestHelper.test_entry_deleted(address: 0x000a, raw: "\x0a".bytes(), xrefs: { code: [0x0005] }),
          ]
        }
        assert_equal(expected, result)
      end

      def test_bad_load()
        assert_raises(Error) do
          Workspace.load("Not valid YAML")
        end
      end
    end

    class UserDefinedTest < Test::Unit::TestCase
      def setup()
        @workspace = Workspace.new(raw: RAW)
      end

      def test_replace()
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0004, user_defined: { test: "A" })

        result = @workspace.get(address: 0x00, length: 0x01, since:0)
        expected = {
          revision: 0x01,
          entries: [
            TestHelper.test_entry(address: 0x00, length: 0x04, raw: "\x00\x01\x02\x03".bytes(), user_defined: { test: "A" })
          ]
        }
        assert_equal(expected, result)

        @workspace.transaction() do
          @workspace.replace_user_defined(address: 0x0000, user_defined: { test2: "B" })
        end

        result = @workspace.get(address: 0x00, length: 0x01, since:0)
        expected = {
          revision: 0x02,
          entries: [
            TestHelper.test_entry(address: 0x00, length: 0x04, raw: "\x00\x01\x02\x03".bytes(), user_defined: { test2: "B" })
          ]
        }
        assert_equal(expected, result)
      end

      def test_update()
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0004, user_defined: { test: "A" })

        result = @workspace.get(address: 0x00, length: 0x01, since:0)
        expected = {
          revision: 0x01,
          entries: [
            TestHelper.test_entry(address: 0x00, length: 0x04, raw: "\x00\x01\x02\x03".bytes(), user_defined: { test: "A" })
          ]
        }
        assert_equal(expected, result)

        @workspace.transaction() do
          @workspace.update_user_defined(address: 0x0000, user_defined: { test2: "B" })
        end

        result = @workspace.get(address: 0x00, length: 0x01, since:0)
        expected = {
          revision: 0x02,
          entries: [
            TestHelper.test_entry(address: 0x00, length: 0x04, raw: "\x00\x01\x02\x03".bytes(), user_defined: { test: "A", test2: "B" })
          ]
        }
        assert_equal(expected, result)
      end

      def test_replace_undo_redo()
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0004, user_defined: { test: "A" })

        result = @workspace.get(address: 0x00, length: 0x01, since:0)
        expected = {
          revision: 0x01,
          entries: [
            TestHelper.test_entry(address: 0x00, length: 0x04, raw: "\x00\x01\x02\x03".bytes(), user_defined: { test: "A" })
          ]
        }
        assert_equal(expected, result)

        @workspace.transaction() do
          @workspace.replace_user_defined(address: 0x0000, user_defined: { test2: "B" })
        end

        result = @workspace.get(address: 0x00, length: 0x01, since:0)
        expected = {
          revision: 0x02,
          entries: [
            TestHelper.test_entry(address: 0x00, length: 0x04, raw: "\x00\x01\x02\x03".bytes(), user_defined: { test2: "B" })
          ]
        }
        assert_equal(expected, result)

        @workspace.undo()

        result = @workspace.get(address: 0x00, length: 0x01, since:0)
        expected = {
          revision: 0x03,
          entries: [
            TestHelper.test_entry(address: 0x00, length: 0x04, raw: "\x00\x01\x02\x03".bytes(), user_defined: { test: "A" })
          ]
        }
        assert_equal(expected, result)

        @workspace.redo()

        result = @workspace.get(address: 0x00, length: 0x01, since:0)
        expected = {
          revision: 0x04,
          entries: [
            TestHelper.test_entry(address: 0x00, length: 0x04, raw: "\x00\x01\x02\x03".bytes(), user_defined: { test2: "B" })
          ]
        }
        assert_equal(expected, result)
      end

      def test_update_undo_redo()
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0004, user_defined: { test: "A" })

        result = @workspace.get(address: 0x00, length: 0x01, since:0)
        expected = {
          revision: 0x01,
          entries: [
            TestHelper.test_entry(address: 0x00, length: 0x04, raw: "\x00\x01\x02\x03".bytes(), user_defined: { test: "A" })
          ]
        }
        assert_equal(expected, result)

        @workspace.transaction() do
          @workspace.update_user_defined(address: 0x0000, user_defined: { test2: "B" })
        end

        result = @workspace.get(address: 0x00, length: 0x01, since:0)
        expected = {
          revision: 0x02,
          entries: [
            TestHelper.test_entry(address: 0x00, length: 0x04, raw: "\x00\x01\x02\x03".bytes(), user_defined: { test: "A", test2: "B" })
          ]
        }
        assert_equal(expected, result)

        @workspace.undo()

        result = @workspace.get(address: 0x00, length: 0x01, since:0)
        expected = {
          revision: 0x03,
          entries: [
            TestHelper.test_entry(address: 0x00, length: 0x04, raw: "\x00\x01\x02\x03".bytes(), user_defined: { test: "A" })
          ]
        }
        assert_equal(expected, result)

        @workspace.redo()

        result = @workspace.get(address: 0x00, length: 0x01, since:0)
        expected = {
          revision: 0x04,
          entries: [
            TestHelper.test_entry(address: 0x00, length: 0x04, raw: "\x00\x01\x02\x03".bytes(), user_defined: { test: "A", test2: "B" })
          ]
        }
        assert_equal(expected, result)
      end

      def test_update_since()
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0004, user_defined: { test: "A" })
        _test_define(workspace: @workspace, address: 0x0004, length: 0x0004, user_defined: { test2: "B" })

        result = @workspace.get(address: 0x00, length: 0xFF, since:0)
        expected = {
          revision: 0x02,
          entries: [
            TestHelper.test_entry(address: 0x00, length: 0x04, raw: "\x00\x01\x02\x03".bytes(), user_defined: { test: "A" }),
            TestHelper.test_entry(address: 0x04, length: 0x04, raw: "\x04\x05\x06\x07".bytes(), user_defined: { test2: "B" }),
          ]
        }
        assert_equal(expected, result)

        result = @workspace.get(address: 0x00, length: 0xFF, since:0x02)
        expected = {
          revision: 0x02,
          entries: [
          ]
        }
        assert_equal(expected, result)

        @workspace.transaction() do
          @workspace.replace_user_defined(address: 0x0000, user_defined: { test3: "C" })
        end

        result = @workspace.get(address: 0x00, length: 0xFF, since:0x02)
        expected = {
          revision: 0x03,
          entries: [
            TestHelper.test_entry(address: 0x00, length: 0x04, raw: "\x00\x01\x02\x03".bytes(), user_defined: { test3: "C" }),
          ]
        }
        assert_equal(expected, result)

        @workspace.transaction() do
          @workspace.update_user_defined(address: 0x0004, user_defined: { test4: "D" })
        end

        result = @workspace.get(address: 0x00, length: 0xFF, since:0x03)
        expected = {
          revision: 0x04,
          entries: [
            TestHelper.test_entry(address: 0x04, length: 0x04, raw: "\x04\x05\x06\x07".bytes(), user_defined: { test2: "B", test4: "D" }),
          ]
        }
        assert_equal(expected, result)
      end

      def test_replace_with_non_hash()
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0004, user_defined: { test: "A" })

        @workspace.transaction() do
          assert_raises(Error) do
            @workspace.replace_user_defined(address: 0x0000, user_defined: "hi")
          end
        end
      end

      def test_replace_in_middle()
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0004, user_defined: { test: "A" })

        result = @workspace.get(address: 0x00, length: 0x01, since:0)
        expected = {
          revision: 0x01,
          entries: [
            TestHelper.test_entry(address: 0x00, length: 0x04, raw: "\x00\x01\x02\x03".bytes(), user_defined: { test: "A" })
          ]
        }
        assert_equal(expected, result)

        @workspace.transaction() do
          @workspace.replace_user_defined(address: 0x0002, user_defined: { test2: "B" })
        end

        result = @workspace.get(address: 0x00, length: 0x01, since:0)
        expected = {
          revision: 0x02,
          entries: [
            TestHelper.test_entry(address: 0x00, length: 0x04, raw: "\x00\x01\x02\x03".bytes(), user_defined: { test2: "B" })
          ]
        }
        assert_equal(expected, result)
      end

      def test_replace_no_entry()
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0004, user_defined: { test: "A" })

        @workspace.transaction() do
          @workspace.replace_user_defined(address: 0x0008, user_defined: { test2: "B" })
        end

        result = @workspace.get(address: 0x00, length: 0xFF, since:0)
        expected = {
          revision: 0x02,
          entries: [
            TestHelper.test_entry(address: 0x00, length: 0x04, raw: "\x00\x01\x02\x03".bytes(), user_defined: { test: "A" }),
            TestHelper.test_entry(address: 0x08, length: 0x01, type: :uint8_t, raw: "\x08".bytes(), user_defined: { test2: "B" }, comment: nil, value: 8),
          ]
        }
        assert_equal(expected, result)

        @workspace.undo()

        result = @workspace.get(address: 0x00, length: 0xFF, since:0)
        expected = {
          revision: 0x03,
          entries: [
            TestHelper.test_entry(address: 0x00, length: 0x04, raw: "\x00\x01\x02\x03".bytes(), user_defined: { test: "A" }),
            TestHelper.test_entry_deleted(address: 0x08, raw: "\x08".bytes()),
          ]
        }
        assert_equal(expected, result)

        @workspace.redo()

        result = @workspace.get(address: 0x00, length: 0xFF, since:0)
        expected = {
          revision: 0x04,
          entries: [
            TestHelper.test_entry(address: 0x00, length: 0x04, raw: "\x00\x01\x02\x03".bytes(), user_defined: { test: "A" }),
            TestHelper.test_entry(address: 0x08, length: 0x01, type: :uint8_t, raw: "\x08".bytes(), user_defined: { test2: "B" }, comment: nil, value: 8),
          ]
        }
        assert_equal(expected, result)
      end

      def test_update_no_entry()
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0004, user_defined: { test: "A" })

        @workspace.transaction() do
          @workspace.update_user_defined(address: 0x0008, user_defined: { test2: "B" })
        end

        result = @workspace.get(address: 0x00, length: 0xFF, since:0)
        expected = {
          revision: 0x02,
          entries: [
            TestHelper.test_entry(address: 0x00, length: 0x04, raw: "\x00\x01\x02\x03".bytes(), user_defined: { test: "A" }),
            TestHelper.test_entry(address: 0x08, length: 0x01, type: :uint8_t, raw: "\x08".bytes(), user_defined: { test2: "B" }, comment: nil, value: 8),
          ]
        }
        assert_equal(expected, result)

        @workspace.undo()

        result = @workspace.get(address: 0x00, length: 0xFF, since:0)
        expected = {
          revision: 0x03,
          entries: [
            TestHelper.test_entry(address: 0x00, length: 0x04, raw: "\x00\x01\x02\x03".bytes(), user_defined: { test: "A" }),
            TestHelper.test_entry_deleted(address: 0x08, raw: "\x08".bytes()),
          ]
        }
        assert_equal(expected, result)

        @workspace.redo()

        result = @workspace.get(address: 0x00, length: 0xFF, since:0)
        expected = {
          revision: 0x04,
          entries: [
            TestHelper.test_entry(address: 0x00, length: 0x04, raw: "\x00\x01\x02\x03".bytes(), user_defined: { test: "A" }),
            TestHelper.test_entry(address: 0x08, length: 0x01, type: :uint8_t, raw: "\x08".bytes(), user_defined: { test2: "B" }, comment: nil, value: 8),
          ]
        }
        assert_equal(expected, result)
      end
    end

    class ChangeCommentTest < Test::Unit::TestCase
      def setup()
        @workspace = Workspace.new(raw: RAW)
      end

      def test_set_comment()
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0001, comment: nil)
        @workspace.transaction() do
          @workspace.set_comment(address: 0x0000, comment: 'blahblah')
        end

        result = @workspace.get(address: 0x00, length: 0x01, since:0)
        expected = {
          revision: 0x02,
          entries: [
            TestHelper.test_entry(address: 0x00, length: 0x01, raw: [0x00], comment: 'blahblah')
          ]
        }

        assert_equal(expected, result)
      end

      def test_change_comment()
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0001, comment: 'hihi')
        @workspace.transaction() do
          @workspace.set_comment(address: 0x0000, comment: 'blahblah')
        end

        result = @workspace.get(address: 0x00, length: 0x01, since:0)
        expected = {
          revision: 0x02,
          entries: [
            TestHelper.test_entry(address: 0x00, length: 0x01, raw: [0x00], comment: 'blahblah')
          ]
        }

        assert_equal(expected, result)
      end

      def test_remove_comment()
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0001, comment: 'hihi')
        @workspace.transaction() do
          @workspace.set_comment(address: 0x0000, comment: nil)
        end

        result = @workspace.get(address: 0x00, length: 0x01, since:0)
        expected = {
          revision: 0x02,
          entries: [
            TestHelper.test_entry(address: 0x00, length: 0x01, raw: [0x00], comment: nil)
          ]
        }

        assert_equal(expected, result)
      end

      def test_change_comment_undo_redo()
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0001, comment: 'hihi')
        @workspace.transaction() do
          @workspace.set_comment(address: 0x0000, comment: 'blahblah')
        end

        result = @workspace.get(address: 0x00, length: 0x01, since:0)
        expected = {
          revision: 0x02,
          entries: [
            TestHelper.test_entry(address: 0x00, length: 0x01, raw: [0x00], comment: 'blahblah')
          ]
        }
        assert_equal(expected, result)

        @workspace.undo()

        result = @workspace.get(address: 0x00, length: 0x01, since:0)
        expected = {
          revision: 0x03,
          entries: [
            TestHelper.test_entry(address: 0x00, length: 0x01, raw: [0x00], comment: 'hihi')
          ]
        }
        assert_equal(expected, result)

        @workspace.redo()

        result = @workspace.get(address: 0x00, length: 0x01, since:0)
        expected = {
          revision: 0x04,
          entries: [
            TestHelper.test_entry(address: 0x00, length: 0x01, raw: [0x00], comment: 'blahblah')
          ]
        }
        assert_equal(expected, result)
      end

      def test_add_comment_no_entry()
        @workspace.transaction() do
          @workspace.set_comment(address: 0x0000, comment: 'blahblah')
        end

        result = @workspace.get(address: 0x00, length: 0xFF, since:0)
        expected = {
          revision: 0x01,
          entries: [
            TestHelper.test_entry(address: 0x00, length: 0x01, type: :uint8_t, raw: "\x00".bytes(), comment: 'blahblah', value: 0, user_defined: {}),
          ]
        }
        assert_equal(expected, result)

        @workspace.undo()

        result = @workspace.get(address: 0x00, length: 0xFF, since:0)
        expected = {
          revision: 0x02,
          entries: [
            TestHelper.test_entry_deleted(address: 0x00, raw: "\x00".bytes()),
          ]
        }
        assert_equal(expected, result)

        @workspace.redo()

        result = @workspace.get(address: 0x00, length: 0xFF, since:0)
        expected = {
          revision: 0x03,
          entries: [
            TestHelper.test_entry(address: 0x00, length: 0x01, type: :uint8_t, raw: "\x00".bytes(), comment: 'blahblah', value: 0, user_defined: {}),
          ]
        }
        assert_equal(expected, result)
      end

      def test_change_comment_updates_revision()
        _test_define(workspace: @workspace, address: 0x0000, length: 0x0001, comment: nil)
        @workspace.transaction() do
          @workspace.set_comment(address: 0x0000, comment: 'blahblah')
        end

        result = @workspace.get(address: 0x00, length: 0x01, since:1)
        expected = {
          revision: 0x02,
          entries: [
            TestHelper.test_entry(address: 0x00, length: 0x01, raw: [0x00], comment: 'blahblah')
          ]
        }

        assert_equal(expected, result)
      end
    end

    class CreateDeleteBlockTest < Test::Unit::TestCase
      def setup()
        @workspace = Workspace.new(hax_add_magic_block: false)
      end

      def test_create_block()
        @workspace.transaction() do
          @workspace.create_block(block_name: 'test', raw: RAW)
        end
        assert_equal(['test'], @workspace.get_block_names())

        _test_define(block_name: 'test', workspace: @workspace, address: 0x0000, length: 0x0001)

        result = @workspace.get(block_name: 'test', address: 0x00, length: 0x01, since:0)
        expected = {
          revision: 0x02,
          entries: [
            TestHelper.test_entry(address: 0x00, length: 0x01, raw: [0x00])
          ]
        }

        assert_equal(expected, result)
      end

      def test_create_multiple_blocks()
        @workspace.transaction() do
          @workspace.create_block(block_name: 'aaaa', raw: "A" * 16)
          @workspace.create_block(block_name: 'bbbb', raw: "B" * 16)
        end
        assert_equal(['aaaa', 'bbbb'], @workspace.get_block_names().sort())

        _test_define(block_name: 'aaaa', workspace: @workspace, address: 0x0000, length: 0x0001, comment: "a!!")
        _test_define(block_name: 'bbbb', workspace: @workspace, address: 0x0000, length: 0x0004, comment: "B!!")

        result = @workspace.get(block_name: 'aaaa', address: 0x00, length: 0x01, since:0)
        assert_equal('a!!', result[:entries][0][:comment])
        assert_equal('A'.bytes(), result[:entries][0][:raw])

        result = @workspace.get(block_name: 'bbbb', address: 0x00, length: 0x01, since:0)
        assert_equal('B!!', result[:entries][0][:comment])
        assert_equal('BBBB'.bytes(), result[:entries][0][:raw])
      end

      def test_delete_blocks()
        @workspace.transaction() do
          @workspace.create_block(block_name: 'aaaa', raw: "A" * 16)
          @workspace.create_block(block_name: 'bbbb', raw: "B" * 16)
        end
        assert_equal(['aaaa', 'bbbb'], @workspace.get_block_names().sort())

        @workspace.transaction() do
          @workspace.delete_block(block_name: 'aaaa')
        end
        assert_equal(['bbbb'], @workspace.get_block_names().sort())

        @workspace.transaction() do
          @workspace.delete_block(block_name: 'bbbb')
        end
        assert_equal([], @workspace.get_block_names().sort())
      end

      def test_undo_redo()
        @workspace.transaction() do
          @workspace.create_block(block_name: 'aaaa', raw: "A" * 16)
        end
        assert_equal(['aaaa'], @workspace.get_block_names().sort())

        @workspace.transaction() do
          @workspace.create_block(block_name: 'bbbb', raw: "B" * 16)
        end
        assert_equal(['aaaa', 'bbbb'], @workspace.get_block_names().sort())

        @workspace.transaction() do
          @workspace.delete_block(block_name: 'aaaa')
        end
        assert_equal(['bbbb'], @workspace.get_block_names().sort())

        @workspace.transaction() do
          @workspace.delete_block(block_name: 'bbbb')
        end
        assert_equal([], @workspace.get_block_names().sort())

        @workspace.undo()
        assert_equal(['bbbb'], @workspace.get_block_names().sort())

        @workspace.undo()
        assert_equal(['aaaa', 'bbbb'], @workspace.get_block_names().sort())

        @workspace.undo()
        assert_equal(['aaaa'], @workspace.get_block_names().sort())

        @workspace.undo()
        assert_equal([], @workspace.get_block_names().sort())
      end

      def test_undo_redo_with_entries()
        @workspace.transaction() do
          @workspace.create_block(block_name: 'aaaa', raw: "A" * 16)
        end
        @workspace.transaction() do
          @workspace.create_block(block_name: 'bbbb', raw: "B" * 16)
        end
        assert_equal(['aaaa', 'bbbb'], @workspace.get_block_names().sort())

        _test_define(block_name: 'aaaa', workspace: @workspace, address: 0x0000, length: 0x0001, comment: "a!!")
        _test_define(block_name: 'bbbb', workspace: @workspace, address: 0x0000, length: 0x0004, comment: "B!!")

        @workspace.transaction() do
          @workspace.delete_block(block_name: 'aaaa')
        end
        @workspace.transaction() do
          @workspace.delete_block(block_name: 'bbbb')
        end

        @workspace.undo()
        @workspace.undo()

        result = @workspace.get(block_name: 'aaaa', address: 0x00, length: 0x01, since:0)
        assert_equal('a!!', result[:entries][0][:comment])
        assert_equal('A'.bytes(), result[:entries][0][:raw])

        result = @workspace.get(block_name: 'bbbb', address: 0x00, length: 0x01, since:0)
        assert_equal('B!!', result[:entries][0][:comment])
        assert_equal('BBBB'.bytes(), result[:entries][0][:raw])
      end

      def test_handle_no_such_block()
        @workspace.transaction() do
          @workspace.create_block(block_name: 'aaaa', raw: "A" * 16)
        end
        @workspace.transaction() do
          @workspace.delete_block(block_name: 'aaaa')
        end

        @workspace.transaction() do
          assert_raises(Error) do
            @workspace.delete_block(block_name: 'aaaa')
          end
          assert_raises(Error) do
            _test_define(block_name: 'aaaa', workspace: @workspace, address: 0x0000, length: 0x0001, do_transaction: false)
          end
          assert_raises(Error) do
            _test_undefine(block_name: 'aaaa', workspace: @workspace, address: 0x0000, length: 0x0001, do_transaction: false)
          end
          assert_raises(Error) do
            @workspace.get_user_defined(block_name: 'aaaa', address: 0x0000)
          end
          assert_raises(Error) do
            @workspace.replace_user_defined(block_name: 'aaaa', address: 0x0000, user_defined: {})
          end
          assert_raises(Error) do
            @workspace.update_user_defined(block_name: 'aaaa', address: 0x0000, user_defined: {})
          end
          assert_raises(Error) do
            @workspace.set_comment(block_name: 'aaaa', address: 0x0000, comment: 'hi')
          end
          assert_raises(Error) do
            @workspace.get(block_name: 'aaaa', address: 0x00, length: 0xFF, since:0)
          end
        end
      end
    end
  end
end
