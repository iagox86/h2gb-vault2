require 'test_helper'

require 'h2gb/vault/memory/memory_block'
require 'h2gb/vault/memory/memory_entry'
require 'h2gb/vault/memory/memory_error'

class H2gb::Vault::MemoryBlockTest < Test::Unit::TestCase
  def setup()
    raw = (0..255).to_a().map() { |b| b.chr() }.join()
    @memory_block = H2gb::Vault::Memory::MemoryBlock.new(raw: raw)
  end

  def _test_entry(address: 0x0000, type: :type, value: "value", length: 0x0001, code_refs: [], data_refs: [], user_defined: { test: 'hi' }, comment: 'bye')
    return H2gb::Vault::Memory::MemoryEntry.new(
      address: address,
      type: type,
      value: value,
      length: length,
      code_refs: code_refs,
      data_refs: data_refs,
      user_defined: user_defined,
      comment: comment,
    )
  end

  def _deleted_entry(address:, value:)
    return H2gb::Vault::Memory::MemoryEntry.new(
      address: address,
      type: :uint8_t,
      value: value,
      length: 1,
      code_refs: [],
      data_refs: [],
      user_defined: {},
      comment: nil,
    )
  end

  def test_empty()
    @memory_block.each_entry_in_range(address: 0x00, length: 0xFF) do |address, this_entry, raw, code_xrefs, data_xrefs|
      assert_true(false)
    end
  end

  def test_single_byte()
    entry = _test_entry(address: 0x0000, length: 0x0001)
    @memory_block.insert(entry: entry, revision: 1)

    addresses = []
    entries = []
    raws = []
    code_xrefses = []
    data_xrefses = []
    @memory_block.each_entry_in_range(address: 0x0000, length: 0x0001) do |address, this_entry, raw, code_xrefs, data_xrefs|
      addresses << address
      entries << entry
      raws << raw
      code_xrefses << code_xrefs
      data_xrefses << data_xrefs
    end
    assert_equal([0x00], addresses)
    assert_equal([entry], entries)
    assert_equal([[0x00]], raws)
    assert_equal([[]], code_xrefses)
    assert_equal([[]], data_xrefses)
  end

  def test_each_entry_no_entries_in_range()
    entry = _test_entry(address: 0x0000, length: 0x0001)
    @memory_block.insert(entry: entry, revision: 1)

    @memory_block.each_entry_in_range(address: 0x0002, length: 0x0004) do |address, this_entry, raw, code_xrefs, data_xrefs|
      assert_true(false)
    end
  end

  def test_each_entry_outside_raw()
    entry = _test_entry(address: 0x0000, length: 0x0001)
    @memory_block.insert(entry: entry, revision: 1)

    assert_raises(H2gb::Vault::Memory::MemoryError) do
      @memory_block.each_entry_in_range(address: 0x00F8, length: 0x0009) do |address, this_entry, raw, code_xrefs, data_xrefs|
        assert_true(false)
      end
    end
  end

  def test_single_byte_middle_of_range()
    entry = _test_entry(address: 0x0080, length: 0x0001)
    @memory_block.insert(entry: entry, revision: 1)

    addresses = []
    entries = []
    raws = []
    code_xrefses = []
    data_xrefses = []

    @memory_block.each_entry_in_range(address: 0x0000, length: 0x0100) do |address, this_entry, raw, code_xrefs, data_xrefs|
      addresses << address
      entries << entry
      raws << raw
      code_xrefses << code_xrefs
      data_xrefses << data_xrefs
    end
    assert_equal([0x80], addresses)
    assert_equal([entry], entries)
    assert_equal([[0x80]], raws)
    assert_equal([[]], code_xrefses)
    assert_equal([[]], data_xrefses)
  end

  def test_multiple_bytes()
    entries = [
      _test_entry(address: 0x0010, length: 0x0010),
      _test_entry(address: 0x0020, length: 0x0010),
      _test_entry(address: 0x0030, length: 0x0010),
    ]

    entries.each do |entry|
      @memory_block.insert(entry: entry, revision: 1)
    end

    test_entries = []
    @memory_block.each_entry_in_range(address: 0x0000, length: 0x0100) do |address, this_entry, raw, code_xrefs, data_xrefs|
      test_entries << this_entry
    end
    assert_equal(entries, test_entries)
  end

  def test_overlapping()
    entries = [
      _test_entry(address: 0x0000, length: 0x0010),
      _test_entry(address: 0x0008, length: 0x0010),
    ]

    @memory_block.insert(entry: entries[0], revision: 1)
    assert_raises(H2gb::Vault::Memory::MemoryError) do
      @memory_block.insert(entry: entries[1], revision: 1)
    end
  end

  def test_delete()
    entry = _test_entry(address: 0x0000, length: 0x0004)

    @memory_block.insert(entry: entry, revision: 1)
    @memory_block.delete(entry: entry, revision: 1)

    results = []
    @memory_block.each_entry_in_range(address: 0x0000, length: 0x00FF) do |address, this_entry, raw, code_xrefs, data_xrefs|
      results << {
        address: address,
        this_entry: this_entry,
      }
    end

    expected = [
      { address: 0x0000, this_entry: _deleted_entry(address: 0, value: 0) },
      { address: 0x0001, this_entry: _deleted_entry(address: 1, value: 1) },
      { address: 0x0002, this_entry: _deleted_entry(address: 2, value: 2) },
      { address: 0x0003, this_entry: _deleted_entry(address: 3, value: 3) },
    ]
    assert_equal(expected, results)
  end

  def test_delete_multiple()
    entries = [
      _test_entry(address: 0x0010, length: 0x0002),
      _test_entry(address: 0x0020, length: 0x0002),
      _test_entry(address: 0x0030, length: 0x0002),
    ]

    entries.each do |entry|
      @memory_block.insert(entry: entry, revision: 1)
    end
    entries.each do |entry|
      @memory_block.delete(entry: entry, revision: 1)
    end

    test_entries = []
    @memory_block.each_entry_in_range(address: 0x0000, length: 0x0100) do |address, this_entry, raw, code_xrefs, data_xrefs|
      test_entries << this_entry
    end
    expected = [
      _deleted_entry(address: 0x0010, value: 0x10),
      _deleted_entry(address: 0x0011, value: 0x11),
      _deleted_entry(address: 0x0020, value: 0x20),
      _deleted_entry(address: 0x0021, value: 0x21),
      _deleted_entry(address: 0x0030, value: 0x30),
      _deleted_entry(address: 0x0031, value: 0x31),
    ]
    assert_equal(expected, test_entries)
  end

  def test_delete_no_such_entry()
    entry = _test_entry(address: 0x0000, length: 0x0010)

    assert_raises(H2gb::Vault::Memory::MemoryError) do
      @memory_block.delete(entry: entry, revision: 1)
    end
  end

  def test_get()
    entry = _test_entry(address: 0x0000, length: 0x0004)
    @memory_block.insert(entry: entry, revision: 1)

    result, _, _ = @memory_block.get(address: 0x0000)
    assert_equal(entry, result)

    result, _, _ = @memory_block.get(address: 0x0001)
    assert_equal(entry, result)

    result, _, _ = @memory_block.get(address: 0x0002)
    assert_equal(entry, result)

    result, _, _ = @memory_block.get(address: 0x0003)
    assert_equal(entry, result)
  end

  def test_get_adjacent()
    entry = _test_entry(address: 0x0004, length: 0x0004)
    @memory_block.insert(entry: entry, revision: 1)

    result, _, _ = @memory_block.get(address: 0x0003)
    expected = _deleted_entry(address: 0x0003, value: 0x03)
    assert_equal(expected, result)

    result, _, _ = @memory_block.get(address: 0x0008)
    expected = _deleted_entry(address: 0x0008, value: 0x08)
    assert_equal(expected, result)
  end

  def test_get_nothing()
    result, _, _ = @memory_block.get(address: 0x0000)
    expected = _deleted_entry(address: 0x0000, value: 0x00)
    assert_equal(expected, result)
  end

  def test_get_past_end()
    assert_raises(H2gb::Vault::Memory::MemoryError) do
      @memory_block.get(address: 0xFFFF)
    end
  end

  def test_since()
    entry_1 = _test_entry(address: 0x0000, length: 0x0004)
    @memory_block.insert(entry: entry_1, revision: 1)

    entry_2 = _test_entry(address: 0x0008, length: 0x0004)
    @memory_block.insert(entry: entry_2, revision: 2)

    entries = []
    @memory_block.each_entry_in_range(address: 0x0000, length: 0x0010, since: 1) do |address, this_entry, raw, code_xrefs, data_xrefs|
      entries << this_entry
    end
    assert_equal([entry_2], entries)
  end

  def test_since_delete()
    entry_1 = _test_entry(address: 0x0000, length: 0x0004)
    @memory_block.insert(entry: entry_1, revision: 1)
    @memory_block.delete(entry: entry_1, revision: 2)

    entries = []
    @memory_block.each_entry_in_range(address: 0x0000, length: 0x0010, since: 1) do |address, this_entry, raw, code_xrefs, data_xrefs|
      entries << this_entry
    end
    expected = [
      _deleted_entry(address: 0x0000, value: 0x00),
      _deleted_entry(address: 0x0001, value: 0x01),
      _deleted_entry(address: 0x0002, value: 0x02),
      _deleted_entry(address: 0x0003, value: 0x03),
    ]
    assert_equal(expected, entries)
  end

  def test_add_refs()
    entry = _test_entry(address: 0x0080, length: 0x0004, code_refs: [0x00], data_refs: [0x80, 0xF0])
    @memory_block.insert(entry: entry, revision: 1)

    results = []
    @memory_block.each_entry do |address, this_entry, raw, code_xrefs, data_xrefs|
      results << {
        address: address,
        entry: this_entry,
        code_xrefs: code_xrefs,
        data_xrefs: data_xrefs,
      }
    end

    expected = [
      {
        address: 0x00,
        entry: _deleted_entry(address: 0x0000, value: 0x00),
        code_xrefs: [0x0080],
        data_xrefs: [],
      },
      {
        address: 0x80,
        entry: entry,
        code_xrefs: [],
        data_xrefs: [0x0080],
      },
      {
        address: 0xF0,
        entry: _deleted_entry(address: 0x00F0, value: 0xF0),
        code_xrefs: [],
        data_xrefs: [0x0080],
      },
    ]

    assert_equal(expected, results)
  end

  def test_ref_to_inside_an_entry()
    entry = _test_entry(address: 0x0080, length: 0x0004, code_refs: [0x82])
    @memory_block.insert(entry: entry, revision: 1)

    results = []
    @memory_block.each_entry do |address, this_entry, raw, code_xrefs, data_xrefs|
      results << {
        address: address,
        entry: this_entry,
        code_xrefs: code_xrefs,
        data_xrefs: data_xrefs,
      }
    end

    expected = [
      {
        address: 0x80,
        entry: entry,
        code_xrefs: [],
        data_xrefs: [],
      },
    ]

    assert_equal(expected, results)
  end

  def test_delete_refs()
    entry = _test_entry(address: 0x0080, length: 0x0002, code_refs: [0x00], data_refs: [0x80, 0xF0])
    @memory_block.insert(entry: entry, revision: 1)
    @memory_block.delete(entry: entry, revision: 1)

    results = []
    @memory_block.each_entry do |address, this_entry, raw, code_xrefs, data_xrefs|
      results << {
        address: address,
        entry: this_entry,
        code_xrefs: code_xrefs,
        data_xrefs: data_xrefs,
      }
    end

    expected = [
      {
        address: 0x00,
        entry: _deleted_entry(address: 0x0000, value: 0x00),
        code_xrefs: [],
        data_xrefs: [],
      },
      {
        address: 0x80,
        entry: _deleted_entry(address: 0x0080, value: 0x80),
        code_xrefs: [],
        data_xrefs: [],
      },
      {
        address: 0x81,
        entry: _deleted_entry(address: 0x0081, value: 0x81),
        code_xrefs: [],
        data_xrefs: [],
      },
      {
        address: 0xF0,
        entry: _deleted_entry(address: 0x00F0, value: 0xF0),
        code_xrefs: [],
        data_xrefs: [],
      },
    ]

    assert_equal(expected, results)
  end


  def test_revision_going_down()
    entry = _test_entry(address: 0x0080, length: 0x0002, code_refs: [0x00], data_refs: [0x80, 0xF0])
    @memory_block.insert(entry: entry, revision: 3)

    assert_raises(H2gb::Vault::Memory::MemoryError) do
      @memory_block.delete(entry: entry, revision: 2)
    end
    assert_raises(H2gb::Vault::Memory::MemoryError) do
      @memory_block.insert(entry: entry, revision: 1)
    end
  end

end
