require 'test_helper'

require 'h2gb/vault/error'
require 'h2gb/vault/memory/memory_block'
require 'h2gb/vault/memory/memory_entry'

module H2gb
  module Vault
    class MemoryBlockTest < Test::Unit::TestCase
      def setup()
        raw = (0..255).to_a().map() { |b| b.chr() }.join()
        @memory_block = Memory::MemoryBlock.new(raw: raw)
      end

      def test_empty()
        @memory_block.each_entry_in_range(address: 0x00, length: 0xFF) do |address, entry, raw, refs, xrefs|
          assert_true(false)
        end
      end

      def test_single_byte()
        test_entry = TestHelper.test_memory_entry(address: 0x0000, length: 0x0001)
        @memory_block.define(entry: test_entry, revision: 1)

        results = []
        @memory_block.each_entry_in_range(address: 0x0000, length: 0x00FF, since: 0) do |address, entry, raw, refs, xrefs|
          results << {
            address: address,
            entry: entry,
            raw: raw,
            refs: refs,
            xrefs: xrefs,
          }
        end

        expected = [
          { address: 0x0000, entry: test_entry, raw: "\x00".bytes(), refs: {}, xrefs: {} },
        ]
        assert_equal(expected, results)
      end

      def test_each_entry_no_entries_in_range()
        test_entry = TestHelper.test_memory_entry(address: 0x0000, length: 0x0001)
        @memory_block.define(entry: test_entry, revision: 1)

        @memory_block.each_entry_in_range(address: 0x0002, length: 0x0004) do |address, entry, raw, refs, xrefs|
          assert_true(false)
        end
      end

      def test_each_entry_outside_raw()
        test_entry = TestHelper.test_memory_entry(address: 0x0000, length: 0x0001)
        @memory_block.define(entry: test_entry, revision: 1)

        assert_raises(Error) do
          @memory_block.each_entry_in_range(address: 0x00F8, length: 0x0009) do |address, entry, raw, refs, xrefs|
            assert_true(false)
          end
        end
      end

      def test_single_byte_middle_of_range()
        test_entry = TestHelper.test_memory_entry(address: 0x0080, length: 0x0001)
        @memory_block.define(entry: test_entry, revision: 1)

        results = []
        @memory_block.each_entry_in_range(address: 0x0000, length: 0x0100) do |address, entry, raw, refs, xrefs|
          results << {
            address: address,
            entry: entry,
            raw: raw,
          }
        end

        expected = [
          { address: 0x0080, entry: test_entry, raw: "\x80".bytes() },
        ]
        assert_equal(expected, results)
      end

      def test_multiple_bytes()
        entries = [
          TestHelper.test_memory_entry(address: 0x0010, length: 0x0010),
          TestHelper.test_memory_entry(address: 0x0020, length: 0x0010),
          TestHelper.test_memory_entry(address: 0x0030, length: 0x0010),
        ]

        entries.each do |test_entry|
          @memory_block.define(entry: test_entry, revision: 1)
        end

        results = []
        @memory_block.each_entry_in_range(address: 0x0000, length: 0x0100) do |address, entry, raw, refs, xrefs|
          results << entry
        end
        assert_equal(entries, results)
      end

      def test_overlapping()
        entries = [
          TestHelper.test_memory_entry(address: 0x0000, length: 0x0010),
          TestHelper.test_memory_entry(address: 0x0008, length: 0x0010),
        ]

        @memory_block.define(entry: entries[0], revision: 1)
        assert_raises(Error) do
          @memory_block.define(entry: entries[1], revision: 1)
        end
      end

      def test_delete()
        test_entry = TestHelper.test_memory_entry(address: 0x0000, length: 0x0004)

        @memory_block.define(entry: test_entry, revision: 1)
        @memory_block.undefine(entry: test_entry, revision: 1)

        results = []
        @memory_block.each_entry_in_range(address: 0x0000, length: 0x00FF) do |address, entry, raw, refs, xrefs|
          results << {
            address: address,
            entry: entry,
          }
        end

        expected = [
          { address: 0x0000, entry: TestHelper.test_memory_entry_deleted(address: 0) },
          { address: 0x0001, entry: TestHelper.test_memory_entry_deleted(address: 1) },
          { address: 0x0002, entry: TestHelper.test_memory_entry_deleted(address: 2) },
          { address: 0x0003, entry: TestHelper.test_memory_entry_deleted(address: 3) },
        ]
        assert_equal(expected, results)
      end

      def test_delete_multiple()
        entries = [
          TestHelper.test_memory_entry(address: 0x0010, length: 0x0002),
          TestHelper.test_memory_entry(address: 0x0020, length: 0x0002),
          TestHelper.test_memory_entry(address: 0x0030, length: 0x0002),
        ]

        entries.each do |test_entry|
          @memory_block.define(entry: test_entry, revision: 1)
        end
        entries.each do |test_entry|
          @memory_block.undefine(entry: test_entry, revision: 1)
        end

        results = []
        @memory_block.each_entry_in_range(address: 0x0000, length: 0x0100) do |address, entry, raw, refs, xrefs|
          results << entry
        end
        expected = [
          TestHelper.test_memory_entry_deleted(address: 0x0010),
          TestHelper.test_memory_entry_deleted(address: 0x0011),
          TestHelper.test_memory_entry_deleted(address: 0x0020),
          TestHelper.test_memory_entry_deleted(address: 0x0021),
          TestHelper.test_memory_entry_deleted(address: 0x0030),
          TestHelper.test_memory_entry_deleted(address: 0x0031),
        ]
        assert_equal(expected, results)
      end

      def test_delete_no_such_entry()
        test_entry = TestHelper.test_memory_entry(address: 0x0000, length: 0x0010)

        assert_raises(Error) do
          @memory_block.undefine(entry: test_entry, revision: 1)
        end
      end

      def test_get()
        test_entry = TestHelper.test_memory_entry(address: 0x0000, length: 0x0004)
        @memory_block.define(entry: test_entry, revision: 1)

        result = @memory_block.get(address: 0x0000)
        assert_equal(test_entry, result)

        result = @memory_block.get(address: 0x0001)
        assert_equal(test_entry, result)

        result = @memory_block.get(address: 0x0002)
        assert_equal(test_entry, result)

        result = @memory_block.get(address: 0x0003)
        assert_equal(test_entry, result)
      end

      def test_get_adjacent()
        test_entry = TestHelper.test_memory_entry(address: 0x0004, length: 0x0004)
        @memory_block.define(entry: test_entry, revision: 1)

        result = @memory_block.get(address: 0x0003)
        expected = TestHelper.test_memory_entry_deleted(address: 0x0003)
        assert_equal(expected, result)

        result = @memory_block.get(address: 0x0008)
        expected = TestHelper.test_memory_entry_deleted(address: 0x0008)
        assert_equal(expected, result)
      end

      def test_get_nothing()
        result = @memory_block.get(address: 0x0000)
        expected = TestHelper.test_memory_entry_deleted(address: 0x0000)
        assert_equal(expected, result)
      end

      def test_get_dont_define_by_default()
        result = @memory_block.get(address: 0x0000, define_by_default: false)
        assert_nil(result)
      end

      def test_get_past_end()
        assert_raises(Error) do
          @memory_block.get(address: 0xFFFF)
        end
      end

      def test_since()
        test_entry_1 = TestHelper.test_memory_entry(address: 0x0000, length: 0x0004)
        @memory_block.define(entry: test_entry_1, revision: 1)

        test_entry_2 = TestHelper.test_memory_entry(address: 0x0008, length: 0x0004)
        @memory_block.define(entry: test_entry_2, revision: 2)

        entries = []
        @memory_block.each_entry_in_range(address: 0x0000, length: 0x0010, since: 1) do |address, entry, raw, refs, xrefs|
          entries << entry
        end
        assert_equal([test_entry_2], entries)
      end

      def test_since_delete()
        test_entry_1 = TestHelper.test_memory_entry(address: 0x0000, length: 0x0004)
        @memory_block.define(entry: test_entry_1, revision: 1)
        @memory_block.undefine(entry: test_entry_1, revision: 2)

        entries = []
        @memory_block.each_entry_in_range(address: 0x0000, length: 0x0010, since: 1) do |address, entry, raw, refs, xrefs|
          entries << entry
        end
        expected = [
          TestHelper.test_memory_entry_deleted(address: 0x0000),
          TestHelper.test_memory_entry_deleted(address: 0x0001),
          TestHelper.test_memory_entry_deleted(address: 0x0002),
          TestHelper.test_memory_entry_deleted(address: 0x0003),
        ]
        assert_equal(expected, entries)
      end

      def test_revision_going_down()
        test_entry = TestHelper.test_memory_entry(address: 0x0080, length: 0x0002)
        @memory_block.define(entry: test_entry, revision: 3)

        assert_raises(Error) do
          @memory_block.undefine(entry: test_entry, revision: 2)
        end
        assert_raises(Error) do
          @memory_block.define(entry: test_entry, revision: 1)
        end
      end

      def test_refs_and_xrefs()
        test_entry1 = TestHelper.test_memory_entry(address: 0x0000, length: 0x0002)
        @memory_block.define(entry: test_entry1, revision: 1)
        @memory_block.add_refs(type: :code, from: 0x0000, tos: [0x0004], revision: 1)
        @memory_block.add_refs(type: :data, from: 0x0000, tos: [0x0008], revision: 1)

        results = []
        @memory_block.each_entry_in_range(address: 0x0000, length: 0x00FF, since: 0) do |address, entry, raw, refs, xrefs|
          results << {
            entry: entry,
            refs: refs,
            xrefs: xrefs,
          }
        end

        expected = [
          { entry: test_entry1, refs: { code: [0x0004], data: [0x0008]}, xrefs: {} },
          { entry: TestHelper.test_memory_entry_deleted(address: 0x0004), refs: {}, xrefs: {code: [0x0000]} },
          { entry: TestHelper.test_memory_entry_deleted(address: 0x0008), refs: {}, xrefs: {data: [0x0000]} },
        ]
        assert_equal(expected, results)
      end

      def test_xrefs_update_revision()
        test_entry = TestHelper.test_memory_entry(address: 0x0000, length: 0x0002)
        @memory_block.define(entry: test_entry, revision: 1)
        @memory_block.add_refs(type: :code, from: 0x0000, tos: [0x0004], revision: 2)

        results = []
        @memory_block.each_entry_in_range(address: 0x0000, length: 0x00FF, since: 1) do |address, entry, raw, refs, xrefs|
          results << {
            entry: entry,
            refs: refs,
            xrefs: xrefs,
          }
        end

        expected = [
          { entry: test_entry, refs: {code: [0x0004]}, xrefs: {} },
          { entry: TestHelper.test_memory_entry_deleted(address: 0x0004), refs: {}, xrefs: {code: [0x0000]} },
        ]
        assert_equal(expected, results)
      end

      def test_ref_to_middle_of_entry()
        test_entry1 = TestHelper.test_memory_entry(address: 0x0000, length: 0x0002)
        @memory_block.define(entry: test_entry1, revision: 1)
        @memory_block.add_refs(type: :code, from: 0x0000, tos: [0x0005], revision: 1)

        test_entry2 = TestHelper.test_memory_entry(address: 0x0004, length: 0x0002)
        @memory_block.define(entry: test_entry2, revision: 1)

        results = []
        @memory_block.each_entry_in_range(address: 0x0000, length: 0x00FF, since: 0) do |address, entry, raw, refs, xrefs|
          results << {
            entry: entry,
            refs: refs,
            xrefs: xrefs,
          }
        end

        expected = [
          { entry: test_entry1, refs: {code: [0x0005]}, xrefs: {} },
          { entry: test_entry2, refs: {}, xrefs: {} },
        ]
        assert_equal(expected, results)
      end

      def test_delete_refs()
        test_entry1 = TestHelper.test_memory_entry(address: 0x0000, length: 0x0002)
        @memory_block.define(entry: test_entry1, revision: 1)
        @memory_block.add_refs(type: :code, from: 0x0000, tos: [0x0004], revision: 1)
        @memory_block.add_refs(type: :data, from: 0x0000, tos: [0x0008], revision: 1)

        test_entry2 = TestHelper.test_memory_entry(address: 0x0004, length: 0x0002)
        @memory_block.define(entry: test_entry2, revision: 1)
        @memory_block.add_refs(type: :code, from: 0x0004, tos: [0x0004], revision: 1)
        @memory_block.add_refs(type: :code, from: 0x0004, tos: [0x0008], revision: 1)
        @memory_block.add_refs(type: :code, from: 0x0004, tos: [0x000c], revision: 1)

        test_entry3 = TestHelper.test_memory_entry(address: 0x0008, length: 0x0002)
        @memory_block.define(entry: test_entry3, revision: 1)

        @memory_block.remove_refs(type: :code, from: test_entry1.address, tos: [0x0004], revision: 1)
        @memory_block.remove_refs(type: :data, from: test_entry1.address, tos: [0x0008], revision: 1)
        @memory_block.undefine(entry: test_entry1, revision: 1)

        @memory_block.remove_refs(type: :code, from: test_entry2.address, tos: [0x0004, 0x0008], revision: 1)

        results = []
        @memory_block.each_entry_in_range(address: 0x0000, length: 0x00FF, since: 0) do |address, entry, raw, refs, xrefs|
          results << {
            entry: entry,
            refs: refs,
            xrefs: xrefs,
          }
        end

        expected = [
          { entry: TestHelper.test_memory_entry_deleted(address: 0x0000), refs: {}, xrefs: {} },
          { entry: TestHelper.test_memory_entry_deleted(address: 0x0001), refs: {}, xrefs: {} },
          { entry: test_entry2, refs: {code: [0x000c]}, xrefs: {} },
          { entry: test_entry3, refs: {}, xrefs: {} },
          { entry: TestHelper.test_memory_entry_deleted(address: 0x000c), refs: {}, xrefs: { code: [0x0004] } },
        ]
        assert_equal(expected, results)
      end

      def test_delete_xref_while_other_refs_remain()
        test_entry1 = TestHelper.test_memory_entry(address: 0x0000, length: 0x0002)
        @memory_block.define(entry: test_entry1, revision: 1)
        @memory_block.add_refs(type: :data, from: 0x0000, tos: [0x0004], revision: 1)
        @memory_block.add_refs(type: :data, from: 0x0000, tos: [0x0008], revision: 1)
        @memory_block.add_refs(type: :code, from: 0x0000, tos: [0x0008], revision: 1)

        test_entry2 = TestHelper.test_memory_entry(address: 0x0004, length: 0x0002)
        @memory_block.define(entry: test_entry2, revision: 1)
        @memory_block.add_refs(type: :code, from: 0x0004, tos: [0x0008], revision: 1)
        @memory_block.add_refs(type: :data, from: 0x0004, tos: [0x0008], revision: 1)

        @memory_block.remove_refs(type: :data, from: 0x0000, tos: [0x0008], revision: 1)

        results = []
        @memory_block.each_entry_in_range(address: 0x0000, length: 0x00FF, since: 0) do |address, entry, raw, refs, xrefs|
          results << {
            entry: entry,
            refs: refs,
            xrefs: xrefs,
          }
        end

        expected = [
          { entry: test_entry1, refs: {data: [0x0004], code: [0x0008]}, xrefs: {} },
          { entry: test_entry2, refs: {data: [0x0008], code: [0x0008]}, xrefs: {data: [0x0000]} },
          { entry: TestHelper.test_memory_entry_deleted(address: 0x0008), refs: {}, xrefs: {code: [0x0000, 0x0004], data: [0x0004]} },
        ]
        assert_equal(expected, results)
      end

      def test_delete_refs_revision_updated()
        test_entry1 = TestHelper.test_memory_entry(address: 0x0000, length: 0x0002)
        @memory_block.define(entry: test_entry1, revision: 1)
        @memory_block.add_refs(type: :data, from: 0x0000, tos: [0x0004], revision: 1)
        @memory_block.add_refs(type: :data, from: 0x0000, tos: [0x0008], revision: 1)
        @memory_block.add_refs(type: :code, from: 0x0000, tos: [0x0008], revision: 1)

        test_entry2 = TestHelper.test_memory_entry(address: 0x0004, length: 0x0002)
        @memory_block.define(entry: test_entry2, revision: 1)
        @memory_block.add_refs(type: :code, from: 0x0004, tos: [0x0008], revision: 1)
        @memory_block.add_refs(type: :data, from: 0x0004, tos: [0x0008], revision: 1)

        @memory_block.remove_refs(type: :data, from: 0x0000, tos: [0x0008], revision: 2)

        results = []
        @memory_block.each_entry_in_range(address: 0x0000, length: 0x00FF, since: 1) do |address, entry, raw, refs, xrefs|
          results << {
            entry: entry,
            refs: refs,
            xrefs: xrefs,
          }
        end

        expected = [
          { entry: test_entry1, refs: {data: [0x0004], code: [0x0008]}, xrefs: {} },
          { entry: TestHelper.test_memory_entry_deleted(address: 0x0008), refs: {}, xrefs: {code: [0x0000, 0x0004], data: [0x0004]} },
        ]
        assert_equal(expected, results)
      end

      def test_remove_one_reference_when_there_are_duplicates()
        test_entry1 = TestHelper.test_memory_entry(address: 0x0000, length: 0x0002)
        @memory_block.define(entry: test_entry1, revision: 1)
        @memory_block.add_refs(type: :code, from: 0x0000, tos: [0x0000], revision: 1)
        @memory_block.add_refs(type: :code, from: 0x0000, tos: [0x0000], revision: 1)

        results = []
        @memory_block.each_entry_in_range(address: 0x0000, length: 0x00FF, since: 0) do |address, entry, raw, refs, xrefs|
          results << {
            entry: entry,
            refs: refs,
            xrefs: xrefs,
          }
        end
        expected = [
          { entry: test_entry1, refs: { code: [0x0000, 0x0000] }, xrefs: { code: [0x0000, 0x0000] } },
        ]
        assert_equal(expected, results)

        @memory_block.remove_refs(type: :code, from: 0x0000, tos: [0x0000], revision: 1)

        results = []
        @memory_block.each_entry_in_range(address: 0x0000, length: 0x00FF, since: 0) do |address, entry, raw, refs, xrefs|
          results << {
            entry: entry,
            refs: refs,
            xrefs: xrefs,
          }
        end
        expected = [
          { entry: test_entry1, refs: { code: [0x0000] }, xrefs: { code: [0x0000] } },
        ]
        assert_equal(expected, results)
      end

      def test_add_ref_with_no_entry()
        assert_raises(Error) do
          @memory_block.add_refs(type: :code, from: 0x0000, tos: [0x0004], revision: 1)
        end
      end

      def test_remove_ref_with_no_entry()
        assert_raises(Error) do
          @memory_block.remove_refs(type: :code, from: 0x0000, tos: [0x0004], revision: 1)
        end
      end

      def test_remove_ref_that_doesnt_exist()
        test_entry1 = TestHelper.test_memory_entry(address: 0x0000, length: 0x0002)
        @memory_block.define(entry: test_entry1, revision: 1)
        @memory_block.add_refs(type: :code, from: 0x0000, tos: [0x0004], revision: 1)

        assert_raises(Error) do
          @memory_block.remove_refs(type: :data, from: 0x0004, tos: [0x0004], revision: 1)
        end
        assert_raises(Error) do
          @memory_block.remove_refs(type: :data, from: 0x0004, tos: [0x0000], revision: 1)
        end
        assert_raises(Error) do
          @memory_block.remove_refs(type: :data, from: 0x0000, tos: [0x0004], revision: 1)
        end
      end

      def test_each_entry_in_range_no_undefined()
        test_entry = TestHelper.test_memory_entry(address: 0x0000, length: 0x0004)
        @memory_block.define(entry: test_entry, revision: 1)

        results = []
        @memory_block.each_entry_in_range(address: 0x0000, length: 0x0008, since: -1, include_undefined: true) do |address, entry, raw, refs, xrefs|
          results << { address: address, entry: entry }
        end

        expected = [
          { address: 0x0000, entry: TestHelper.test_memory_entry(address: 0x0000, length: 0x0004) },
          { address: 0x0004, entry: TestHelper.test_memory_entry_deleted(address: 0x0004) },
          { address: 0x0005, entry: TestHelper.test_memory_entry_deleted(address: 0x0005) },
          { address: 0x0006, entry: TestHelper.test_memory_entry_deleted(address: 0x0006) },
          { address: 0x0007, entry: TestHelper.test_memory_entry_deleted(address: 0x0007) },
        ]
        assert_equal(expected, results)

        results = []
        @memory_block.each_entry_in_range(address: 0x0000, length: 0x0008, since: -1, include_undefined: false) do |address, entry, raw, refs, xrefs|
          results << { address: address, entry: entry }
        end

        expected = [
          { address: 0x0000, entry: TestHelper.test_memory_entry(address: 0x0000, length: 0x0004) },
        ]
        assert_equal(expected, results)
      end
    end
  end
end
