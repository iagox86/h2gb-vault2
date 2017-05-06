require 'test_helper'

require 'h2gb/vault/memory/memory'

# Generate a nice simple test memory map
RAW = (0..255).to_a().map() { |b| b.chr() }.join()

#class H2gb::Vault::InsertTest < Test::Unit::TestCase
#  def setup()
#    @memory = H2gb::Vault::Memory.new(raw: RAW)
#  end
#
#  def test_empty()
#    result = @memory.get(address: 0x00, length: 0xFF, since:0)
#    expected = {
#      revision: 0x00,
#      entries: [],
#    }
#    assert_equal(expected, result)
#  end
#
#  def test_single_entry()
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "A", length: 0x01)
#    end
#
#    result = @memory.get(address: 0x00, length: 0x01, since:0)
#    expected = {
#      revision: 0x1,
#      entries: [
#        { address: 0x00, data: "A", length: 0x01, refs: [], raw: [0x00], xrefs: [] },
#      ]
#    }
#
#    assert_equal(expected, result)
#  end
#
#  def test_get_longer_entry()
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "A", length: 0x08)
#    end
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 1,
#      entries: [
#        { address: 0x00, data: "A", length: 0x08, refs: [], raw: [0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07], xrefs: [] },
#      ]
#    }
#
#    assert_equal(expected, result)
#  end
#
#  def test_get_entry_in_middle()
#    @memory.transaction() do
#      @memory.insert(address: 0x80, data: "A", length: 0x01)
#    end
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 0x01,
#      entries: [
#        { address: 0x80, data: "A", length: 0x01, refs: [], raw: [0x80], xrefs: [] },
#      ]
#    }
#
#    assert_equal(expected, result)
#  end
#
#  def test_two_adjacent()
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "A", length: 0x02)
#    end
#
#    @memory.transaction() do
#      @memory.insert(address: 0x02, data: "B", length: 0x02)
#    end
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#
#    expected = {
#      revision: 0x02,
#      entries: [
#        { address: 0x00, data: "A", length: 0x02, refs: [], raw: [0x00, 0x01], xrefs: [] },
#        { address: 0x02, data: "B", length: 0x02, refs: [], raw: [0x02, 0x03], xrefs: [] },
#      ]
#    }
#
#    assert_equal(expected, result)
#  end
#
#  def test_two_adjacent_in_same_transaction()
#    @memory.transaction do
#      @memory.insert(address: 0x00, data: "A", length: 0x02)
#      @memory.insert(address: 0x02, data: "B", length: 0x02)
#    end
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#
#    expected = {
#      revision: 1,
#      entries: [
#        { address: 0x00, data: "A", length: 0x02, refs: [], raw: [0x00, 0x01], xrefs: [] },
#        { address: 0x02, data: "B", length: 0x02, refs: [], raw: [0x02, 0x03], xrefs: [] },
#      ]
#    }
#
#    assert_equal(expected, result)
#  end
#
#  def test_two_not_adjacent()
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "A", length: 0x02)
#      @memory.insert(address: 0x80, data: "B", length: 0x02)
#    end
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#
#    expected = {
#      revision: 0x01,
#      entries: [
#        { address: 0x00, data: "A", length: 0x02, refs: [], raw: [0x00, 0x01], xrefs: [] },
#        { address: 0x80, data: "B", length: 0x02, refs: [], raw: [0x80, 0x81], xrefs: [] },
#      ]
#    }
#
#    assert_equal(expected, result)
#  end
#
#  def test_overwrite()
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "A", length: 0x01)
#    end
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "B", length: 0x01)
#    end
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 0x02,
#      entries: [
#        { address: 0x00, data: "B", length: 0x01, refs: [], raw: [0x00], xrefs: [] },
#      ]
#    }
#
#    assert_equal(expected, result)
#  end
#
#  def test_overwrite_by_shorter()
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "A", length: 0x08)
#    end
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "B", length: 0x01)
#    end
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 0x02,
#      entries: [
#        { address: 0x00, data: "B", length: 0x01, refs: [], raw: [0x00], xrefs: [] },
#        { address: 0x01, data: nil, length: 0x01, refs: [], raw: [0x01], xrefs: [] },
#        { address: 0x02, data: nil, length: 0x01, refs: [], raw: [0x02], xrefs: [] },
#        { address: 0x03, data: nil, length: 0x01, refs: [], raw: [0x03], xrefs: [] },
#        { address: 0x04, data: nil, length: 0x01, refs: [], raw: [0x04], xrefs: [] },
#        { address: 0x05, data: nil, length: 0x01, refs: [], raw: [0x05], xrefs: [] },
#        { address: 0x06, data: nil, length: 0x01, refs: [], raw: [0x06], xrefs: [] },
#        { address: 0x07, data: nil, length: 0x01, refs: [], raw: [0x07], xrefs: [] },
#      ]
#    }
#
#    assert_equal(expected, result)
#  end
#
#  def test_overwrite_middle()
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "A", length: 0x08)
#    end
#    @memory.transaction() do
#      @memory.insert(address: 0x04, data: "B", length: 0x01)
#    end
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 0x02,
#      entries: [
#        { address: 0x00, data: nil, length: 0x01, refs: [], raw: [0x00], xrefs: [] },
#        { address: 0x01, data: nil, length: 0x01, refs: [], raw: [0x01], xrefs: [] },
#        { address: 0x02, data: nil, length: 0x01, refs: [], raw: [0x02], xrefs: [] },
#        { address: 0x03, data: nil, length: 0x01, refs: [], raw: [0x03], xrefs: [] },
#        { address: 0x04, data: "B", length: 0x01, refs: [], raw: [0x04], xrefs: [] },
#        { address: 0x05, data: nil, length: 0x01, refs: [], raw: [0x05], xrefs: [] },
#        { address: 0x06, data: nil, length: 0x01, refs: [], raw: [0x06], xrefs: [] },
#        { address: 0x07, data: nil, length: 0x01, refs: [], raw: [0x07], xrefs: [] },
#      ]
#    }
#
#    assert_equal(expected, result)
#  end
#
#  def test_overwrite_multiple()
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "A", length: 0x02)
#    end
#    @memory.transaction() do
#      @memory.insert(address: 0x02, data: "B", length: 0x04)
#    end
#    @memory.transaction() do
#      @memory.insert(address: 0x01, data: "C", length: 0x02)
#    end
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 0x03,
#      entries: [
#        { address: 0x00, data: nil, length: 0x01, refs: [], raw: [0x00], xrefs: [] },
#        { address: 0x01, data: "C", length: 0x02, refs: [], raw: [0x01, 0x02], xrefs: [] },
#        { address: 0x03, data: nil, length: 0x01, refs: [], raw: [0x03], xrefs: [] },
#        { address: 0x04, data: nil, length: 0x01, refs: [], raw: [0x04], xrefs: [] },
#        { address: 0x05, data: nil, length: 0x01, refs: [], raw: [0x05], xrefs: [] },
#      ]
#    }
#
#    assert_equal(expected, result)
#  end
#
#  def test_overwrite_multiple_with_gap()
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "A", length: 0x02)
#    end
#    @memory.transaction() do
#      @memory.insert(address: 0x10, data: "B", length: 0x10)
#    end
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "C", length: 0x80)
#    end
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 0x03,
#      entries: [
#        { address: 0x00, data: "C", length: 0x80, refs: [], raw: (0x00..0x7F).to_a(), xrefs: [] },
#      ]
#    }
#
#    assert_equal(expected, result)
#  end
#
#  def test_insert_invalid_refs_string()
#    assert_raises(H2gb::Vault::Memory::MemoryError) do
#      @memory.transaction() do
#        @memory.insert(address: 0x00, data: "A", length: 0x02, refs: 'hi')
#      end
#    end
#  end
#
#  def test_insert_invalid_refs_array_string()
#    assert_raises(H2gb::Vault::Memory::MemoryError) do
#      @memory.transaction() do
#        @memory.insert(address: 0x00, data: "A", length: 0x02, refs: ['hi'])
#      end
#    end
#  end
#
#  def test_insert_invalid_refs_nil()
#    assert_raises(H2gb::Vault::Memory::MemoryError) do
#      @memory.transaction() do
#        @memory.insert(address: 0x00, data: "A", length: 0x02, refs: [nil])
#      end
#    end
#  end
#end
#
###
## Since we already use transactions throughout other tests, this will simply
## ensure that transactions are required.
###
#class H2gb::Vault::TransactionTest < Test::Unit::TestCase
#  def setup()
#    @memory = H2gb::Vault::Memory.new(raw: RAW)
#  end
#
#  def test_add_transaction()
#    assert_raises(H2gb::Vault::Memory::MemoryError) do
#      @memory.insert(address: 0x00, length: 0x01, data: 'A')
#    end
#  end
#
#  def test_delete_transaction()
#    assert_raises(H2gb::Vault::Memory::MemoryError) do
#      @memory.delete(address: 0x00, length: 0x01)
#    end
#  end
#
#  def test_revision_increment()
#    result = @memory.get(address: 0x00, length: 0x00, since: 0)
#    assert_equal(0, result[:revision])
#
#    @memory.transaction() do
#    end
#
#    result = @memory.get(address: 0x00, length: 0x00, since: 0)
#    assert_equal(1, result[:revision])
#  end
#end
#
#class H2gb::Vault::DeleteTest < Test::Unit::TestCase
#  def setup()
#    @memory = H2gb::Vault::Memory.new(raw: RAW)
#  end
#
#  def test_delete_nothing()
#    @memory.transaction() do
#      @memory.delete(address: 0x00, length: 0xFF)
#    end
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#
#    expected = {
#      revision: 0x01,
#      entries: [],
#    }
#    assert_equal(expected, result)
#  end
#
#  def test_delete_one_byte()
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "A", length: 0x01)
#    end
#
#    @memory.transaction() do
#      @memory.delete(address: 0x00, length: 0x01)
#    end
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 0x02,
#      entries: [
#        { address: 0x00, data: nil, length: 0x01, refs: [], raw: [0x00], xrefs: [] },
#      ],
#    }
#
#    assert_equal(expected, result)
#  end
#
#  def test_delete_multi_bytes()
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "A", length: 0x04)
#    end
#
#    @memory.transaction() do
#      @memory.delete(address: 0x00, length: 0x04)
#    end
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 0x02,
#      entries: [
#        { address: 0x00, data: nil, length: 0x01, refs: [], raw: [0x00], xrefs: [] },
#        { address: 0x01, data: nil, length: 0x01, refs: [], raw: [0x01], xrefs: [] },
#        { address: 0x02, data: nil, length: 0x01, refs: [], raw: [0x02], xrefs: [] },
#        { address: 0x03, data: nil, length: 0x01, refs: [], raw: [0x03], xrefs: [] },
#      ],
#    }
#
#    assert_equal(expected, result)
#  end
#
#  def test_delete_zero_bytes()
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "A", length: 0x10)
#    end
#
#    @memory.transaction() do
#      @memory.delete(address: 0x08, length: 0x0)
#    end
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 0x02,
#      entries: [
#        { address: 0x00, data: "A", length: 0x10, refs: [], raw: (0x00..0x0F).to_a(), xrefs: [] },
#      ],
#    }
#
#    assert_equal(expected, result)
#  end
#
#  def test_delete_just_start()
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "A", length: 0x04)
#    end
#
#    @memory.transaction() do
#      @memory.delete(address: 0x00, length: 0x01)
#    end
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 0x02,
#      entries: [
#        { address: 0x00, data: nil, length: 0x01, refs: [], raw: [0x00], xrefs: [] },
#        { address: 0x01, data: nil, length: 0x01, refs: [], raw: [0x01], xrefs: [] },
#        { address: 0x02, data: nil, length: 0x01, refs: [], raw: [0x02], xrefs: [] },
#        { address: 0x03, data: nil, length: 0x01, refs: [], raw: [0x03], xrefs: [] },
#      ],
#    }
#
#    assert_equal(expected, result)
#  end
#
#  def test_delete_just_middle()
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "A", length: 0x08)
#    end
#
#    @memory.transaction() do
#      @memory.delete(address: 0x04, length: 0x08)
#    end
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 0x02,
#      entries: [
#        { address: 0x00, data: nil, length: 0x01, refs: [], raw: [0x00], xrefs: [] },
#        { address: 0x01, data: nil, length: 0x01, refs: [], raw: [0x01], xrefs: [] },
#        { address: 0x02, data: nil, length: 0x01, refs: [], raw: [0x02], xrefs: [] },
#        { address: 0x03, data: nil, length: 0x01, refs: [], raw: [0x03], xrefs: [] },
#        { address: 0x04, data: nil, length: 0x01, refs: [], raw: [0x04], xrefs: [] },
#        { address: 0x05, data: nil, length: 0x01, refs: [], raw: [0x05], xrefs: [] },
#        { address: 0x06, data: nil, length: 0x01, refs: [], raw: [0x06], xrefs: [] },
#        { address: 0x07, data: nil, length: 0x01, refs: [], raw: [0x07], xrefs: [] },
#      ],
#    }
#
#    assert_equal(expected, result)
#  end
#
#  def test_delete_multiple_entries()
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "A", length: 0x04)
#      @memory.insert(address: 0x04, data: "B", length: 0x04)
#      @memory.insert(address: 0x08, data: "C", length: 0x04)
#    end
#
#    @memory.transaction() do
#      @memory.delete(address: 0x00, length: 0xFF)
#    end
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 0x02,
#      entries: [
#        { address: 0x00, data: nil, length: 0x01, refs: [], raw: [0x00], xrefs: [] },
#        { address: 0x01, data: nil, length: 0x01, refs: [], raw: [0x01], xrefs: [] },
#        { address: 0x02, data: nil, length: 0x01, refs: [], raw: [0x02], xrefs: [] },
#        { address: 0x03, data: nil, length: 0x01, refs: [], raw: [0x03], xrefs: [] },
#        { address: 0x04, data: nil, length: 0x01, refs: [], raw: [0x04], xrefs: [] },
#        { address: 0x05, data: nil, length: 0x01, refs: [], raw: [0x05], xrefs: [] },
#        { address: 0x06, data: nil, length: 0x01, refs: [], raw: [0x06], xrefs: [] },
#        { address: 0x07, data: nil, length: 0x01, refs: [], raw: [0x07], xrefs: [] },
#        { address: 0x08, data: nil, length: 0x01, refs: [], raw: [0x08], xrefs: [] },
#        { address: 0x09, data: nil, length: 0x01, refs: [], raw: [0x09], xrefs: [] },
#        { address: 0x0a, data: nil, length: 0x01, refs: [], raw: [0x0a], xrefs: [] },
#        { address: 0x0b, data: nil, length: 0x01, refs: [], raw: [0x0b], xrefs: [] },
#      ],
#    }
#
#    assert_equal(expected, result)
#  end
#
#  def test_delete_but_leave_adjacent()
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "A", length: 0x08)
#      @memory.insert(address: 0x08, data: "B", length: 0x08)
#      @memory.insert(address: 0x10, data: "C", length: 0x08)
#    end
#    @memory.transaction() do
#      @memory.delete(address: 0x08, length: 0x08)
#    end
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 0x02,
#      entries: [
#        { address: 0x00, data: "A", length: 0x08, refs: [], raw: (0x00..0x07).to_a(), xrefs: [] },
#        { address: 0x08, data: nil, length: 0x01, refs: [], raw: [0x08], xrefs: [] },
#        { address: 0x09, data: nil, length: 0x01, refs: [], raw: [0x09], xrefs: [] },
#        { address: 0x0a, data: nil, length: 0x01, refs: [], raw: [0x0a], xrefs: [] },
#        { address: 0x0b, data: nil, length: 0x01, refs: [], raw: [0x0b], xrefs: [] },
#        { address: 0x0c, data: nil, length: 0x01, refs: [], raw: [0x0c], xrefs: [] },
#        { address: 0x0d, data: nil, length: 0x01, refs: [], raw: [0x0d], xrefs: [] },
#        { address: 0x0e, data: nil, length: 0x01, refs: [], raw: [0x0e], xrefs: [] },
#        { address: 0x0f, data: nil, length: 0x01, refs: [], raw: [0x0f], xrefs: [] },
#        { address: 0x10, data: "C", length: 0x08, refs: [], raw: (0x10..0x17).to_a(), xrefs: [] }
#      ],
#    }
#    assert_equal(expected, result)
#  end
#
#  def test_delete_multi_but_leave_adjacent()
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "A", length: 0x10)
#      @memory.insert(address: 0x10, data: "B", length: 0x10)
#      @memory.insert(address: 0x20, data: "C", length: 0x10)
#      @memory.insert(address: 0x30, data: "D", length: 0x10)
#    end
#    @memory.transaction() do
#      @memory.delete(address: 0x18, length: 0x10)
#    end
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 0x02,
#      entries: [
#        { address: 0x00, data: "A", length: 0x10, refs: [], raw: (0x00..0x0F).to_a(), xrefs: [] },
#        { address: 0x10, data: nil, length: 0x01, refs: [], raw: [0x10], xrefs: [] },
#        { address: 0x11, data: nil, length: 0x01, refs: [], raw: [0x11], xrefs: [] },
#        { address: 0x12, data: nil, length: 0x01, refs: [], raw: [0x12], xrefs: [] },
#        { address: 0x13, data: nil, length: 0x01, refs: [], raw: [0x13], xrefs: [] },
#        { address: 0x14, data: nil, length: 0x01, refs: [], raw: [0x14], xrefs: [] },
#        { address: 0x15, data: nil, length: 0x01, refs: [], raw: [0x15], xrefs: [] },
#        { address: 0x16, data: nil, length: 0x01, refs: [], raw: [0x16], xrefs: [] },
#        { address: 0x17, data: nil, length: 0x01, refs: [], raw: [0x17], xrefs: [] },
#        { address: 0x18, data: nil, length: 0x01, refs: [], raw: [0x18], xrefs: [] },
#        { address: 0x19, data: nil, length: 0x01, refs: [], raw: [0x19], xrefs: [] },
#        { address: 0x1a, data: nil, length: 0x01, refs: [], raw: [0x1a], xrefs: [] },
#        { address: 0x1b, data: nil, length: 0x01, refs: [], raw: [0x1b], xrefs: [] },
#        { address: 0x1c, data: nil, length: 0x01, refs: [], raw: [0x1c], xrefs: [] },
#        { address: 0x1d, data: nil, length: 0x01, refs: [], raw: [0x1d], xrefs: [] },
#        { address: 0x1e, data: nil, length: 0x01, refs: [], raw: [0x1e], xrefs: [] },
#        { address: 0x1f, data: nil, length: 0x01, refs: [], raw: [0x1f], xrefs: [] },
#        { address: 0x20, data: nil, length: 0x01, refs: [], raw: [0x20], xrefs: [] },
#        { address: 0x21, data: nil, length: 0x01, refs: [], raw: [0x21], xrefs: [] },
#        { address: 0x22, data: nil, length: 0x01, refs: [], raw: [0x22], xrefs: [] },
#        { address: 0x23, data: nil, length: 0x01, refs: [], raw: [0x23], xrefs: [] },
#        { address: 0x24, data: nil, length: 0x01, refs: [], raw: [0x24], xrefs: [] },
#        { address: 0x25, data: nil, length: 0x01, refs: [], raw: [0x25], xrefs: [] },
#        { address: 0x26, data: nil, length: 0x01, refs: [], raw: [0x26], xrefs: [] },
#        { address: 0x27, data: nil, length: 0x01, refs: [], raw: [0x27], xrefs: [] },
#        { address: 0x28, data: nil, length: 0x01, refs: [], raw: [0x28], xrefs: [] },
#        { address: 0x29, data: nil, length: 0x01, refs: [], raw: [0x29], xrefs: [] },
#        { address: 0x2a, data: nil, length: 0x01, refs: [], raw: [0x2a], xrefs: [] },
#        { address: 0x2b, data: nil, length: 0x01, refs: [], raw: [0x2b], xrefs: [] },
#        { address: 0x2c, data: nil, length: 0x01, refs: [], raw: [0x2c], xrefs: [] },
#        { address: 0x2d, data: nil, length: 0x01, refs: [], raw: [0x2d], xrefs: [] },
#        { address: 0x2e, data: nil, length: 0x01, refs: [], raw: [0x2e], xrefs: [] },
#        { address: 0x2f, data: nil, length: 0x01, refs: [], raw: [0x2f], xrefs: [] },
#        { address: 0x30, data: "D", length: 0x10, refs: [], raw: (0x30..0x3F).to_a(), xrefs: [] }
#      ],
#    }
#    assert_equal(expected, result)
#  end
#end
#
#class H2gb::Vault::UndoTest < Test::Unit::TestCase
#  def setup()
#    @memory = H2gb::Vault::Memory.new(raw: RAW)
#  end
#
#  def test_basic_undo()
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "A", length: 0x02)
#    end
#    @memory.transaction() do
#      @memory.insert(address: 0x02, data: "B", length: 0x02)
#    end
#    @memory.undo()
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#
#    expected = {
#      revision: 0x03,
#      entries: [
#        { address: 0x00, data: "A", length: 0x02, refs: [], raw: [0x00, 0x01], xrefs: [] },
#        { address: 0x02, data: nil, length: 0x01, refs: [], raw: [0x02], xrefs: [] },
#        { address: 0x03, data: nil, length: 0x01, refs: [], raw: [0x03], xrefs: [] },
#      ],
#    }
#
#    assert_equal(expected, result)
#  end
#
#  def test_undo_multiple_steps()
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "A", length: 0x02)
#    end
#    @memory.transaction() do
#      @memory.insert(address: 0x02, data: "B", length: 0x02)
#    end
#    @memory.transaction() do
#      @memory.insert(address: 0x04, data: "C", length: 0x02)
#    end
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 0x03,
#      entries: [
#        { address: 0x00, data: "A", length: 0x02, refs: [], raw: [0x00, 0x01], xrefs: [] },
#        { address: 0x02, data: "B", length: 0x02, refs: [], raw: [0x02, 0x03], xrefs: [] },
#        { address: 0x04, data: "C", length: 0x02, refs: [], raw: [0x04, 0x05], xrefs: [] },
#      ]
#    }
#    assert_equal(expected, result)
#
#    @memory.undo()
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 0x04,
#      entries: [
#        { address: 0x00, data: "A", length: 0x02, refs: [], raw: [0x00, 0x01], xrefs: [] },
#        { address: 0x02, data: "B", length: 0x02, refs: [], raw: [0x02, 0x03], xrefs: [] },
#        { address: 0x04, data: nil, length: 0x01, refs: [], raw: [0x04], xrefs: [] },
#        { address: 0x05, data: nil, length: 0x01, refs: [], raw: [0x05], xrefs: [] },
#      ]
#    }
#    assert_equal(expected, result)
#
#    @memory.undo()
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 0x05,
#      entries: [
#        { address: 0x00, data: "A", length: 0x02, refs: [], raw: [0x00, 0x01], xrefs: [] },
#        { address: 0x02, data: nil, length: 0x01, refs: [], raw: [0x02], xrefs: [] },
#        { address: 0x03, data: nil, length: 0x01, refs: [], raw: [0x03], xrefs: [] },
#        { address: 0x04, data: nil, length: 0x01, refs: [], raw: [0x04], xrefs: [] },
#        { address: 0x05, data: nil, length: 0x01, refs: [], raw: [0x05], xrefs: [] },
#      ]
#    }
#    assert_equal(expected, result)
#
#    @memory.undo()
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 0x06,
#      entries: [
#        { address: 0x00, data: nil, length: 0x01, refs: [], raw: [0x00], xrefs: [] },
#        { address: 0x01, data: nil, length: 0x01, refs: [], raw: [0x01], xrefs: [] },
#        { address: 0x02, data: nil, length: 0x01, refs: [], raw: [0x02], xrefs: [] },
#        { address: 0x03, data: nil, length: 0x01, refs: [], raw: [0x03], xrefs: [] },
#        { address: 0x04, data: nil, length: 0x01, refs: [], raw: [0x04], xrefs: [] },
#        { address: 0x05, data: nil, length: 0x01, refs: [], raw: [0x05], xrefs: [] },
#      ],
#    }
#    assert_equal(expected, result)
#  end
#
#  def test_undo_then_set()
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "A", length: 0x02)
#    end
#    @memory.transaction() do
#      @memory.insert(address: 0x02, data: "B", length: 0x02)
#    end
#    @memory.undo()
#    @memory.transaction() do
#      @memory.insert(address: 0x04, data: "C", length: 0x02)
#    end
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#
#    expected = {
#      revision: 4,
#      entries: [
#        { address: 0x00, data: "A", length: 0x02, refs: [], raw: [0x00, 0x01], xrefs: [] },
#        { address: 0x02, data: nil, length: 0x01, refs: [], raw: [0x02], xrefs: [] },
#        { address: 0x03, data: nil, length: 0x01, refs: [], raw: [0x03], xrefs: [] },
#        { address: 0x04, data: "C", length: 0x02, refs: [], raw: [0x04, 0x05], xrefs: [] },
#      ]
#    }
#
#    assert_equal(expected, result)
#  end
#
#  ##
#  # Attempts to exercise the situation where an undo would inappropriately undo
#  # another undo.
#  ##
#  def test_undo_across_other_undos()
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "A", length: 0x02)
#    end
#    @memory.transaction() do
#      @memory.insert(address: 0x02, data: "B", length: 0x02)
#    end
#
#    @memory.undo() # undo B
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 0x03,
#      entries: [
#        { address: 0x00, data: "A", length: 0x02, refs: [], raw: [0x00, 0x01], xrefs: [] },
#        { address: 0x02, data: nil, length: 0x01, refs: [], raw: [0x02], xrefs: [] },
#        { address: 0x03, data: nil, length: 0x01, refs: [], raw: [0x03], xrefs: [] },
#      ],
#    }
#    assert_equal(expected, result)
#
#    @memory.transaction() do
#      @memory.insert(address: 0x04, data: "C", length: 0x02)
#    end
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 0x04,
#      entries: [
#        { address: 0x00, data: "A", length: 0x02, refs: [], raw: [0x00, 0x01], xrefs: [] },
#        { address: 0x02, data: nil, length: 0x01, refs: [], raw: [0x02], xrefs: [] },
#        { address: 0x03, data: nil, length: 0x01, refs: [], raw: [0x03], xrefs: [] },
#        { address: 0x04, data: "C", length: 0x02, refs: [], raw: [0x04, 0x05], xrefs: [] },
#      ],
#    }
#    assert_equal(expected, result)
#
#    @memory.undo() # undo C
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 0x05,
#      entries: [
#        { address: 0x00, data: "A", length: 0x02, refs: [], raw: [0x00, 0x01], xrefs: [] },
#        { address: 0x02, data: nil, length: 0x01, refs: [], raw: [0x02], xrefs: [] },
#        { address: 0x03, data: nil, length: 0x01, refs: [], raw: [0x03], xrefs: [] },
#        { address: 0x04, data: nil, length: 0x01, refs: [], raw: [0x04], xrefs: [] },
#        { address: 0x05, data: nil, length: 0x01, refs: [], raw: [0x05], xrefs: [] },
#      ],
#    }
#    assert_equal(expected, result)
#
#    @memory.undo() # undo A
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 0x06,
#      entries: [
#        { address: 0x00, data: nil, length: 0x01, refs: [], raw: [0x00], xrefs: [] },
#        { address: 0x01, data: nil, length: 0x01, refs: [], raw: [0x01], xrefs: [] },
#        { address: 0x02, data: nil, length: 0x01, refs: [], raw: [0x02], xrefs: [] },
#        { address: 0x03, data: nil, length: 0x01, refs: [], raw: [0x03], xrefs: [] },
#        { address: 0x04, data: nil, length: 0x01, refs: [], raw: [0x04], xrefs: [] },
#        { address: 0x05, data: nil, length: 0x01, refs: [], raw: [0x05], xrefs: [] },
#      ],
#    }
#    assert_equal(expected, result)
#
#  end
#
#  def test_undo_then_set_then_undo_again()
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "A", length: 0x02)
#    end
#    @memory.transaction() do
#      @memory.insert(address: 0x02, data: "B", length: 0x02)
#    end
#
#    @memory.undo()
#
#    @memory.transaction() do
#      @memory.insert(address: 0x04, data: "C", length: 0x02)
#    end
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 0x04,
#      entries: [
#        { address: 0x00, data: "A", length: 0x02, refs: [], raw: [0x00, 0x01], xrefs: [] },
#        { address: 0x02, data: nil, length: 0x01, refs: [], raw: [0x02], xrefs: [] },
#        { address: 0x03, data: nil, length: 0x01, refs: [], raw: [0x03], xrefs: [] },
#        { address: 0x04, data: "C", length: 0x02, refs: [], raw: [0x04, 0x05], xrefs: [] },
#      ]
#    }
#    assert_equal(expected, result)
#
#    @memory.undo()
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 0x05,
#      entries: [
#        { address: 0x00, data: "A", length: 0x02, refs: [], raw: [0x00, 0x01], xrefs: [] },
#        { address: 0x02, data: nil, length: 0x01, refs: [], raw: [0x02], xrefs: [] },
#        { address: 0x03, data: nil, length: 0x01, refs: [], raw: [0x03], xrefs: [] },
#        { address: 0x04, data: nil, length: 0x01, refs: [], raw: [0x04], xrefs: [] },
#        { address: 0x05, data: nil, length: 0x01, refs: [], raw: [0x05], xrefs: [] },
#      ]
#    }
#    assert_equal(expected, result)
#  end
#
#  def test_undo_too_much()
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "A", length: 0x02)
#    end
#    @memory.undo()
#    @memory.undo()
#    @memory.undo()
#    @memory.undo()
#    @memory.undo()
#    @memory.undo()
#
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "A", length: 0x02)
#    end
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#
#    expected = {
#      revision: 0x03,
#      entries: [
#        { address: 0x00, data: "A", length: 0x02, refs: [], raw: [0x00, 0x01], xrefs: [] },
#      ]
#    }
#
#    assert_equal(expected, result)
#  end
#
#  def test_undo_overwrite()
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "A", length: 0x02)
#    end
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 0x01,
#      entries: [
#        { address: 0x00, data: "A", length: 0x02, refs: [], raw: [0x00, 0x01], xrefs: [] },
#      ]
#    }
#    assert_equal(expected, result)
#
#    @memory.transaction() do
#      @memory.insert(address: 0x01, data: "B", length: 0x02)
#    end
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 0x02,
#      entries: [
#        { address: 0x00, data: nil, length: 0x01, refs: [], raw: [0x00], xrefs: [] },
#        { address: 0x01, data: "B", length: 0x02, refs: [], raw: [0x01, 0x02], xrefs: [] },
#      ]
#    }
#    assert_equal(expected, result)
#
#    @memory.undo()
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 0x03,
#      entries: [
#        { address: 0x00, data: "A", length: 0x02, refs: [], raw: [0x00, 0x01], xrefs: [] },
#        { address: 0x02, data: nil, length: 0x01, refs: [], raw: [0x02], xrefs: [] },
#      ]
#    }
#    assert_equal(expected, result)
#  end
#
#  def test_transaction_undo()
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "A", length: 0x02)
#      @memory.insert(address: 0x02, data: "B", length: 0x02)
#    end
#
#    @memory.transaction() do
#      @memory.insert(address: 0x01, data: "C", length: 0x02)
#      @memory.insert(address: 0x03, data: "D", length: 0x02)
#    end
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 0x02,
#      entries: [
#        { address: 0x00, data: nil, length: 0x01, refs: [], raw: [0x00], xrefs: [] },
#        { address: 0x01, data: "C", length: 0x02, refs: [], raw: [0x01, 0x02], xrefs: [] },
#        { address: 0x03, data: "D", length: 0x02, refs: [], raw: [0x03, 0x04], xrefs: [] },
#      ]
#    }
#    assert_equal(expected, result)
#
#    @memory.undo()
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 0x03,
#      entries: [
#        { address: 0x00, data: "A", length: 0x02, refs: [], raw: [0x00, 0x01], xrefs: [] },
#        { address: 0x02, data: "B", length: 0x02, refs: [], raw: [0x02, 0x03], xrefs: [] },
#        { address: 0x04, data: nil, length: 0x01, refs: [], raw: [0x04], xrefs: [] },
#      ]
#    }
#    assert_equal(expected, result)
#  end
#
#  def test_repeat_undo_redo()
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "A", length: 0x02)
#    end
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "B", length: 0x02)
#    end
#
#    @memory.undo()
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 0x03,
#      entries: [
#        { address: 0x00, data: "A", length: 0x02, refs: [], raw: [0x00, 0x01], xrefs: [] },
#      ],
#    }
#    assert_equal(expected, result)
#
#    @memory.redo()
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 0x04,
#      entries: [
#        { address: 0x00, data: "B", length: 0x02, refs: [], raw: [0x00, 0x01], xrefs: [] },
#      ],
#    }
#    assert_equal(expected, result)
#
#    @memory.undo()
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 0x05,
#      entries: [
#        { address: 0x00, data: "A", length: 0x02, refs: [], raw: [0x00, 0x01], xrefs: [] },
#      ],
#    }
#    assert_equal(expected, result)
#
#    @memory.redo()
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 0x06,
#      entries: [
#        { address: 0x00, data: "B", length: 0x02, refs: [], raw: [0x00, 0x01], xrefs: [] },
#      ],
#    }
#    assert_equal(expected, result)
#
#    @memory.undo()
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 0x07,
#      entries: [
#        { address: 0x00, data: "A", length: 0x02, refs: [], raw: [0x00, 0x01], xrefs: [] },
#      ],
#    }
#    assert_equal(expected, result)
#
#    @memory.redo()
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 0x08,
#      entries: [
#        { address: 0x00, data: "B", length: 0x02, refs: [], raw: [0x00, 0x01], xrefs: [] },
#      ],
#    }
#    assert_equal(expected, result)
#  end
#end
#
#class H2gb::Vault::RedoTest < Test::Unit::TestCase
#  def setup()
#    @memory = H2gb::Vault::Memory.new(raw: RAW)
#  end
#
#  def test_basic_redo()
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "A", length: 0x02)
#    end
#    @memory.transaction() do
#      @memory.insert(address: 0x02, data: "B", length: 0x02)
#    end
#    @memory.undo()
#    @memory.redo()
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#
#    expected = {
#      revision: 0x04,
#      entries: [
#        { address: 0x00, data: "A", length: 0x02, refs: [], raw: [0x00, 0x01], xrefs: [] },
#        { address: 0x02, data: "B", length: 0x02, refs: [], raw: [0x02, 0x03], xrefs: [] },
#      ]
#    }
#
#    assert_equal(expected, result)
#  end
#
#  def test_redo_multiple_steps()
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "A", length: 0x02)
#    end
#    @memory.transaction() do
#      @memory.insert(address: 0x02, data: "B", length: 0x02)
#    end
#    @memory.transaction() do
#      @memory.insert(address: 0x04, data: "C", length: 0x02)
#    end
#
#    @memory.undo()
#    @memory.undo()
#    @memory.undo()
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 0x06,
#      entries: [
#        { address: 0x00, data: nil, length: 0x01, refs: [], raw: [0x00], xrefs: [] },
#        { address: 0x01, data: nil, length: 0x01, refs: [], raw: [0x01], xrefs: [] },
#        { address: 0x02, data: nil, length: 0x01, refs: [], raw: [0x02], xrefs: [] },
#        { address: 0x03, data: nil, length: 0x01, refs: [], raw: [0x03], xrefs: [] },
#        { address: 0x04, data: nil, length: 0x01, refs: [], raw: [0x04], xrefs: [] },
#        { address: 0x05, data: nil, length: 0x01, refs: [], raw: [0x05], xrefs: [] },
#      ]
#    }
#    assert_equal(expected, result)
#
#    @memory.redo()
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 0x07,
#      entries: [
#        { address: 0x00, data: "A", length: 0x02, refs: [], raw: [0x00, 0x01], xrefs: [] },
#        { address: 0x02, data: nil, length: 0x01, refs: [], raw: [0x02], xrefs: [] },
#        { address: 0x03, data: nil, length: 0x01, refs: [], raw: [0x03], xrefs: [] },
#        { address: 0x04, data: nil, length: 0x01, refs: [], raw: [0x04], xrefs: [] },
#        { address: 0x05, data: nil, length: 0x01, refs: [], raw: [0x05], xrefs: [] },
#      ]
#    }
#    assert_equal(expected, result)
#
#    @memory.redo()
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 0x08,
#      entries: [
#        { address: 0x00, data: "A", length: 0x02, refs: [], raw: [0x00, 0x01], xrefs: [] },
#        { address: 0x02, data: "B", length: 0x02, refs: [], raw: [0x02, 0x03], xrefs: [] },
#        { address: 0x04, data: nil, length: 0x01, refs: [], raw: [0x04], xrefs: [] },
#        { address: 0x05, data: nil, length: 0x01, refs: [], raw: [0x05], xrefs: [] },
#      ]
#    }
#    assert_equal(expected, result)
#
#    @memory.redo()
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 0x09,
#      entries: [
#        { address: 0x00, data: "A", length: 0x02, refs: [], raw: [0x00, 0x01], xrefs: [] },
#        { address: 0x02, data: "B", length: 0x02, refs: [], raw: [0x02, 0x03], xrefs: [] },
#        { address: 0x04, data: "C", length: 0x02, refs: [], raw: [0x04, 0x05], xrefs: [] },
#      ]
#    }
#    assert_equal(expected, result)
#  end
#
#  def test_redo_then_set()
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "A", length: 0x02)
#    end
#    @memory.transaction() do
#      @memory.insert(address: 0x02, data: "B", length: 0x02)
#    end
#    @memory.undo()
#    @memory.redo()
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "C", length: 0x02)
#    end
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#
#    expected = {
#      revision: 0x05,
#      entries: [
#        { address: 0x00, data: "C", length: 0x02, refs: [], raw: [0x00, 0x01], xrefs: [] },
#        { address: 0x02, data: "B", length: 0x02, refs: [], raw: [0x02, 0x03], xrefs: [] },
#      ]
#    }
#
#    assert_equal(expected, result)
#  end
#
#  ##
#  # Attempts to exercise the situation where an undo would inappropriately undo
#  # another undo.
#  ##
#  def test_redo_across_other_undos()
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "A", length: 0x02)
#    end
#    @memory.transaction() do
#      @memory.insert(address: 0x02, data: "B", length: 0x02)
#    end
#
#    @memory.undo() # undo B
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 0x03,
#      entries: [
#        { address: 0x00, data: "A", length: 0x02, refs: [], raw: [0x00, 0x01], xrefs: [] },
#        { address: 0x02, data: nil, length: 0x01, refs: [], raw: [0x02], xrefs: [] },
#        { address: 0x03, data: nil, length: 0x01, refs: [], raw: [0x03], xrefs: [] },
#      ],
#    }
#    assert_equal(expected, result)
#
#    @memory.transaction() do
#      @memory.insert(address: 0x04, data: "C", length: 0x02)
#    end
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 0x04,
#      entries: [
#        { address: 0x00, data: "A", length: 0x02, refs: [], raw: [0x00, 0x01], xrefs: [] },
#        { address: 0x02, data: nil, length: 0x01, refs: [], raw: [0x02], xrefs: [] },
#        { address: 0x03, data: nil, length: 0x01, refs: [], raw: [0x03], xrefs: [] },
#        { address: 0x04, data: "C", length: 0x02, refs: [], raw: [0x04, 0x05], xrefs: [] },
#      ],
#    }
#    assert_equal(expected, result)
#
#    @memory.undo() # undo C
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 0x05,
#      entries: [
#        { address: 0x00, data: "A", length: 0x02, refs: [], raw: [0x00, 0x01], xrefs: [] },
#        { address: 0x02, data: nil, length: 0x01, refs: [], raw: [0x02], xrefs: [] },
#        { address: 0x03, data: nil, length: 0x01, refs: [], raw: [0x03], xrefs: [] },
#        { address: 0x04, data: nil, length: 0x01, refs: [], raw: [0x04], xrefs: [] },
#        { address: 0x05, data: nil, length: 0x01, refs: [], raw: [0x05], xrefs: [] },
#      ],
#    }
#    assert_equal(expected, result)
#
#    @memory.undo() # undo A
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 0x06,
#      entries: [
#        { address: 0x00, data: nil, length: 0x01, refs: [], raw: [0x00], xrefs: [] },
#        { address: 0x01, data: nil, length: 0x01, refs: [], raw: [0x01], xrefs: [] },
#        { address: 0x02, data: nil, length: 0x01, refs: [], raw: [0x02], xrefs: [] },
#        { address: 0x03, data: nil, length: 0x01, refs: [], raw: [0x03], xrefs: [] },
#        { address: 0x04, data: nil, length: 0x01, refs: [], raw: [0x04], xrefs: [] },
#        { address: 0x05, data: nil, length: 0x01, refs: [], raw: [0x05], xrefs: [] },
#      ],
#    }
#    assert_equal(expected, result)
#
#    @memory.redo() # redo A
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 0x07,
#      entries: [
#        { address: 0x00, data: "A", length: 0x02, refs: [], raw: [0x00, 0x01], xrefs: [] },
#        { address: 0x02, data: nil, length: 0x01, refs: [], raw: [0x02], xrefs: [] },
#        { address: 0x03, data: nil, length: 0x01, refs: [], raw: [0x03], xrefs: [] },
#        { address: 0x04, data: nil, length: 0x01, refs: [], raw: [0x04], xrefs: [] },
#        { address: 0x05, data: nil, length: 0x01, refs: [], raw: [0x05], xrefs: [] },
#      ],
#    }
#    assert_equal(expected, result)
#
#    @memory.redo() # redo C
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 0x08,
#      entries: [
#        { address: 0x00, data: "A", length: 0x02, refs: [], raw: [0x00, 0x01], xrefs: [] },
#        { address: 0x02, data: nil, length: 0x01, refs: [], raw: [0x02], xrefs: [] },
#        { address: 0x03, data: nil, length: 0x01, refs: [], raw: [0x03], xrefs: [] },
#        { address: 0x04, data: "C", length: 0x02, refs: [], raw: [0x04, 0x05], xrefs: [] },
#      ],
#    }
#    assert_equal(expected, result)
#
#    @memory.redo() # Should do nothing
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 0x08,
#      entries: [
#        { address: 0x00, data: "A", length: 0x02, refs: [], raw: [0x00, 0x01], xrefs: [] },
#        { address: 0x02, data: nil, length: 0x01, refs: [], raw: [0x02], xrefs: [] },
#        { address: 0x03, data: nil, length: 0x01, refs: [], raw: [0x03], xrefs: [] },
#        { address: 0x04, data: "C", length: 0x02, refs: [], raw: [0x04, 0x05], xrefs: [] },
#      ],
#    }
#    assert_equal(expected, result)
#  end
#
#  def test_redo_goes_away_after_edit()
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "A", length: 0x02)
#    end
#    @memory.transaction() do
#      @memory.insert(address: 0x02, data: "B", length: 0x02)
#    end
#    @memory.transaction() do
#      @memory.insert(address: 0x04, data: "C", length: 0x02)
#    end
#
#    @memory.undo()
#    @memory.undo()
#    @memory.undo()
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    assert_equal({
#      revision: 0x06,
#      entries: [
#        { address: 0x00, data: nil, length: 0x01, refs: [], raw: [0x00], xrefs: [] },
#        { address: 0x01, data: nil, length: 0x01, refs: [], raw: [0x01], xrefs: [] },
#        { address: 0x02, data: nil, length: 0x01, refs: [], raw: [0x02], xrefs: [] },
#        { address: 0x03, data: nil, length: 0x01, refs: [], raw: [0x03], xrefs: [] },
#        { address: 0x04, data: nil, length: 0x01, refs: [], raw: [0x04], xrefs: [] },
#        { address: 0x05, data: nil, length: 0x01, refs: [], raw: [0x05], xrefs: [] },
#      ],
#    }, result)
#
#    @memory.redo()
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 0x07,
#      entries: [
#        { address: 0x00, data: "A", length: 0x02, refs: [], raw: [0x00, 0x01], xrefs: [] },
#        { address: 0x02, data: nil, length: 0x01, refs: [], raw: [0x02], xrefs: [] },
#        { address: 0x03, data: nil, length: 0x01, refs: [], raw: [0x03], xrefs: [] },
#        { address: 0x04, data: nil, length: 0x01, refs: [], raw: [0x04], xrefs: [] },
#        { address: 0x05, data: nil, length: 0x01, refs: [], raw: [0x05], xrefs: [] },
#      ]
#    }
#    assert_equal(expected, result)
#
#    @memory.transaction() do
#      @memory.insert(address: 0x06, data: "D", length: 0x02)
#    end
#
#    @memory.redo() # Should do nothing
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 0x08,
#      entries: [
#        { address: 0x00, data: "A", length: 0x02, refs: [], raw: [0x00, 0x01], xrefs: [] },
#        { address: 0x02, data: nil, length: 0x01, refs: [], raw: [0x02], xrefs: [] },
#        { address: 0x03, data: nil, length: 0x01, refs: [], raw: [0x03], xrefs: [] },
#        { address: 0x04, data: nil, length: 0x01, refs: [], raw: [0x04], xrefs: [] },
#        { address: 0x05, data: nil, length: 0x01, refs: [], raw: [0x05], xrefs: [] },
#        { address: 0x06, data: "D", length: 0x02, refs: [], raw: [0x06, 0x07], xrefs: [] },
#      ]
#    }
#    assert_equal(expected, result)
#  end
#
#  def test_redo_too_much()
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "A", length: 0x02)
#    end
#    @memory.undo()
#    @memory.undo()
#    @memory.redo()
#    @memory.redo()
#    @memory.redo()
#    @memory.redo()
#
#    @memory.transaction() do
#      @memory.insert(address: 0x02, data: "B", length: 0x02)
#    end
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#
#    expected = {
#      revision: 0x04,
#      entries: [
#        { address: 0x00, data: "A", length: 0x02, refs: [], raw: [0x00, 0x01], xrefs: [] },
#        { address: 0x02, data: "B", length: 0x02, refs: [], raw: [0x02, 0x03], xrefs: [] },
#      ]
#    }
#
#    assert_equal(expected, result)
#  end
#
#  def test_redo_overwrite()
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "A", length: 0x02)
#    end
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "B", length: 0x01)
#    end
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "C", length: 0x03)
#    end
#
#    @memory.undo()
#    @memory.undo()
#    @memory.undo()
#    @memory.redo()
#    @memory.redo()
#    @memory.redo()
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 0x09,
#      entries: [
#        { address: 0x00, data: "C", length: 0x03, refs: [], raw: [0x00, 0x01, 0x02], xrefs: [] },
#      ]
#    }
#    assert_equal(expected, result)
#  end
#
#  def test_transaction_redo()
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "A", length: 0x02)
#      @memory.insert(address: 0x02, data: "B", length: 0x02)
#      @memory.insert(address: 0x00, data: "C", length: 0x02)
#      @memory.insert(address: 0x04, data: "D", length: 0x02)
#    end
#
#    @memory.transaction() do
#      @memory.insert(address: 0x01, data: "E", length: 0x02)
#      @memory.insert(address: 0x06, data: "F", length: 0x02)
#    end
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#
#    @memory.undo()
#    @memory.undo()
#
#    @memory.redo()
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 0x05,
#      entries: [
#        { address: 0x00, data: "C", length: 0x02, refs: [], raw: [0x00, 0x01], xrefs: [] },
#        { address: 0x02, data: "B", length: 0x02, refs: [], raw: [0x02, 0x03], xrefs: [] },
#        { address: 0x04, data: "D", length: 0x02, refs: [], raw: [0x04, 0x05], xrefs: [] },
#        { address: 0x06, data: nil, length: 0x01, refs: [], raw: [0x06], xrefs: [] },
#        { address: 0x07, data: nil, length: 0x01, refs: [], raw: [0x07], xrefs: [] },
#      ]
#    }
#    assert_equal(expected, result)
#
#    @memory.redo()
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 0x06,
#      entries: [
#        { address: 0x00, data: nil, length: 0x01, refs: [], raw: [0x00], xrefs: [] },
#        { address: 0x01, data: "E", length: 0x02, refs: [], raw: [0x01, 0x02], xrefs: [] },
#        { address: 0x03, data: nil, length: 0x01, refs: [], raw: [0x03], xrefs: [] },
#        { address: 0x04, data: "D", length: 0x02, refs: [], raw: [0x04, 0x05], xrefs: [] },
#        { address: 0x06, data: "F", length: 0x02, refs: [], raw: [0x06, 0x07], xrefs: [] },
#      ]
#    }
#    assert_equal(expected, result)
#  end
#end
#
#class H2gb::Vault::GetChangesSinceTest < Test::Unit::TestCase
#  def setup()
#    @memory = H2gb::Vault::Memory.new(raw: RAW)
#  end
#
#
#  def test_get_from_minus_one()
#    @memory.transaction() do
#      @memory.insert(address: 0x01, data: "A", length: 0x02)
#    end
#
#    result = @memory.get(address: 0x00, length: 0x04, since: -1)
#    expected = {
#      revision: 0x1,
#      entries: [
#        { address: 0x00, data: nil, length: 0x01, refs: [], raw: [0x00], xrefs: [] },
#        { address: 0x01, data: "A", length: 0x02, refs: [], raw: [0x01, 0x02], xrefs: [] },
#        { address: 0x03, data: nil, length: 0x01, refs: [], raw: [0x03], xrefs: [] },
#      ]
#    }
#
#    assert_equal(expected, result)
#  end
#
#  def test_add_one()
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "A", length: 0x01)
#    end
#
#    result = @memory.get(address: 0x00, length: 0x10, since: 0)
#    expected = {
#      revision: 0x1,
#      entries: [
#        { address: 0x00, data: "A", length: 0x01, refs: [], raw: [0x00], xrefs: [] },
#      ]
#    }
#
#    assert_equal(expected, result)
#  end
#
#  def test_add_multiple()
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "A", length: 0x04)
#    end
#    @memory.transaction() do
#      @memory.insert(address: 0x04, data: "B", length: 0x04)
#    end
#    @memory.transaction() do
#      @memory.insert(address: 0x08, data: "C", length: 0x04)
#    end
#
#    result = @memory.get(address: 0x00, length: 0x10, since: 0)
#    expected = {
#      revision: 0x3,
#      entries: [
#        { address: 0x00, data: "A", length: 0x04, refs: [], raw: [0x00, 0x01, 0x02, 0x03], xrefs: [] },
#        { address: 0x04, data: "B", length: 0x04, refs: [], raw: [0x04, 0x05, 0x06, 0x07], xrefs: [] },
#        { address: 0x08, data: "C", length: 0x04, refs: [], raw: [0x08, 0x09, 0x0a, 0x0b], xrefs: [] },
#      ]
#    }
#    assert_equal(expected, result)
#
#    result = @memory.get(address: 0x00, length: 0x10, since: 1)
#    expected = {
#      revision: 0x3,
#      entries: [
#        { address: 0x04, data: "B", length: 0x04, refs: [], raw: [0x04, 0x05, 0x06, 0x07], xrefs: [] },
#        { address: 0x08, data: "C", length: 0x04, refs: [], raw: [0x08, 0x09, 0x0a, 0x0b], xrefs: [] },
#      ]
#    }
#    assert_equal(expected, result)
#
#    result = @memory.get(address: 0x00, length: 0x10, since: 2)
#    expected = {
#      revision: 0x3,
#      entries: [
#        { address: 0x08, data: "C", length: 0x04, refs: [], raw: [0x08, 0x09, 0x0a, 0x0b], xrefs: [] },
#      ]
#    }
#    assert_equal(expected, result)
#
#    result = @memory.get(address: 0x00, length: 0x10, since: 3)
#    expected = {
#      revision: 0x3,
#      entries: []
#    }
#    assert_equal(expected, result)
#  end
#
#  def test_overwrite()
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "A", length: 0x04)
#    end
#    @memory.transaction() do
#      @memory.insert(address: 0x02, data: "B", length: 0x04)
#    end
#    @memory.transaction() do
#      @memory.insert(address: 0x04, data: "C", length: 0x04)
#    end
#
#    result = @memory.get(address: 0x00, length: 0x10, since: 0)
#    expected = {
#      revision: 0x3,
#      entries: [
#        { address: 0x00, data: nil, length: 0x01, refs: [], raw: [0x00], xrefs: [] },
#        { address: 0x01, data: nil, length: 0x01, refs: [], raw: [0x01], xrefs: [] },
#        { address: 0x02, data: nil, length: 0x01, refs: [], raw: [0x02], xrefs: [] },
#        { address: 0x03, data: nil, length: 0x01, refs: [], raw: [0x03], xrefs: [] },
#        { address: 0x04, data: "C", length: 0x04, refs: [], raw: [0x04, 0x05, 0x06, 0x07], xrefs: [] },
#      ]
#    }
#    assert_equal(expected, result)
#
#    result = @memory.get(address: 0x00, length: 0x10, since: 1)
#    expected = {
#      revision: 0x3,
#      entries: [
#        { address: 0x00, data: nil, length: 0x01, refs: [], raw: [0x00], xrefs: [] },
#        { address: 0x01, data: nil, length: 0x01, refs: [], raw: [0x01], xrefs: [] },
#        { address: 0x02, data: nil, length: 0x01, refs: [], raw: [0x02], xrefs: [] },
#        { address: 0x03, data: nil, length: 0x01, refs: [], raw: [0x03], xrefs: [] },
#        { address: 0x04, data: "C", length: 0x04, refs: [], raw: [0x04, 0x05, 0x06, 0x07], xrefs: [] },
#      ]
#    }
#    assert_equal(expected, result)
#
#    result = @memory.get(address: 0x00, length: 0x10, since: 2)
#    expected = {
#      revision: 0x3,
#      entries: [
#        { address: 0x02, data: nil, length: 0x01, refs: [], raw: [0x02], xrefs: [] },
#        { address: 0x03, data: nil, length: 0x01, refs: [], raw: [0x03], xrefs: [] },
#        { address: 0x04, data: "C", length: 0x04, refs: [], raw: [0x04, 0x05, 0x06, 0x07], xrefs: [] },
#      ]
#    }
#    assert_equal(expected, result)
#
#    result = @memory.get(address: 0x00, length: 0x10, since: 3)
#    expected = {
#      revision: 0x3,
#      entries: []
#    }
#    assert_equal(expected, result)
#  end
#
#  def test_undo()
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "A", length: 0x02)
#    end
#    @memory.transaction() do
#      @memory.insert(address: 0x04, data: "B", length: 0x02)
#    end
#    @memory.transaction() do
#      @memory.insert(address: 0x08, data: "C", length: 0x02)
#    end
#    @memory.undo()
#    @memory.undo()
#    @memory.undo()
#
#    result = @memory.get(address: 0x00, length: 0x10, since: 0)
#    expected = {
#      revision: 0x06,
#      entries: [
#        { address: 0x00, data: nil, length: 0x01, refs: [], raw: [0x00], xrefs: [] },
#        { address: 0x01, data: nil, length: 0x01, refs: [], raw: [0x01], xrefs: [] },
#        { address: 0x04, data: nil, length: 0x01, refs: [], raw: [0x04], xrefs: [] },
#        { address: 0x05, data: nil, length: 0x01, refs: [], raw: [0x05], xrefs: [] },
#        { address: 0x08, data: nil, length: 0x01, refs: [], raw: [0x08], xrefs: [] },
#        { address: 0x09, data: nil, length: 0x01, refs: [], raw: [0x09], xrefs: [] },
#      ]
#    }
#    assert_equal(expected, result)
#
#    result = @memory.get(address: 0x00, length: 0x10, since: 3)
#    expected = {
#      revision: 0x06,
#      entries: [
#        { address: 0x00, data: nil, length: 0x01, refs: [], raw: [0x00], xrefs: [] },
#        { address: 0x01, data: nil, length: 0x01, refs: [], raw: [0x01], xrefs: [] },
#        { address: 0x04, data: nil, length: 0x01, refs: [], raw: [0x04], xrefs: [] },
#        { address: 0x05, data: nil, length: 0x01, refs: [], raw: [0x05], xrefs: [] },
#        { address: 0x08, data: nil, length: 0x01, refs: [], raw: [0x08], xrefs: [] },
#        { address: 0x09, data: nil, length: 0x01, refs: [], raw: [0x09], xrefs: [] },
#      ]
#    }
#    assert_equal(expected, result)
#
#    result = @memory.get(address: 0x00, length: 0x10, since: 4)
#    expected = {
#      revision: 0x06,
#      entries: [
#        { address: 0x00, data: nil, length: 0x01, refs: [], raw: [0x00], xrefs: [] },
#        { address: 0x01, data: nil, length: 0x01, refs: [], raw: [0x01], xrefs: [] },
#        { address: 0x04, data: nil, length: 0x01, refs: [], raw: [0x04], xrefs: [] },
#        { address: 0x05, data: nil, length: 0x01, refs: [], raw: [0x05], xrefs: [] },
#      ]
#    }
#    assert_equal(expected, result)
#
#    result = @memory.get(address: 0x00, length: 0x10, since: 5)
#    expected = {
#      revision: 0x06,
#      entries: [
#        { address: 0x00, data: nil, length: 0x01, refs: [], raw: [0x00], xrefs: [] },
#        { address: 0x01, data: nil, length: 0x01, refs: [], raw: [0x01], xrefs: [] },
#      ]
#    }
#    assert_equal(expected, result)
#
#    result = @memory.get(address: 0x00, length: 0x10, since: 6)
#    expected = {
#      revision: 0x06,
#      entries: [],
#    }
#    assert_equal(expected, result)
#  end
#
#  def test_redo()
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "A", length: 0x04)
#    end
#    @memory.transaction() do
#      @memory.insert(address: 0x02, data: "B", length: 0x04)
#    end
#    @memory.transaction() do
#      @memory.insert(address: 0x08, data: "C", length: 0x02)
#    end
#    @memory.undo()
#    @memory.undo()
#    @memory.undo()
#    @memory.redo()
#    @memory.redo()
#    @memory.redo()
#
#    result = @memory.get(address: 0x00, length: 0x10, since: 0)
#    expected = {
#      revision: 0x09,
#      entries: [
#        { address: 0x00, data: nil, length: 0x01, refs: [], raw: [0x00], xrefs: [] },
#        { address: 0x01, data: nil, length: 0x01, refs: [], raw: [0x01], xrefs: [] },
#        { address: 0x02, data: "B", length: 0x04, refs: [], raw: [0x02, 0x03, 0x04, 0x05], xrefs: [] },
#        { address: 0x08, data: "C", length: 0x02, refs: [], raw: [0x08, 0x09], xrefs: [] },
#      ]
#    }
#    assert_equal(expected, result)
#
#    result = @memory.get(address: 0x00, length: 0x10, since: 6)
#    expected = {
#      revision: 0x09,
#      entries: [
#        { address: 0x00, data: nil, length: 0x01, refs: [], raw: [0x00], xrefs: [] },
#        { address: 0x01, data: nil, length: 0x01, refs: [], raw: [0x01], xrefs: [] },
#        { address: 0x02, data: "B", length: 0x04, refs: [], raw: [0x02, 0x03, 0x04, 0x05], xrefs: [] },
#        { address: 0x08, data: "C", length: 0x02, refs: [], raw: [0x08, 0x09], xrefs: [] },
#      ]
#    }
#    assert_equal(expected, result)
#
#    result = @memory.get(address: 0x00, length: 0x10, since: 7)
#    expected = {
#      revision: 0x09,
#      entries: [
#        { address: 0x00, data: nil, length: 0x01, refs: [], raw: [0x00], xrefs: [] },
#        { address: 0x01, data: nil, length: 0x01, refs: [], raw: [0x01], xrefs: [] },
#        { address: 0x02, data: "B", length: 0x04, refs: [], raw: [0x02, 0x03, 0x04, 0x05], xrefs: [] },
#        { address: 0x08, data: "C", length: 0x02, refs: [], raw: [0x08, 0x09], xrefs: [] },
#      ]
#    }
#    assert_equal(expected, result)
#
#    result = @memory.get(address: 0x00, length: 0x10, since: 8)
#    expected = {
#      revision: 0x09,
#      entries: [
#        { address: 0x08, data: "C", length: 0x02, refs: [], raw: [0x08, 0x09], xrefs: [] },
#      ]
#    }
#    assert_equal(expected, result)
#  end
#end
#
#class H2gb::Vault::XrefsTest < Test::Unit::TestCase
#  def setup()
#    @memory = H2gb::Vault::Memory.new(raw: RAW)
#  end
#
#  def test_basic_xref()
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "A", length: 0x04)
#    end
#
#    @memory.transaction() do
#      @memory.insert(address: 0x04, data: "B", length: 0x04, refs: [0x00])
#    end
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 0x02,
#      entries: [
#        { address: 0x00, data: "A", length: 0x04, raw: [0x00, 0x01, 0x02, 0x03], refs: [], xrefs: [0x04] },
#        { address: 0x04, data: "B", length: 0x04, raw: [0x04, 0x05, 0x06, 0x07], refs: [0x00], xrefs: [] },
#      ]
#    }
#    assert_equal(expected, result)
#  end
#
#  def test_xref_to_middle()
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "A", length: 0x04)
#    end
#
#    @memory.transaction() do
#      @memory.insert(address: 0x04, data: "B", length: 0x04, refs: [0x02])
#    end
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 0x02,
#      entries: [
#        { address: 0x00, data: "A", length: 0x04, raw: [0x00, 0x01, 0x02, 0x03], refs: [], xrefs: [0x04] },
#        { address: 0x04, data: "B", length: 0x04, raw: [0x04, 0x05, 0x06, 0x07], refs: [0x02], xrefs: [] },
#      ]
#    }
#    assert_equal(expected, result)
#  end
#
#  def test_multiple_same_refs()
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "A", length: 0x04)
#    end
#
#    @memory.transaction() do
#      @memory.insert(address: 0x04, data: "B", length: 0x04, refs: [0x00, 0x01, 0x02])
#    end
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 0x02,
#      entries: [
#        { address: 0x00, data: "A", length: 0x04, raw: [0x00, 0x01, 0x02, 0x03], refs: [],                 xrefs: [0x04] },
#        { address: 0x04, data: "B", length: 0x04, raw: [0x04, 0x05, 0x06, 0x07], refs: [0x00, 0x01, 0x02], xrefs: [] },
#      ]
#    }
#    assert_equal(expected, result)
#  end
#
#  def test_multiple_refs()
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "A", length: 0x04, refs: [0x04, 0x08, 0x09])
#    end
#
#    @memory.transaction() do
#      @memory.insert(address: 0x04, data: "B", length: 0x04, refs: [])
#    end
#
#    @memory.transaction() do
#      @memory.insert(address: 0x08, data: "C", length: 0x04, refs: nil)
#    end
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 0x03,
#      entries: [
#        { address: 0x00, data: "A", length: 0x04, raw: [0x00, 0x01, 0x02, 0x03], refs: [0x04, 0x08, 0x09], xrefs: [] },
#        { address: 0x04, data: "B", length: 0x04, raw: [0x04, 0x05, 0x06, 0x07], refs: [],                 xrefs: [0x00] },
#        { address: 0x08, data: "C", length: 0x04, raw: [0x08, 0x09, 0x0a, 0x0b], refs: [],                 xrefs: [0x00] },
#      ]
#    }
#    assert_equal(expected, result)
#  end
#
#  def test_multiple_xrefs()
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "A", length: 0x04, refs: [0x04, 0x08, 0x09])
#    end
#
#    @memory.transaction() do
#      @memory.insert(address: 0x04, data: "B", length: 0x04, refs: [0x0a])
#    end
#
#    @memory.transaction() do
#      @memory.insert(address: 0x08, data: "C", length: 0x04, refs: nil)
#    end
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 0x03,
#      entries: [
#        { address: 0x00, data: "A", length: 0x04, raw: [0x00, 0x01, 0x02, 0x03], refs: [0x04, 0x08, 0x09], xrefs: [] },
#        { address: 0x04, data: "B", length: 0x04, raw: [0x04, 0x05, 0x06, 0x07], refs: [0x0a],             xrefs: [0x00] },
#        { address: 0x08, data: "C", length: 0x04, raw: [0x08, 0x09, 0x0a, 0x0b], refs: [],                 xrefs: [0x00, 0x04] },
#      ]
#    }
#    assert_equal(expected, result)
#  end
#
#  def test_self_ref()
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "A", length: 0x04, refs: [0x00])
#    end
#
#    @memory.transaction() do
#      @memory.insert(address: 0x04, data: "B", length: 0x04, refs: [0x05])
#    end
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 0x02,
#      entries: [
#        { address: 0x00, data: "A", length: 0x04, raw: [0x00, 0x01, 0x02, 0x03], refs: [0x00], xrefs: [0x00] },
#        { address: 0x04, data: "B", length: 0x04, raw: [0x04, 0x05, 0x06, 0x07], refs: [0x05], xrefs: [0x04] },
#      ]
#    }
#    assert_equal(expected, result)
#  end
#
#  def test_delete_ref()
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "A", length: 0x04, refs: [0x04, 0x08, 0x09])
#    end
#
#    @memory.transaction() do
#      @memory.insert(address: 0x04, data: "B", length: 0x04, refs: [0x00, 0x02, 0x0a])
#    end
#
#    @memory.transaction() do
#      @memory.insert(address: 0x08, data: "C", length: 0x04, refs: nil)
#    end
#
#    @memory.transaction() do
#      @memory.delete(address: 0x00, length: 0x01)
#    end
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 0x04,
#      entries: [
#        { address: 0x00, data: nil, length: 0x01, raw: [0x00],                   refs: [],                 xrefs: [0x04] },
#        { address: 0x01, data: nil, length: 0x01, raw: [0x01],                   refs: [],                 xrefs: [] },
#        { address: 0x02, data: nil, length: 0x01, raw: [0x02],                   refs: [],                 xrefs: [0x04] },
#        { address: 0x03, data: nil, length: 0x01, raw: [0x03],                   refs: [],                 xrefs: [] },
#        { address: 0x04, data: "B", length: 0x04, raw: [0x04, 0x05, 0x06, 0x07], refs: [0x00, 0x02, 0x0a], xrefs: [] },
#        { address: 0x08, data: "C", length: 0x04, raw: [0x08, 0x09, 0x0a, 0x0b], refs: [],                 xrefs: [0x04] },
#      ]
#    }
#    assert_equal(expected, result)
#  end
#
#  def test_xref_after_undos_and_redos()
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "A", length: 0x04, refs: [0x04, 0x08, 0x09])
#    end
#
#    @memory.transaction() do
#      @memory.insert(address: 0x04, data: "B", length: 0x04, refs: [0x00, 0x02, 0x0a])
#    end
#
#    @memory.transaction() do
#      @memory.insert(address: 0x08, data: "C", length: 0x04, refs: [0x07])
#    end
#
#    @memory.transaction() do
#      @memory.delete(address: 0x00, length: 0x01)
#    end
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 0x04,
#      entries: [
#        { address: 0x00, data: nil, length: 0x01, raw: [0x00],                   refs: [],                 xrefs: [0x04] },
#        { address: 0x01, data: nil, length: 0x01, raw: [0x01],                   refs: [],                 xrefs: [] },
#        { address: 0x02, data: nil, length: 0x01, raw: [0x02],                   refs: [],                 xrefs: [0x04] },
#        { address: 0x03, data: nil, length: 0x01, raw: [0x03],                   refs: [],                 xrefs: [] },
#        { address: 0x04, data: "B", length: 0x04, raw: [0x04, 0x05, 0x06, 0x07], refs: [0x00, 0x02, 0x0a], xrefs: [0x08] },
#        { address: 0x08, data: "C", length: 0x04, raw: [0x08, 0x09, 0x0a, 0x0b], refs: [0x07],             xrefs: [0x04] },
#      ]
#    }
#    assert_equal(expected, result)
#
#    @memory.undo()
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 0x05,
#      entries: [
#        { address: 0x00, data: "A", length: 0x04, raw: [0x00, 0x01, 0x02, 0x03], refs: [0x04, 0x08, 0x09], xrefs: [0x04] },
#        { address: 0x04, data: "B", length: 0x04, raw: [0x04, 0x05, 0x06, 0x07], refs: [0x00, 0x02, 0x0a], xrefs: [0x00, 0x08] },
#        { address: 0x08, data: "C", length: 0x04, raw: [0x08, 0x09, 0x0a, 0x0b], refs: [0x07],             xrefs: [0x00, 0x04] },
#      ]
#    }
#    assert_equal(expected, result)
#
#    @memory.undo()
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 0x06,
#      entries: [
#        { address: 0x00, data: "A", length: 0x04, raw: [0x00, 0x01, 0x02, 0x03], refs: [0x04, 0x08, 0x09], xrefs: [0x04] },
#        { address: 0x04, data: "B", length: 0x04, raw: [0x04, 0x05, 0x06, 0x07], refs: [0x00, 0x02, 0x0a], xrefs: [0x00] },
#        { address: 0x08, data: nil, length: 0x01, raw: [0x08],                   refs: [],                 xrefs: [0x00] },
#        { address: 0x09, data: nil, length: 0x01, raw: [0x09],                   refs: [],                 xrefs: [0x00] },
#        { address: 0x0a, data: nil, length: 0x01, raw: [0x0a],                   refs: [],                 xrefs: [0x04] },
#        { address: 0x0b, data: nil, length: 0x01, raw: [0x0b],                   refs: [],                 xrefs: [] },
#      ]
#    }
#    assert_equal(expected, result)
#
#    @memory.undo()
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 0x07,
#      entries: [
#        { address: 0x00, data: "A", length: 0x04, raw: [0x00, 0x01, 0x02, 0x03], refs: [0x04, 0x08, 0x09], xrefs: [] },
#        { address: 0x04, data: nil, length: 0x01, raw: [0x04],                   refs: [],                 xrefs: [0x00] },
#        { address: 0x05, data: nil, length: 0x01, raw: [0x05],                   refs: [],                 xrefs: [] },
#        { address: 0x06, data: nil, length: 0x01, raw: [0x06],                   refs: [],                 xrefs: [] },
#        { address: 0x07, data: nil, length: 0x01, raw: [0x07],                   refs: [],                 xrefs: [] },
#        { address: 0x08, data: nil, length: 0x01, raw: [0x08],                   refs: [],                 xrefs: [0x00] },
#        { address: 0x09, data: nil, length: 0x01, raw: [0x09],                   refs: [],                 xrefs: [0x00] },
#        { address: 0x0a, data: nil, length: 0x01, raw: [0x0a],                   refs: [],                 xrefs: [] },
#        { address: 0x0b, data: nil, length: 0x01, raw: [0x0b],                   refs: [],                 xrefs: [] },
#      ]
#    }
#    assert_equal(expected, result)
#
#    @memory.undo()
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 0x08,
#      entries: [
#        { address: 0x00, data: nil, length: 0x01, raw: [0x00],                   refs: [],                 xrefs: [] },
#        { address: 0x01, data: nil, length: 0x01, raw: [0x01],                   refs: [],                 xrefs: [] },
#        { address: 0x02, data: nil, length: 0x01, raw: [0x02],                   refs: [],                 xrefs: [] },
#        { address: 0x03, data: nil, length: 0x01, raw: [0x03],                   refs: [],                 xrefs: [] },
#        { address: 0x04, data: nil, length: 0x01, raw: [0x04],                   refs: [],                 xrefs: [] },
#        { address: 0x05, data: nil, length: 0x01, raw: [0x05],                   refs: [],                 xrefs: [] },
#        { address: 0x06, data: nil, length: 0x01, raw: [0x06],                   refs: [],                 xrefs: [] },
#        { address: 0x07, data: nil, length: 0x01, raw: [0x07],                   refs: [],                 xrefs: [] },
#        { address: 0x08, data: nil, length: 0x01, raw: [0x08],                   refs: [],                 xrefs: [] },
#        { address: 0x09, data: nil, length: 0x01, raw: [0x09],                   refs: [],                 xrefs: [] },
#        { address: 0x0a, data: nil, length: 0x01, raw: [0x0a],                   refs: [],                 xrefs: [] },
#        { address: 0x0b, data: nil, length: 0x01, raw: [0x0b],                   refs: [],                 xrefs: [] },
#      ]
#    }
#    assert_equal(expected, result)
#
#    @memory.redo()
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 0x09,
#      entries: [
#        { address: 0x00, data: "A", length: 0x04, raw: [0x00, 0x01, 0x02, 0x03], refs: [0x04, 0x08, 0x09], xrefs: [] },
#        { address: 0x04, data: nil, length: 0x01, raw: [0x04],                   refs: [],                 xrefs: [0x00] },
#        { address: 0x05, data: nil, length: 0x01, raw: [0x05],                   refs: [],                 xrefs: [] },
#        { address: 0x06, data: nil, length: 0x01, raw: [0x06],                   refs: [],                 xrefs: [] },
#        { address: 0x07, data: nil, length: 0x01, raw: [0x07],                   refs: [],                 xrefs: [] },
#        { address: 0x08, data: nil, length: 0x01, raw: [0x08],                   refs: [],                 xrefs: [0x00] },
#        { address: 0x09, data: nil, length: 0x01, raw: [0x09],                   refs: [],                 xrefs: [0x00] },
#        { address: 0x0a, data: nil, length: 0x01, raw: [0x0a],                   refs: [],                 xrefs: [] },
#        { address: 0x0b, data: nil, length: 0x01, raw: [0x0b],                   refs: [],                 xrefs: [] },
#      ]
#    }
#    assert_equal(expected, result)
#
#    @memory.redo()
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 0x0a,
#      entries: [
#        { address: 0x00, data: "A", length: 0x04, raw: [0x00, 0x01, 0x02, 0x03], refs: [0x04, 0x08, 0x09], xrefs: [0x04] },
#        { address: 0x04, data: "B", length: 0x04, raw: [0x04, 0x05, 0x06, 0x07], refs: [0x00, 0x02, 0x0a], xrefs: [0x00] },
#        { address: 0x08, data: nil, length: 0x01, raw: [0x08],                   refs: [],                 xrefs: [0x00] },
#        { address: 0x09, data: nil, length: 0x01, raw: [0x09],                   refs: [],                 xrefs: [0x00] },
#        { address: 0x0a, data: nil, length: 0x01, raw: [0x0a],                   refs: [],                 xrefs: [0x04] },
#        { address: 0x0b, data: nil, length: 0x01, raw: [0x0b],                   refs: [],                 xrefs: [] },
#      ]
#    }
#    assert_equal(expected, result)
#
#    @memory.redo()
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 0x0b,
#      entries: [
#        { address: 0x00, data: "A", length: 0x04, raw: [0x00, 0x01, 0x02, 0x03], refs: [0x04, 0x08, 0x09], xrefs: [0x04] },
#        { address: 0x04, data: "B", length: 0x04, raw: [0x04, 0x05, 0x06, 0x07], refs: [0x00, 0x02, 0x0a], xrefs: [0x00, 0x08] },
#        { address: 0x08, data: "C", length: 0x04, raw: [0x08, 0x09, 0x0a, 0x0b], refs: [0x07],             xrefs: [0x00, 0x04] },
#      ]
#    }
#    assert_equal(expected, result)
#
#    @memory.redo()
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
#    expected = {
#      revision: 0x0c,
#      entries: [
#        { address: 0x00, data: nil, length: 0x01, raw: [0x00],                   refs: [],                 xrefs: [0x04] },
#        { address: 0x01, data: nil, length: 0x01, raw: [0x01],                   refs: [],                 xrefs: [] },
#        { address: 0x02, data: nil, length: 0x01, raw: [0x02],                   refs: [],                 xrefs: [0x04] },
#        { address: 0x03, data: nil, length: 0x01, raw: [0x03],                   refs: [],                 xrefs: [] },
#        { address: 0x04, data: "B", length: 0x04, raw: [0x04, 0x05, 0x06, 0x07], refs: [0x00, 0x02, 0x0a], xrefs: [0x08] },
#        { address: 0x08, data: "C", length: 0x04, raw: [0x08, 0x09, 0x0a, 0x0b], refs: [0x07],             xrefs: [0x04] },
#      ]
#    }
#    assert_equal(expected, result)
#  end
#
#  def test_xref_with_since()
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "A", length: 0x04, refs: [0x04, 0x05])
#    end
#    @memory.transaction() do
#      @memory.insert(address: 0x04, data: "B", length: 0x04, refs: [0x04])
#    end
#    @memory.transaction() do
#      @memory.insert(address: 0x05, data: "C", length: 0x04, refs: [0x05, 0x0a])
#    end
#
#    result = @memory.get(address: 0x00, length: 0x10, since: 0)
#    expected = {
#      revision: 0x03,
#      entries: [
#        { address: 0x00, data: "A", length: 0x04, raw: [0x00, 0x01, 0x02, 0x03], refs: [0x04, 0x05], xrefs: [] },
#        { address: 0x04, data: nil, length: 0x01, raw: [0x04],                   refs: [],           xrefs: [0x00] },
#        { address: 0x05, data: "C", length: 0x04, raw: [0x05, 0x06, 0x07, 0x08], refs: [0x05, 0x0a], xrefs: [0x00, 0x05] },
#        { address: 0x0a, data: nil, length: 0x01, raw: [0x0a],                   refs: [],           xrefs: [0x05] },
#      ]
#    }
#    assert_equal(expected, result)
#
#    result = @memory.get(address: 0x00, length: 0x10, since: 1)
#    expected = {
#      revision: 0x03,
#      entries: [
#        { address: 0x04, data: nil, length: 0x01, raw: [0x04],                   refs: [],           xrefs: [0x00] },
#        { address: 0x05, data: "C", length: 0x04, raw: [0x05, 0x06, 0x07, 0x08], refs: [0x05, 0x0a], xrefs: [0x00, 0x05] },
#        { address: 0x0a, data: nil, length: 0x01, raw: [0x0a],                   refs: [],           xrefs: [0x05] },
#      ]
#    }
#    assert_equal(expected, result)
#
#    result = @memory.get(address: 0x00, length: 0x10, since: 2)
#    expected = {
#      revision: 0x03,
#      entries: [
#        { address: 0x04, data: nil, length: 0x01, raw: [0x04],                   refs: [],           xrefs: [0x00] },
#        { address: 0x05, data: "C", length: 0x04, raw: [0x05, 0x06, 0x07, 0x08], refs: [0x05, 0x0a], xrefs: [0x00, 0x05] },
#        { address: 0x0a, data: nil, length: 0x01, raw: [0x0a],                   refs: [],           xrefs: [0x05] },
#      ]
#    }
#    assert_equal(expected, result)
#
#    @memory.undo()
#    @memory.undo()
#    @memory.undo()
#
#    result = @memory.get(address: 0x00, length: 0x10, since: 3)
#    expected = {
#      revision: 0x06,
#      entries: [
#        { address: 0x00, data: nil, length: 0x01, raw: [0x00], refs: [], xrefs: [] },
#        { address: 0x01, data: nil, length: 0x01, raw: [0x01], refs: [], xrefs: [] },
#        { address: 0x02, data: nil, length: 0x01, raw: [0x02], refs: [], xrefs: [] },
#        { address: 0x03, data: nil, length: 0x01, raw: [0x03], refs: [], xrefs: [] },
#        { address: 0x04, data: nil, length: 0x01, raw: [0x04], refs: [], xrefs: [] },
#        { address: 0x05, data: nil, length: 0x01, raw: [0x05], refs: [], xrefs: [] },
#        { address: 0x06, data: nil, length: 0x01, raw: [0x06], refs: [], xrefs: [] },
#        { address: 0x07, data: nil, length: 0x01, raw: [0x07], refs: [], xrefs: [] },
#        { address: 0x08, data: nil, length: 0x01, raw: [0x08], refs: [], xrefs: [] },
#        { address: 0x0a, data: nil, length: 0x01, raw: [0x0a], refs: [], xrefs: [] },
#      ]
#    }
#    assert_equal(expected, result)
#
#    result = @memory.get(address: 0x00, length: 0x10, since: 4)
#    expected = {
#      revision: 0x06,
#      entries: [
#        { address: 0x00, data: nil, length: 0x01, raw: [0x00], refs: [], xrefs: [] },
#        { address: 0x01, data: nil, length: 0x01, raw: [0x01], refs: [], xrefs: [] },
#        { address: 0x02, data: nil, length: 0x01, raw: [0x02], refs: [], xrefs: [] },
#        { address: 0x03, data: nil, length: 0x01, raw: [0x03], refs: [], xrefs: [] },
#        { address: 0x04, data: nil, length: 0x01, raw: [0x04], refs: [], xrefs: [] },
#        { address: 0x05, data: nil, length: 0x01, raw: [0x05], refs: [], xrefs: [] },
#        { address: 0x06, data: nil, length: 0x01, raw: [0x06], refs: [], xrefs: [] },
#        { address: 0x07, data: nil, length: 0x01, raw: [0x07], refs: [], xrefs: [] },
#      ]
#    }
#    assert_equal(expected, result)
#
#    result = @memory.get(address: 0x00, length: 0x10, since: 5)
#    expected = {
#      revision: 0x06,
#      entries: [
#        { address: 0x00, data: nil, length: 0x01, raw: [0x00], refs: [], xrefs: [] },
#        { address: 0x01, data: nil, length: 0x01, raw: [0x01], refs: [], xrefs: [] },
#        { address: 0x02, data: nil, length: 0x01, raw: [0x02], refs: [], xrefs: [] },
#        { address: 0x03, data: nil, length: 0x01, raw: [0x03], refs: [], xrefs: [] },
#        { address: 0x04, data: nil, length: 0x01, raw: [0x04], refs: [], xrefs: [] },
#        { address: 0x05, data: nil, length: 0x01, raw: [0x05], refs: [], xrefs: [] },
#      ]
#    }
#    assert_equal(expected, result)
#
#    @memory.redo()
#    @memory.redo()
#    @memory.redo()
#
#    result = @memory.get(address: 0x00, length: 0x10, since: 6)
#    expected = {
#      revision: 0x09,
#      entries: [
#        { address: 0x00, data: "A", length: 0x04, raw: [0x00, 0x01, 0x02, 0x03], refs: [0x04, 0x05], xrefs: [] },
#        { address: 0x04, data: nil, length: 0x01, raw: [0x04],                   refs: [],           xrefs: [0x00] },
#        { address: 0x05, data: "C", length: 0x04, raw: [0x05, 0x06, 0x07, 0x08], refs: [0x05, 0x0a], xrefs: [0x00, 0x05] },
#        { address: 0x0a, data: nil, length: 0x01, raw: [0x0a],                   refs: [],           xrefs: [0x05] },
#      ]
#    }
#    assert_equal(expected, result)
#
#    result = @memory.get(address: 0x00, length: 0x10, since: 7)
#    expected = {
#      revision: 0x09,
#      entries: [
#        { address: 0x04, data: nil, length: 0x01, raw: [0x04],                   refs: [],           xrefs: [0x00] },
#        { address: 0x05, data: "C", length: 0x04, raw: [0x05, 0x06, 0x07, 0x08], refs: [0x05, 0x0a], xrefs: [0x00, 0x05] },
#        { address: 0x0a, data: nil, length: 0x01, raw: [0x0a],                   refs: [],           xrefs: [0x05] },
#      ]
#    }
#    assert_equal(expected, result)
#
#    result = @memory.get(address: 0x00, length: 0x10, since: 8)
#    expected = {
#      revision: 0x09,
#      entries: [
#        { address: 0x04, data: nil, length: 0x01, raw: [0x04],                   refs: [],           xrefs: [0x00] },
#        { address: 0x05, data: "C", length: 0x04, raw: [0x05, 0x06, 0x07, 0x08], refs: [0x05, 0x0a], xrefs: [0x00, 0x05] },
#        { address: 0x0a, data: nil, length: 0x01, raw: [0x0a],                   refs: [],           xrefs: [0x05] },
#      ]
#    }
#    assert_equal(expected, result)
#  end
#end
#
#class H2gb::Vault::SaveRestoreTest < Test::Unit::TestCase
#  def test_save_load()
#    memory = H2gb::Vault::Memory.new(raw: RAW)
#
#    memory.transaction() do
#      memory.insert(address: 0x00, data: "A", length: 0x04, refs: [0x04, 0x05])
#    end
#    memory.transaction() do
#      memory.insert(address: 0x04, data: "B", length: 0x04, refs: [0x04])
#    end
#    memory.transaction() do
#      memory.insert(address: 0x05, data: "C", length: 0x04, refs: [0x05, 0x0a])
#    end
#
#    # Save/load throughout this function to make sure it's working right
#    memory = H2gb::Vault::Memory.load(memory.dump())
#    assert_not_nil(memory)
#
#    result = memory.get(address: 0x00, length: 0x10, since: 0)
#    expected = {
#      revision: 0x03,
#      entries: [
#        { address: 0x00, data: "A", length: 0x04, raw: [0x00, 0x01, 0x02, 0x03], refs: [0x04, 0x05], xrefs: [] },
#        { address: 0x04, data: nil, length: 0x01, raw: [0x04],                   refs: [],           xrefs: [0x00] },
#        { address: 0x05, data: "C", length: 0x04, raw: [0x05, 0x06, 0x07, 0x08], refs: [0x05, 0x0a], xrefs: [0x00, 0x05] },
#        { address: 0x0a, data: nil, length: 0x01, raw: [0x0a],                   refs: [],           xrefs: [0x05] },
#      ]
#    }
#    assert_equal(expected, result)
#
#    result = memory.get(address: 0x00, length: 0x10, since: 1)
#    expected = {
#      revision: 0x03,
#      entries: [
#        { address: 0x04, data: nil, length: 0x01, raw: [0x04],                   refs: [],           xrefs: [0x00] },
#        { address: 0x05, data: "C", length: 0x04, raw: [0x05, 0x06, 0x07, 0x08], refs: [0x05, 0x0a], xrefs: [0x00, 0x05] },
#        { address: 0x0a, data: nil, length: 0x01, raw: [0x0a],                   refs: [],           xrefs: [0x05] },
#      ]
#    }
#    assert_equal(expected, result)
#
#    # Save/load throughout this function to make sure it's working right
#    memory = H2gb::Vault::Memory.load(memory.dump())
#    assert_not_nil(memory)
#
#    result = memory.get(address: 0x00, length: 0x10, since: 2)
#    expected = {
#      revision: 0x03,
#      entries: [
#        { address: 0x04, data: nil, length: 0x01, raw: [0x04],                   refs: [],           xrefs: [0x00] },
#        { address: 0x05, data: "C", length: 0x04, raw: [0x05, 0x06, 0x07, 0x08], refs: [0x05, 0x0a], xrefs: [0x00, 0x05] },
#        { address: 0x0a, data: nil, length: 0x01, raw: [0x0a],                   refs: [],           xrefs: [0x05] },
#      ]
#    }
#    assert_equal(expected, result)
#
#    # Save/load throughout this function to make sure it's working right
#    memory = H2gb::Vault::Memory.load(memory.dump())
#    assert_not_nil(memory)
#
#    memory.undo()
#
#    # Save/load throughout this function to make sure it's working right
#    memory = H2gb::Vault::Memory.load(memory.dump())
#    assert_not_nil(memory)
#
#    memory.undo()
#
#    # Save/load throughout this function to make sure it's working right
#    memory = H2gb::Vault::Memory.load(memory.dump())
#    assert_not_nil(memory)
#
#    memory.undo()
#
#    result = memory.get(address: 0x00, length: 0x10, since: 3)
#    expected = {
#      revision: 0x06,
#      entries: [
#        { address: 0x00, data: nil, length: 0x01, raw: [0x00], refs: [], xrefs: [] },
#        { address: 0x01, data: nil, length: 0x01, raw: [0x01], refs: [], xrefs: [] },
#        { address: 0x02, data: nil, length: 0x01, raw: [0x02], refs: [], xrefs: [] },
#        { address: 0x03, data: nil, length: 0x01, raw: [0x03], refs: [], xrefs: [] },
#        { address: 0x04, data: nil, length: 0x01, raw: [0x04], refs: [], xrefs: [] },
#        { address: 0x05, data: nil, length: 0x01, raw: [0x05], refs: [], xrefs: [] },
#        { address: 0x06, data: nil, length: 0x01, raw: [0x06], refs: [], xrefs: [] },
#        { address: 0x07, data: nil, length: 0x01, raw: [0x07], refs: [], xrefs: [] },
#        { address: 0x08, data: nil, length: 0x01, raw: [0x08], refs: [], xrefs: [] },
#        { address: 0x0a, data: nil, length: 0x01, raw: [0x0a], refs: [], xrefs: [] },
#      ]
#    }
#    assert_equal(expected, result)
#
#    result = memory.get(address: 0x00, length: 0x10, since: 4)
#    expected = {
#      revision: 0x06,
#      entries: [
#        { address: 0x00, data: nil, length: 0x01, raw: [0x00], refs: [], xrefs: [] },
#        { address: 0x01, data: nil, length: 0x01, raw: [0x01], refs: [], xrefs: [] },
#        { address: 0x02, data: nil, length: 0x01, raw: [0x02], refs: [], xrefs: [] },
#        { address: 0x03, data: nil, length: 0x01, raw: [0x03], refs: [], xrefs: [] },
#        { address: 0x04, data: nil, length: 0x01, raw: [0x04], refs: [], xrefs: [] },
#        { address: 0x05, data: nil, length: 0x01, raw: [0x05], refs: [], xrefs: [] },
#        { address: 0x06, data: nil, length: 0x01, raw: [0x06], refs: [], xrefs: [] },
#        { address: 0x07, data: nil, length: 0x01, raw: [0x07], refs: [], xrefs: [] },
#      ]
#    }
#    assert_equal(expected, result)
#
#    result = memory.get(address: 0x00, length: 0x10, since: 5)
#    expected = {
#      revision: 0x06,
#      entries: [
#        { address: 0x00, data: nil, length: 0x01, raw: [0x00], refs: [], xrefs: [] },
#        { address: 0x01, data: nil, length: 0x01, raw: [0x01], refs: [], xrefs: [] },
#        { address: 0x02, data: nil, length: 0x01, raw: [0x02], refs: [], xrefs: [] },
#        { address: 0x03, data: nil, length: 0x01, raw: [0x03], refs: [], xrefs: [] },
#        { address: 0x04, data: nil, length: 0x01, raw: [0x04], refs: [], xrefs: [] },
#        { address: 0x05, data: nil, length: 0x01, raw: [0x05], refs: [], xrefs: [] },
#      ]
#    }
#    assert_equal(expected, result)
#
#    memory.redo()
#
#    # Save/load throughout this function to make sure it's working right
#    memory = H2gb::Vault::Memory.load(memory.dump())
#    assert_not_nil(memory)
#
#    memory.redo()
#
#    # Save/load throughout this function to make sure it's working right
#    memory = H2gb::Vault::Memory.load(memory.dump())
#    assert_not_nil(memory)
#
#    memory.redo()
#
#    result = memory.get(address: 0x00, length: 0x10, since: 6)
#    expected = {
#      revision: 0x09,
#      entries: [
#        { address: 0x00, data: "A", length: 0x04, raw: [0x00, 0x01, 0x02, 0x03], refs: [0x04, 0x05], xrefs: [] },
#        { address: 0x04, data: nil, length: 0x01, raw: [0x04],                   refs: [],           xrefs: [0x00] },
#        { address: 0x05, data: "C", length: 0x04, raw: [0x05, 0x06, 0x07, 0x08], refs: [0x05, 0x0a], xrefs: [0x00, 0x05] },
#        { address: 0x0a, data: nil, length: 0x01, raw: [0x0a],                   refs: [],           xrefs: [0x05] },
#      ]
#    }
#    assert_equal(expected, result)
#
#    result = memory.get(address: 0x00, length: 0x10, since: 7)
#    expected = {
#      revision: 0x09,
#      entries: [
#        { address: 0x04, data: nil, length: 0x01, raw: [0x04],                   refs: [],           xrefs: [0x00] },
#        { address: 0x05, data: "C", length: 0x04, raw: [0x05, 0x06, 0x07, 0x08], refs: [0x05, 0x0a], xrefs: [0x00, 0x05] },
#        { address: 0x0a, data: nil, length: 0x01, raw: [0x0a],                   refs: [],           xrefs: [0x05] },
#      ]
#    }
#    assert_equal(expected, result)
#
#    # Save/load throughout this function to make sure it's working right
#    memory = H2gb::Vault::Memory.load(memory.dump())
#    assert_not_nil(memory)
#
#    result = memory.get(address: 0x00, length: 0x10, since: 8)
#    expected = {
#      revision: 0x09,
#      entries: [
#        { address: 0x04, data: nil, length: 0x01, raw: [0x04],                   refs: [],           xrefs: [0x00] },
#        { address: 0x05, data: "C", length: 0x04, raw: [0x05, 0x06, 0x07, 0x08], refs: [0x05, 0x0a], xrefs: [0x00, 0x05] },
#        { address: 0x0a, data: nil, length: 0x01, raw: [0x0a],                   refs: [],           xrefs: [0x05] },
#      ]
#    }
#    assert_equal(expected, result)
#  end
#
#  def test_bad_load()
#    assert_raises(H2gb::Vault::Memory::MemoryError) do
#      H2gb::Vault::Memory.load("Not valid YAML")
#    end
#  end
#end
#
#class H2gb::Vault::EditTest < Test::Unit::TestCase
#  def setup()
#    @memory = H2gb::Vault::Memory.new(raw: RAW)
#  end
#
#  def test_edit()
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "A", length: 0x04)
#    end
#
#    @memory.transaction() do
#      @memory.edit(address: 0x00, new_data: "B")
#    end
#
#    result = @memory.get(address: 0x00, length: 0xFF, since:0)
#    expected = {
#      revision: 0x2,
#      entries: [
#        { address: 0x00, data: "B", length: 0x04, refs: [], raw: [0x00, 0x01, 0x02, 0x03], xrefs: [] },
#      ]
#    }
#    assert_equal(expected, result)
#
#    @memory.transaction() do
#      @memory.edit(address: 0x02, new_data: "C")
#    end
#
#    result = @memory.get(address: 0x00, length: 0xFF, since:0)
#    expected = {
#      revision: 0x3,
#      entries: [
#        { address: 0x00, data: "C", length: 0x04, refs: [], raw: [0x00, 0x01, 0x02, 0x03], xrefs: [] },
#      ]
#    }
#    assert_equal(expected, result)
#  end
#
#  def test_edit_undo_redo()
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "A", length: 0x04)
#    end
#
#    @memory.transaction() do
#      @memory.edit(address: 0x00, new_data: "B")
#    end
#
#    result = @memory.get(address: 0x00, length: 0xFF, since:0)
#    expected = {
#      revision: 0x2,
#      entries: [
#        { address: 0x00, data: "B", length: 0x04, refs: [], raw: [0x00, 0x01, 0x02, 0x03], xrefs: [] },
#      ]
#    }
#    assert_equal(expected, result)
#
#    @memory.undo()
#
#    result = @memory.get(address: 0x00, length: 0xFF, since:0)
#    expected = {
#      revision: 0x3,
#      entries: [
#        { address: 0x00, data: "A", length: 0x04, refs: [], raw: [0x00, 0x01, 0x02, 0x03], xrefs: [] },
#      ]
#    }
#    assert_equal(expected, result)
#
#    @memory.redo()
#
#    result = @memory.get(address: 0x00, length: 0xFF, since:0)
#    expected = {
#      revision: 0x4,
#      entries: [
#        { address: 0x00, data: "B", length: 0x04, refs: [], raw: [0x00, 0x01, 0x02, 0x03], xrefs: [] },
#      ]
#    }
#    assert_equal(expected, result)
#
#    @memory.undo()
#
#    result = @memory.get(address: 0x00, length: 0xFF, since:0)
#    expected = {
#      revision: 0x5,
#      entries: [
#        { address: 0x00, data: "A", length: 0x04, refs: [], raw: [0x00, 0x01, 0x02, 0x03], xrefs: [] },
#      ]
#    }
#    assert_equal(expected, result)
#
#    @memory.redo()
#
#    result = @memory.get(address: 0x00, length: 0xFF, since:0)
#    expected = {
#      revision: 0x6,
#      entries: [
#        { address: 0x00, data: "B", length: 0x04, refs: [], raw: [0x00, 0x01, 0x02, 0x03], xrefs: [] },
#      ]
#    }
#    assert_equal(expected, result)
#  end
#
#  def test_edit_bad_memory()
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "A", length: 0x04)
#    end
#
#    assert_raises(H2gb::Vault::Memory::MemoryError) do
#      @memory.transaction() do
#        @memory.edit(address: 0x08, new_data: "B")
#      end
#    end
#  end
#
#  def test_edit_and_since()
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "A", length: 0x04)
#    end
#
#    @memory.transaction() do
#      @memory.edit(address: 0x02, new_data: "B")
#    end
#
#    result = @memory.get(address: 0x00, length: 0xFF, since: 1)
#    expected = {
#      revision: 0x2,
#      entries: [
#        { address: 0x00, data: "B", length: 0x04, refs: [], raw: [0x00, 0x01, 0x02, 0x03], xrefs: [] },
#      ]
#    }
#    assert_equal(expected, result)
#  end
#end
#
#class H2gb::Vault::EditTest < Test::Unit::TestCase
#  def setup()
#    @memory = H2gb::Vault::Memory.new(raw: RAW)
#  end
#
#  def test_get_raw()
#    raw = @memory.get_raw()
#    assert_equal(RAW, raw)
#  end
#end
