require 'test_helper'

require 'h2gb/vault/memory/memory'

# Generate a nice simple test memory map
RAW = (0..255).to_a().map() { |b| b.chr() }.join()

def _test_define(memory:, address:, type: :type, value: "value", length:, code_refs: [], data_refs: [], user_defined: { test: 'hi' }, comment: 'bye', do_transaction: true)
  if do_transaction
    memory.transaction() do
      memory.define(
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
  else
    memory.define(
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
end

def _test_undefine(memory:, address:, length:, do_transaction:true)
  if do_transaction
    memory.transaction() do
      memory.undefine(address: address, length: length)
    end
  else
    memory.undefine(address: address, length: length)
  end
end

def _test_entry(address:, type: :type, value: "value", length:, code_refs: [], data_refs: [], user_defined: { test: 'hi' }, comment: 'bye', raw:, code_xrefs: [], data_xrefs: [])
  return {
    address:      address,
    type:         type,
    value:        value,
    length:       length,
    code_refs:    code_refs,
    data_refs:    data_refs,
    user_defined: user_defined,
    comment:      comment,
    raw:          raw,
    code_xrefs:   code_xrefs,
    data_xrefs:   data_xrefs,
  }
end

def _test_entry_deleted(address:, raw:, code_xrefs: [], data_xrefs: [])
  return {
    address:      address,
    type:         :uint8_t,
    value:        raw[0],
    length:       1,
    code_refs:    [],
    data_refs:    [],
    user_defined: {},
    comment:      nil,
    raw:          raw,
    code_xrefs:   code_xrefs,
    data_xrefs:   data_xrefs,
  }
end

class H2gb::Vault::InsertTest < Test::Unit::TestCase
  def setup()
    @memory = H2gb::Vault::Memory.new(raw: RAW)
  end

  def test_empty()
    result = @memory.get(address: 0x00, length: 0xFF, since:0)
    expected = {
      revision: 0x00,
      entries: [],
    }
    assert_equal(expected, result)
  end

  def test_single_entry()
    _test_define(memory: @memory, address: 0x0000, length: 0x0001)

    result = @memory.get(address: 0x00, length: 0x01, since:0)
    expected = {
      revision: 0x01,
      entries: [
        _test_entry(address: 0x00, length: 0x01, raw: [0x00])
      ]
    }

    assert_equal(expected, result)
  end

  def test_get_longer_entry()
    _test_define(memory: @memory, address: 0x0000, length: 0x0008)

    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
    expected = {
      revision: 0x01,
      entries: [
        _test_entry(address: 0x00, length: 0x08, raw: "\x00\x01\x02\x03\x04\x05\x06\x07".bytes())
      ]
    }

    assert_equal(expected, result)
  end

  def test_get_entry_in_middle()
    _test_define(memory: @memory, address: 0x0080, length: 0x0004)

    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
    expected = {
      revision: 0x01,
      entries: [
        _test_entry(address: 0x80, length: 0x04, raw: "\x80\x81\x82\x83".bytes())
      ]
    }

    assert_equal(expected, result)
  end

  def test_two_adjacent()
    _test_define(memory: @memory, address: 0x0000, length: 0x0002)
    _test_define(memory: @memory, address: 0x0002, length: 0x0002)

    result = @memory.get(address: 0x00, length: 0xFF, since: 0)

    expected = {
      revision: 0x02,
      entries: [
        _test_entry(address: 0x00, length: 0x02, raw: "\x00\x01".bytes()),
        _test_entry(address: 0x02, length: 0x02, raw: "\x02\x03".bytes()),
      ]
    }

    assert_equal(expected, result)
  end

  def test_two_adjacent_in_same_transaction()
    @memory.transaction do
      _test_define(memory: @memory, address: 0x0000, length: 0x0002, do_transaction: false)
      _test_define(memory: @memory, address: 0x0002, length: 0x0002, do_transaction: false)
    end

    result = @memory.get(address: 0x00, length: 0xFF, since: 0)

    expected = {
      revision: 1,
      entries: [
        _test_entry(address: 0x00, length: 0x02, raw: "\x00\x01".bytes()),
        _test_entry(address: 0x02, length: 0x02, raw: "\x02\x03".bytes()),
      ]
    }

    assert_equal(expected, result)
  end

  def test_two_not_adjacent()
    _test_define(memory: @memory, address: 0x0000, length: 0x0002)
    _test_define(memory: @memory, address: 0x0080, length: 0x0002)

    result = @memory.get(address: 0x00, length: 0xFF, since: 0)

    expected = {
      revision: 0x02,
      entries: [
        _test_entry(address: 0x00, length: 0x02, raw: "\x00\x01".bytes()),
        _test_entry(address: 0x80, length: 0x02, raw: "\x80\x81".bytes()),
      ]
    }

    assert_equal(expected, result)
  end

  def test_overwrite()
    _test_define(memory: @memory, address: 0x0000, length: 0x0002, user_defined: { test: 'A'} )
    _test_define(memory: @memory, address: 0x0000, length: 0x0002, user_defined: { test: 'B'} )

    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
    expected = {
      revision: 0x02,
      entries: [
        _test_entry(address: 0x00, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'B'} ),
      ]
    }

    assert_equal(expected, result)
  end

  def test_overwrite_by_shorter()
    _test_define(memory: @memory, address: 0x0000, length: 0x0004, user_defined: { test: 'A'} )
    _test_define(memory: @memory, address: 0x0000, length: 0x0001, user_defined: { test: 'B'} )

    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
    expected = {
      revision: 0x02,
      entries: [
        _test_entry(address: 0x00, length: 0x01, raw: "\x00".bytes(), user_defined: { test: 'B'} ),
        _test_entry_deleted(address: 0x01, raw: "\x01".bytes()),
        _test_entry_deleted(address: 0x02, raw: "\x02".bytes()),
        _test_entry_deleted(address: 0x03, raw: "\x03".bytes()),
      ]
    }

    assert_equal(expected, result)
  end

  def test_overwrite_middle()
    _test_define(memory: @memory, address: 0x0000, length: 0x0008, user_defined: { test: 'A'} )
    _test_define(memory: @memory, address: 0x0004, length: 0x0002, user_defined: { test: 'B'} )

    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
    expected = {
      revision: 0x02,
      entries: [
        _test_entry_deleted(address: 0x00, raw: "\x00".bytes()),
        _test_entry_deleted(address: 0x01, raw: "\x01".bytes()),
        _test_entry_deleted(address: 0x02, raw: "\x02".bytes()),
        _test_entry_deleted(address: 0x03, raw: "\x03".bytes()),
        _test_entry(address: 0x04, length: 0x02, raw: "\x04\x05".bytes(), user_defined: { test: 'B'} ),
        _test_entry_deleted(address: 0x06, raw: "\x06".bytes()),
        _test_entry_deleted(address: 0x07, raw: "\x07".bytes()),
      ]
    }

    assert_equal(expected, result)
  end

  def test_overwrite_multiple()
    _test_define(memory: @memory, address: 0x0000, length: 0x0002, user_defined: { test: 'A'} )
    _test_define(memory: @memory, address: 0x0002, length: 0x0002, user_defined: { test: 'B'} )
    _test_define(memory: @memory, address: 0x0001, length: 0x0002, user_defined: { test: 'C'} )

    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
    expected = {
      revision: 0x03,
      entries: [
        _test_entry_deleted(address: 0x00, raw: "\x00".bytes()),
        _test_entry(address: 0x01, length: 0x02, raw: "\x01\x02".bytes(), user_defined: { test: 'C'} ),
        _test_entry_deleted(address: 0x03, raw: "\x03".bytes()),
      ]
    }

    assert_equal(expected, result)
  end

  def test_overwrite_multiple_with_gap()
    _test_define(memory: @memory, address: 0x0000, length: 0x0002, user_defined: { test: 'A'} )
    _test_define(memory: @memory, address: 0x0010, length: 0x0010, user_defined: { test: 'B'} )
    _test_define(memory: @memory, address: 0x0000, length: 0x0080, user_defined: { test: 'C'} )

    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
    expected = {
      revision: 0x03,
      entries: [
        _test_entry(address: 0x00, length: 0x80, raw: (0x00..0x7F).to_a(), user_defined: { test: 'C'} ),
      ]
    }

    assert_equal(expected, result)
  end

  def test_refs()
    _test_define(memory: @memory, address: 0x0000, length: 0x0001, code_refs: [0x10], data_refs: [0x20])

    result = @memory.get(address: 0x00, length: 0xFF, since:0)
    expected = {
      revision: 0x01,
      entries: [
        _test_entry(address: 0x00, length: 0x01, raw: [0x00], code_refs: [0x10], data_refs: [0x20]),
        _test_entry_deleted(address: 0x10, raw: "\x10".bytes(), code_xrefs: [0x0000]),
        _test_entry_deleted(address: 0x20, raw: "\x20".bytes(), data_xrefs: [0x0000]),
      ]
    }

    assert_equal(expected, result)
  end

  def test_undefine()
    _test_define(memory: @memory, address: 0x0000, length: 0x0002)
    _test_undefine(memory: @memory, address: 0x0000, length: 0x0001)

    result = @memory.get(address: 0x00, length: 0xFF, since:0)
    expected = {
      revision: 0x02,
      entries: [
        _test_entry_deleted(address: 0x00, raw: "\x00".bytes()),
        _test_entry_deleted(address: 0x01, raw: "\x01".bytes()),
      ]
    }

    assert_equal(expected, result)
  end

  def test_undefine_multiple()
    _test_define(memory: @memory, address: 0x0000, length: 0x0001)
    _test_define(memory: @memory, address: 0x0001, length: 0x0002)
    _test_define(memory: @memory, address: 0x0004, length: 0x0002)
    _test_define(memory: @memory, address: 0x0007, length: 0x0002)
    _test_undefine(memory: @memory, address: 1, length: 4)

    result = @memory.get(address: 0x00, length: 0xFF, since:0)
    expected = {
      revision: 0x05,
      entries: [
        _test_entry(address: 0x00, length: 0x01, raw: "\x00".bytes()),
        _test_entry_deleted(address: 0x01, raw: "\x01".bytes()),
        _test_entry_deleted(address: 0x02, raw: "\x02".bytes()),
        _test_entry_deleted(address: 0x04, raw: "\x04".bytes()),
        _test_entry_deleted(address: 0x05, raw: "\x05".bytes()),
        _test_entry(address: 0x07, length: 0x02, raw: "\x07\x08".bytes()),
      ]
    }

    assert_equal(expected, result)
  end

  def test_undefine_refs()
    _test_define(memory: @memory, address: 0x0000, length: 0x0001, code_refs: [0x10], data_refs: [0x20])
    _test_undefine(memory: @memory, address: 0x0000, length: 0x0001)

    result = @memory.get(address: 0x00, length: 0xFF, since:0)
    expected = {
      revision: 0x02,
      entries: [
        _test_entry_deleted(address: 0x00, raw: "\x00".bytes()),
        _test_entry_deleted(address: 0x10, raw: "\x10".bytes()),
        _test_entry_deleted(address: 0x20, raw: "\x20".bytes()),
      ]
    }

    assert_equal(expected, result)
  end

  def test_define_invalid()
    assert_raises(H2gb::Vault::Memory::MemoryError) do
      _test_define(memory: @memory, address: 0x0100, length: 0x01)
    end
  end

  def test_define_invalid_refs_string()
    assert_raises(H2gb::Vault::Memory::MemoryError) do
      _test_define(memory: @memory, address: 0x0000, length: 0x0001, code_refs: [0xFFFF])
    end
    assert_raises(H2gb::Vault::Memory::MemoryError) do
      _test_define(memory: @memory, address: 0x0000, length: 0x0001, data_refs: [0xFFFF])
    end

    # I accidentally created a bug by doing this in the API, so making sure I test for it
    assert_raises(H2gb::Vault::Memory::MemoryError) do
      _test_define(memory: @memory, address: 0x0000, length: 0x0001, data_refs: [nil])
    end
  end
end

###
## Since we already use transactions throughout other tests, this will simply
## ensure that transactions are required.
###
class H2gb::Vault::TransactionTest < Test::Unit::TestCase
  def setup()
    @memory = H2gb::Vault::Memory.new(raw: RAW)
  end

  def test_add_transaction()
    assert_raises(H2gb::Vault::Memory::MemoryError) do
      _test_define(memory: @memory, address: 0x0000, length: 0x0002, do_transaction: false)
    end
  end

  def test_undefine_transaction()
    assert_raises(H2gb::Vault::Memory::MemoryError) do
      _test_undefine(memory: @memory, address: 0x0000, length: 0x0002, do_transaction: false)
    end
  end

  def test_revision_increment()
    result = @memory.get(address: 0x00, length: 0x00, since: 0)
    assert_equal(0, result[:revision])

    @memory.transaction() do
    end

    result = @memory.get(address: 0x00, length: 0x00, since: 0)
    assert_equal(1, result[:revision])
  end
end

class H2gb::Vault::DeleteTest < Test::Unit::TestCase
  def setup()
    @memory = H2gb::Vault::Memory.new(raw: RAW)
  end

  def test_delete_nothing()
    _test_undefine(memory: @memory, address: 0x00, length: 0xFF)

    result = @memory.get(address: 0x00, length: 0xFF, since: 0)

    expected = {
      revision: 0x01,
      entries: [],
    }
    assert_equal(expected, result)
  end

  def test_delete_one_byte()
    _test_define(memory: @memory, address: 0x0000, length: 0x0001, user_defined: { test: 'A'} )
    _test_undefine(memory: @memory, address: 0x0000, length: 0x0001)

    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
    expected = {
      revision: 0x02,
      entries: [
        _test_entry_deleted(address: 0x0000, raw: "\x00".bytes()),
      ],
    }

    assert_equal(expected, result)
  end

  def test_delete_multi_bytes()
    _test_define(memory: @memory, address: 0x0000, length: 0x0004, user_defined: { test: 'A'} )
    _test_undefine(memory: @memory, address: 0, length: 1)

    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
    expected = {
      revision: 0x02,
      entries: [
        _test_entry_deleted(address: 0x0000, raw: "\x00".bytes()),
        _test_entry_deleted(address: 0x0001, raw: "\x01".bytes()),
        _test_entry_deleted(address: 0x0002, raw: "\x02".bytes()),
        _test_entry_deleted(address: 0x0003, raw: "\x03".bytes()),
      ],
    }

    assert_equal(expected, result)
  end

  def test_delete_zero_bytes()
    _test_define(memory: @memory, address: 0x0000, length: 0x0010, user_defined: { test: 'A'} )
    _test_undefine(memory: @memory, address: 8, length: 0)

    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
    expected = {
      revision: 0x02,
      entries: [
        _test_entry(address: 0x00, length: 0x10, raw: (0x00..0x0F).to_a(), user_defined: { test: 'A'} ),
      ],
    }

    assert_equal(expected, result)
  end

  def test_delete_just_start()
    _test_define(memory: @memory, address: 0x0000, length: 0x0004, user_defined: { test: 'A'} )
    _test_undefine(memory: @memory, address: 0000, length: 0x0001)

    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
    expected = {
      revision: 0x02,
      entries: [
        _test_entry_deleted(address: 0x0000, raw: "\x00".bytes()),
        _test_entry_deleted(address: 0x0001, raw: "\x01".bytes()),
        _test_entry_deleted(address: 0x0002, raw: "\x02".bytes()),
        _test_entry_deleted(address: 0x0003, raw: "\x03".bytes()),
      ],
    }

    assert_equal(expected, result)
  end

  def test_delete_just_middle()
    _test_define(memory: @memory, address: 0x0000, length: 0x0004, user_defined: { test: 'A'} )
    _test_undefine(memory: @memory, address: 0002, length: 0x0001)

    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
    expected = {
      revision: 0x02,
      entries: [
        _test_entry_deleted(address: 0x0000, raw: "\x00".bytes()),
        _test_entry_deleted(address: 0x0001, raw: "\x01".bytes()),
        _test_entry_deleted(address: 0x0002, raw: "\x02".bytes()),
        _test_entry_deleted(address: 0x0003, raw: "\x03".bytes()),
      ],
    }

    assert_equal(expected, result)
  end

  def test_delete_multiple_entries()
    _test_define(memory: @memory, address: 0x0000, length: 0x0004, user_defined: { test: 'A'} )
    _test_define(memory: @memory, address: 0x0004, length: 0x0004, user_defined: { test: 'B'} )
    _test_define(memory: @memory, address: 0x0008, length: 0x0004, user_defined: { test: 'C'} )
    _test_undefine(memory: @memory, address: 0x0000, length: 0xFF)

    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
    expected = {
      revision: 0x04,
      entries: [
        _test_entry_deleted(address: 0x0000, raw: "\x00".bytes()),
        _test_entry_deleted(address: 0x0001, raw: "\x01".bytes()),
        _test_entry_deleted(address: 0x0002, raw: "\x02".bytes()),
        _test_entry_deleted(address: 0x0003, raw: "\x03".bytes()),
        _test_entry_deleted(address: 0x0004, raw: "\x04".bytes()),
        _test_entry_deleted(address: 0x0005, raw: "\x05".bytes()),
        _test_entry_deleted(address: 0x0006, raw: "\x06".bytes()),
        _test_entry_deleted(address: 0x0007, raw: "\x07".bytes()),
        _test_entry_deleted(address: 0x0008, raw: "\x08".bytes()),
        _test_entry_deleted(address: 0x0009, raw: "\x09".bytes()),
        _test_entry_deleted(address: 0x000a, raw: "\x0a".bytes()),
        _test_entry_deleted(address: 0x000b, raw: "\x0b".bytes()),
      ],
    }

    assert_equal(expected, result)
  end

  def test_delete_but_leave_adjacent()
    _test_define(memory: @memory, address: 0x0000, length: 0x0004, user_defined: { test: 'A'} )
    _test_define(memory: @memory, address: 0x0004, length: 0x0004, user_defined: { test: 'B'} )
    _test_define(memory: @memory, address: 0x0008, length: 0x0004, user_defined: { test: 'C'} )
    _test_undefine(memory: @memory, address: 0x0004, length: 0x04)

    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
    expected = {
      revision: 0x04,
      entries: [
        _test_entry(address: 0x0000, length: 0x04, raw: "\x00\x01\x02\x03".bytes(), user_defined: { test: 'A'} ),
        _test_entry_deleted(address: 0x0004, raw: "\x04".bytes()),
        _test_entry_deleted(address: 0x0005, raw: "\x05".bytes()),
        _test_entry_deleted(address: 0x0006, raw: "\x06".bytes()),
        _test_entry_deleted(address: 0x0007, raw: "\x07".bytes()),
        _test_entry(address: 0x0008, length: 0x04, raw: "\x08\x09\x0a\x0b".bytes(), user_defined: { test: 'C'} ),
      ],
    }

    assert_equal(expected, result)
  end

  def test_delete_multi_but_leave_adjacent()
    _test_define(memory: @memory, address: 0x0000, length: 0x0004, user_defined: { test: 'A'} )
    _test_define(memory: @memory, address: 0x0004, length: 0x0004, user_defined: { test: 'B'} )
    _test_define(memory: @memory, address: 0x0008, length: 0x0004, user_defined: { test: 'C'} )
    _test_define(memory: @memory, address: 0x000c, length: 0x0004, user_defined: { test: 'D'} )
    _test_undefine(memory: @memory, address: 0x0004, length: 0x08)

    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
    expected = {
      revision: 0x05,
      entries: [
        _test_entry(address: 0x0000, length: 0x04, raw: "\x00\x01\x02\x03".bytes(), user_defined: { test: 'A'} ),
        _test_entry_deleted(address: 0x0004, raw: "\x04".bytes()),
        _test_entry_deleted(address: 0x0005, raw: "\x05".bytes()),
        _test_entry_deleted(address: 0x0006, raw: "\x06".bytes()),
        _test_entry_deleted(address: 0x0007, raw: "\x07".bytes()),
        _test_entry_deleted(address: 0x0008, raw: "\x08".bytes()),
        _test_entry_deleted(address: 0x0009, raw: "\x09".bytes()),
        _test_entry_deleted(address: 0x000a, raw: "\x0a".bytes()),
        _test_entry_deleted(address: 0x000b, raw: "\x0b".bytes()),
        _test_entry(address: 0x000c, length: 0x04, raw: "\x0c\x0d\x0e\x0f".bytes(), user_defined: { test: 'D'} ),
      ],
    }

    assert_equal(expected, result)
  end
end

class H2gb::Vault::UndoTest < Test::Unit::TestCase
  def setup()
    @memory = H2gb::Vault::Memory.new(raw: RAW)
  end

  def test_basic_undo()
    _test_define(memory: @memory, address: 0x0000, length: 0x0002, user_defined: { test: 'A'} )
    _test_define(memory: @memory, address: 0x0002, length: 0x0002, user_defined: { test: 'B'} )

    @memory.undo()

    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
    expected = {
      revision: 0x03,
      entries: [
        _test_entry(address: 0x0000, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'A'} ),
        _test_entry_deleted(address: 0x0002, raw: "\x02".bytes()),
        _test_entry_deleted(address: 0x0003, raw: "\x03".bytes()),
      ],
    }

    assert_equal(expected, result)
  end

  def test_undo_multiple_steps()
    _test_define(memory: @memory, address: 0x0000, length: 0x0002, user_defined: { test: 'A'} )
    _test_define(memory: @memory, address: 0x0002, length: 0x0002, user_defined: { test: 'B'} )
    _test_define(memory: @memory, address: 0x0004, length: 0x0002, user_defined: { test: 'C'} )

    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
    expected = {
      revision: 0x03,
      entries: [
        _test_entry(address: 0x0000, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'A'} ),
        _test_entry(address: 0x0002, length: 0x02, raw: "\x02\x03".bytes(), user_defined: { test: 'B'} ),
        _test_entry(address: 0x0004, length: 0x02, raw: "\x04\x05".bytes(), user_defined: { test: 'C'} ),
      ]
    }
    assert_equal(expected, result)

    @memory.undo()
    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
    expected = {
      revision: 0x04,
      entries: [
        _test_entry(address: 0x0000, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'A'} ),
        _test_entry(address: 0x0002, length: 0x02, raw: "\x02\x03".bytes(), user_defined: { test: 'B'} ),
        _test_entry_deleted(address: 0x0004, raw: "\x04".bytes()),
        _test_entry_deleted(address: 0x0005, raw: "\x05".bytes()),
      ]
    }
    assert_equal(expected, result)

    @memory.undo()
    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
    expected = {
      revision: 0x05,
      entries: [
        _test_entry(address: 0x0000, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'A'} ),
        _test_entry_deleted(address: 0x0002, raw: "\x02".bytes()),
        _test_entry_deleted(address: 0x0003, raw: "\x03".bytes()),
        _test_entry_deleted(address: 0x0004, raw: "\x04".bytes()),
        _test_entry_deleted(address: 0x0005, raw: "\x05".bytes()),
      ]
    }
    assert_equal(expected, result)

    @memory.undo()
    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
    expected = {
      revision: 0x06,
      entries: [
        _test_entry_deleted(address: 0x0000, raw: "\x00".bytes()),
        _test_entry_deleted(address: 0x0001, raw: "\x01".bytes()),
        _test_entry_deleted(address: 0x0002, raw: "\x02".bytes()),
        _test_entry_deleted(address: 0x0003, raw: "\x03".bytes()),
        _test_entry_deleted(address: 0x0004, raw: "\x04".bytes()),
        _test_entry_deleted(address: 0x0005, raw: "\x05".bytes()),
      ],
    }
    assert_equal(expected, result)
  end

  def test_undo_then_set()
    _test_define(memory: @memory, address: 0x0000, length: 0x0002, user_defined: { test: 'A'} )
    _test_define(memory: @memory, address: 0x0002, length: 0x0002, user_defined: { test: 'B'} )
    @memory.undo()
    _test_define(memory: @memory, address: 0x0004, length: 0x0002, user_defined: { test: 'C'} )

    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
    expected = {
      revision: 4,
      entries: [
        _test_entry(address: 0x0000, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'A'} ),
        _test_entry_deleted(address: 0x0002, raw: "\x02".bytes()),
        _test_entry_deleted(address: 0x0003, raw: "\x03".bytes()),
        _test_entry(address: 0x0004, length: 0x02, raw: "\x04\x05".bytes(), user_defined: { test: 'C'} ),
      ]
    }

    assert_equal(expected, result)
  end

  ##
  # Attempts to exercise the situation where an undo would inappropriately undo
  # another undo.
  ##
  def test_undo_across_other_undos()
    _test_define(memory: @memory, address: 0x0000, length: 0x0002, user_defined: { test: 'A'} )
    _test_define(memory: @memory, address: 0x0002, length: 0x0002, user_defined: { test: 'B'} )

    @memory.undo() # undo B

    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
    expected = {
      revision: 0x03,
      entries: [
        _test_entry(address: 0x0000, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'A'} ),
        _test_entry_deleted(address: 0x0002, raw: "\x02".bytes()),
        _test_entry_deleted(address: 0x0003, raw: "\x03".bytes()),
      ],
    }
    assert_equal(expected, result)

    _test_define(memory: @memory, address: 0x0004, length: 0x0002, user_defined: { test: 'C'} )

    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
    expected = {
      revision: 0x04,
      entries: [
        _test_entry(address: 0x0000, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'A'} ),
        _test_entry_deleted(address: 0x0002, raw: "\x02".bytes()),
        _test_entry_deleted(address: 0x0003, raw: "\x03".bytes()),
        _test_entry(address: 0x0004, length: 0x02, raw: "\x04\x05".bytes(), user_defined: { test: 'C'} ),
      ],
    }
    assert_equal(expected, result)

    @memory.undo() # undo C

    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
    expected = {
      revision: 0x05,
      entries: [
        _test_entry(address: 0x0000, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'A'} ),
        _test_entry_deleted(address: 0x0002, raw: "\x02".bytes()),
        _test_entry_deleted(address: 0x0003, raw: "\x03".bytes()),
        _test_entry_deleted(address: 0x0004, raw: "\x04".bytes()),
        _test_entry_deleted(address: 0x0005, raw: "\x05".bytes()),
      ],
    }
    assert_equal(expected, result)

    @memory.undo() # undo A

    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
    expected = {
      revision: 0x06,
      entries: [
        _test_entry_deleted(address: 0x0000, raw: "\x00".bytes()),
        _test_entry_deleted(address: 0x0001, raw: "\x01".bytes()),
        _test_entry_deleted(address: 0x0002, raw: "\x02".bytes()),
        _test_entry_deleted(address: 0x0003, raw: "\x03".bytes()),
        _test_entry_deleted(address: 0x0004, raw: "\x04".bytes()),
        _test_entry_deleted(address: 0x0005, raw: "\x05".bytes()),
      ],
    }
    assert_equal(expected, result)
  end

  def test_undo_then_set_then_undo_again()
    _test_define(memory: @memory, address: 0x0000, length: 0x0002, user_defined: { test: 'A'} )
    _test_define(memory: @memory, address: 0x0002, length: 0x0002, user_defined: { test: 'B'} )

    @memory.undo()

    _test_define(memory: @memory, address: 0x0004, length: 0x0002, user_defined: { test: 'C'} )

    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
    expected = {
      revision: 0x04,
      entries: [
        _test_entry(address: 0x0000, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'A'} ),
        _test_entry_deleted(address: 0x0002, raw: "\x02".bytes()),
        _test_entry_deleted(address: 0x0003, raw: "\x03".bytes()),
        _test_entry(address: 0x0004, length: 0x02, raw: "\x04\x05".bytes(), user_defined: { test: 'C'} ),
      ]
    }
    assert_equal(expected, result)

    @memory.undo()
    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
    expected = {
      revision: 0x05,
      entries: [
        _test_entry(address: 0x0000, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'A'} ),
        _test_entry_deleted(address: 0x0002, raw: "\x02".bytes()),
        _test_entry_deleted(address: 0x0003, raw: "\x03".bytes()),
        _test_entry_deleted(address: 0x0004, raw: "\x04".bytes()),
        _test_entry_deleted(address: 0x0005, raw: "\x05".bytes()),
      ]
    }
    assert_equal(expected, result)
  end

  def test_undo_too_much()
    _test_define(memory: @memory, address: 0x0000, length: 0x0002, user_defined: { test: 'A'} )

    @memory.undo()
    @memory.undo()
    @memory.undo()
    @memory.undo()
    @memory.undo()
    @memory.undo()

    _test_define(memory: @memory, address: 0x0001, length: 0x0002, user_defined: { test: 'B'} )
    result = @memory.get(address: 0x00, length: 0xFF, since: 0)

    expected = {
      revision: 0x03,
      entries: [
        _test_entry_deleted(address: 0x0000, raw: "\x00".bytes()),
        _test_entry(address: 0x0001, length: 0x02, raw: "\x01\x02".bytes(), user_defined: { test: 'B'} ),
      ]
    }

    assert_equal(expected, result)
  end

  def test_undo_overwrite()
    _test_define(memory: @memory, address: 0x0000, length: 0x0002, user_defined: { test: 'A'} )
    _test_define(memory: @memory, address: 0x0001, length: 0x0002, user_defined: { test: 'B'} )

    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
    expected = {
      revision: 0x02,
      entries: [
        _test_entry_deleted(address: 0x0000, raw: "\x00".bytes()),
        _test_entry(address: 0x0001, length: 0x02, raw: "\x01\x02".bytes(), user_defined: { test: 'B'} ),
      ]
    }
    assert_equal(expected, result)

    @memory.undo()
    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
    expected = {
      revision: 0x03,
      entries: [
        _test_entry(address: 0x0000, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'A'} ),
        _test_entry_deleted(address: 0x0002, raw: "\x02".bytes()),
      ]
    }
    assert_equal(expected, result)
  end

  def test_transaction_undo()
    @memory.transaction() do
      _test_define(memory: @memory, address: 0x0000, length: 0x0002, user_defined: { test: 'A'}, do_transaction: false )
      _test_define(memory: @memory, address: 0x0002, length: 0x0002, user_defined: { test: 'B'}, do_transaction: false )
    end

    @memory.transaction() do
      _test_define(memory: @memory, address: 0x0001, length: 0x0002, user_defined: { test: 'C'}, do_transaction: false )
      _test_define(memory: @memory, address: 0x0003, length: 0x0002, user_defined: { test: 'D'}, do_transaction: false )
    end

    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
    expected = {
      revision: 0x02,
      entries: [
        _test_entry_deleted(address: 0x0000, raw: "\x00".bytes()),
        _test_entry(address: 0x0001, length: 0x02, raw: "\x01\x02".bytes(), user_defined: { test: 'C'} ),
        _test_entry(address: 0x0003, length: 0x02, raw: "\x03\x04".bytes(), user_defined: { test: 'D'} ),
      ]
    }
    assert_equal(expected, result)

    @memory.undo()

    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
    expected = {
      revision: 0x03,
      entries: [
        { address: 0x00, data: "A", length: 0x02, refs: [], raw: [0x00, 0x01], xrefs: [] },
        { address: 0x02, data: "B", length: 0x02, refs: [], raw: [0x02, 0x03], xrefs: [] },
        { address: 0x04, data: nil, length: 0x01, refs: [], raw: [0x04], xrefs: [] },
      ]
    }
    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
    expected = {
      revision: 0x03,
      entries: [
        _test_entry(address: 0x0000, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'A'} ),
        _test_entry(address: 0x0002, length: 0x02, raw: "\x02\x03".bytes(), user_defined: { test: 'B'} ),
        _test_entry_deleted(address: 0x0004, raw: "\x04".bytes()),
      ]
    }
    assert_equal(expected, result)
  end

  def test_repeat_undo_redo()
    _test_define(memory: @memory, address: 0x0000, length: 0x0002, user_defined: { test: 'A'} )
    _test_define(memory: @memory, address: 0x0000, length: 0x0002, user_defined: { test: 'B'} )

    @memory.undo()

    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
    expected = {
      revision: 0x03,
      entries: [
        _test_entry(address: 0x0000, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'A'} ),

      ],
    }
    assert_equal(expected, result)

    @memory.redo()

    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
    expected = {
      revision: 0x04,
      entries: [
        _test_entry(address: 0x0000, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'B'} ),
      ],
    }
    assert_equal(expected, result)

    @memory.undo()

    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
    expected = {
      revision: 0x05,
      entries: [
        _test_entry(address: 0x0000, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'A'} ),
      ],
    }
    assert_equal(expected, result)

    @memory.redo()

    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
    expected = {
      revision: 0x06,
      entries: [
        _test_entry(address: 0x0000, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'B'} ),
      ],
    }
    assert_equal(expected, result)

    @memory.undo()

    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
    expected = {
      revision: 0x07,
      entries: [
        _test_entry(address: 0x0000, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'A'} ),
      ],
    }
    assert_equal(expected, result)

    @memory.redo()

    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
    expected = {
      revision: 0x08,
      entries: [
        _test_entry(address: 0x0000, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'B'} ),
      ],
    }
    assert_equal(expected, result)
  end
end

class H2gb::Vault::RedoTest < Test::Unit::TestCase
  def setup()
    @memory = H2gb::Vault::Memory.new(raw: RAW)
  end

  def test_basic_redo()
    _test_define(memory: @memory, address: 0x0000, length: 0x0002, user_defined: { test: 'A'} )
    _test_define(memory: @memory, address: 0x0002, length: 0x0002, user_defined: { test: 'B'} )
    @memory.undo()
    @memory.redo()

    result = @memory.get(address: 0x00, length: 0xFF, since: 0)

    expected = {
      revision: 0x04,
      entries: [
        _test_entry(address: 0x0000, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'A'} ),
        _test_entry(address: 0x0002, length: 0x02, raw: "\x02\x03".bytes(), user_defined: { test: 'B'} ),
      ]
    }

    assert_equal(expected, result)
  end

  def test_redo_multiple_steps()
    _test_define(memory: @memory, address: 0x0000, length: 0x0002, user_defined: { test: 'A'} )
    _test_define(memory: @memory, address: 0x0002, length: 0x0002, user_defined: { test: 'B'} )
    _test_define(memory: @memory, address: 0x0004, length: 0x0002, user_defined: { test: 'C'} )

    @memory.undo()
    @memory.undo()
    @memory.undo()

    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
    expected = {
      revision: 0x06,
      entries: [
        _test_entry_deleted(address: 0x0000, raw: "\x00".bytes()),
        _test_entry_deleted(address: 0x0001, raw: "\x01".bytes()),
        _test_entry_deleted(address: 0x0002, raw: "\x02".bytes()),
        _test_entry_deleted(address: 0x0003, raw: "\x03".bytes()),
        _test_entry_deleted(address: 0x0004, raw: "\x04".bytes()),
        _test_entry_deleted(address: 0x0005, raw: "\x05".bytes()),
      ]
    }
    assert_equal(expected, result)

    @memory.redo()
    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
    expected = {
      revision: 0x07,
      entries: [
        _test_entry(address: 0x0000, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'A'} ),
        _test_entry_deleted(address: 0x0002, raw: "\x02".bytes()),
        _test_entry_deleted(address: 0x0003, raw: "\x03".bytes()),
        _test_entry_deleted(address: 0x0004, raw: "\x04".bytes()),
        _test_entry_deleted(address: 0x0005, raw: "\x05".bytes()),
      ]
    }
    assert_equal(expected, result)

    @memory.redo()
    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
    expected = {
      revision: 0x08,
      entries: [
        _test_entry(address: 0x0000, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'A'} ),
        _test_entry(address: 0x0002, length: 0x02, raw: "\x02\x03".bytes(), user_defined: { test: 'B'} ),
        _test_entry_deleted(address: 0x0004, raw: "\x04".bytes()),
        _test_entry_deleted(address: 0x0005, raw: "\x05".bytes()),
      ]
    }
    assert_equal(expected, result)

    @memory.redo()
    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
    expected = {
      revision: 0x09,
      entries: [
        _test_entry(address: 0x0000, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'A'} ),
        _test_entry(address: 0x0002, length: 0x02, raw: "\x02\x03".bytes(), user_defined: { test: 'B'} ),
        _test_entry(address: 0x0004, length: 0x02, raw: "\x04\x05".bytes(), user_defined: { test: 'C'} ),
      ]
    }
    assert_equal(expected, result)
  end

  def test_redo_then_set()
    _test_define(memory: @memory, address: 0x0000, length: 0x0002, user_defined: { test: 'A'} )
    _test_define(memory: @memory, address: 0x0002, length: 0x0002, user_defined: { test: 'B'} )
    @memory.undo()
    @memory.redo()
    _test_define(memory: @memory, address: 0x0000, length: 0x0002, user_defined: { test: 'C'} )

    result = @memory.get(address: 0x00, length: 0xFF, since: 0)

    expected = {
      revision: 0x05,
      entries: [
        _test_entry(address: 0x0000, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'C'} ),
        _test_entry(address: 0x0002, length: 0x02, raw: "\x02\x03".bytes(), user_defined: { test: 'B'} ),
      ]
    }

    assert_equal(expected, result)
  end

  ##
  # Attempts to exercise the situation where an undo would inappropriately undo
  # another undo.
  ##
  def test_redo_across_other_undos()
    _test_define(memory: @memory, address: 0x0000, length: 0x0002, user_defined: { test: 'A'} )
    _test_define(memory: @memory, address: 0x0002, length: 0x0002, user_defined: { test: 'B'} )

    @memory.undo() # undo B

    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
    expected = {
      revision: 0x03,
      entries: [
        _test_entry(address: 0x0000, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'A'} ),
        _test_entry_deleted(address: 0x0002, raw: "\x02".bytes() ),
        _test_entry_deleted(address: 0x0003, raw: "\x03".bytes() ),
      ],
    }
    assert_equal(expected, result)

    _test_define(memory: @memory, address: 0x0004, length: 0x0002, user_defined: { test: 'C'} )

    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
    expected = {
      revision: 0x04,
      entries: [
        _test_entry(address: 0x0000, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'A'} ),
        _test_entry_deleted(address: 0x0002, raw: "\x02".bytes() ),
        _test_entry_deleted(address: 0x0003, raw: "\x03".bytes() ),
        _test_entry(address: 0x0004, length: 0x02, raw: "\x04\x05".bytes(), user_defined: { test: 'C'} ),
      ],
    }
    assert_equal(expected, result)

    @memory.undo() # undo C

    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
    expected = {
      revision: 0x05,
      entries: [
        _test_entry(address: 0x0000, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'A'} ),
        _test_entry_deleted(address: 0x0002, raw: "\x02".bytes() ),
        _test_entry_deleted(address: 0x0003, raw: "\x03".bytes() ),
        _test_entry_deleted(address: 0x0004, raw: "\x04".bytes() ),
        _test_entry_deleted(address: 0x0005, raw: "\x05".bytes() ),
      ],
    }
    assert_equal(expected, result)

    @memory.undo() # undo A

    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
    expected = {
      revision: 0x06,
      entries: [
        _test_entry_deleted(address: 0x0000, raw: "\x00".bytes() ),
        _test_entry_deleted(address: 0x0001, raw: "\x01".bytes() ),
        _test_entry_deleted(address: 0x0002, raw: "\x02".bytes() ),
        _test_entry_deleted(address: 0x0003, raw: "\x03".bytes() ),
        _test_entry_deleted(address: 0x0004, raw: "\x04".bytes() ),
        _test_entry_deleted(address: 0x0005, raw: "\x05".bytes() ),
      ],
    }
    assert_equal(expected, result)

    @memory.redo() # redo A

    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
    expected = {
      revision: 0x07,
      entries: [
        _test_entry(address: 0x0000, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'A'} ),
        _test_entry_deleted(address: 0x0002, raw: "\x02".bytes() ),
        _test_entry_deleted(address: 0x0003, raw: "\x03".bytes() ),
        _test_entry_deleted(address: 0x0004, raw: "\x04".bytes() ),
        _test_entry_deleted(address: 0x0005, raw: "\x05".bytes() ),
      ],
    }
    assert_equal(expected, result)

    @memory.redo() # redo C

    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
    expected = {
      revision: 0x08,
      entries: [
        _test_entry(address: 0x0000, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'A'} ),
        _test_entry_deleted(address: 0x0002, raw: "\x02".bytes() ),
        _test_entry_deleted(address: 0x0003, raw: "\x03".bytes() ),
        _test_entry(address: 0x0004, length: 0x02, raw: "\x04\x05".bytes(), user_defined: { test: 'C'} ),
      ],
    }
    assert_equal(expected, result)

    @memory.redo() # Should do nothing
    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
    expected = {
      revision: 0x08,
      entries: [
        _test_entry(address: 0x0000, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'A'} ),
        _test_entry_deleted(address: 0x0002, raw: "\x02".bytes() ),
        _test_entry_deleted(address: 0x0003, raw: "\x03".bytes() ),
        _test_entry(address: 0x0004, length: 0x02, raw: "\x04\x05".bytes(), user_defined: { test: 'C'} ),
      ],
    }
    assert_equal(expected, result)
  end

  def test_redo_goes_away_after_edit()
    _test_define(memory: @memory, address: 0x0000, length: 0x0002, user_defined: { test: 'A'} )
    _test_define(memory: @memory, address: 0x0002, length: 0x0002, user_defined: { test: 'B'} )
    _test_define(memory: @memory, address: 0x0004, length: 0x0002, user_defined: { test: 'C'} )

    @memory.undo()
    @memory.undo()
    @memory.undo()

    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
    assert_equal({
      revision: 0x06,
      entries: [
        _test_entry_deleted(address: 0x0000, raw: "\x00".bytes() ),
        _test_entry_deleted(address: 0x0001, raw: "\x01".bytes() ),
        _test_entry_deleted(address: 0x0002, raw: "\x02".bytes() ),
        _test_entry_deleted(address: 0x0003, raw: "\x03".bytes() ),
        _test_entry_deleted(address: 0x0004, raw: "\x04".bytes() ),
        _test_entry_deleted(address: 0x0005, raw: "\x05".bytes() ),
      ],
    }, result)

    @memory.redo()

    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
    expected = {
      revision: 0x07,
      entries: [
        _test_entry(address: 0x0000, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'A'} ),
        _test_entry_deleted(address: 0x0002, raw: "\x02".bytes() ),
        _test_entry_deleted(address: 0x0003, raw: "\x03".bytes() ),
        _test_entry_deleted(address: 0x0004, raw: "\x04".bytes() ),
        _test_entry_deleted(address: 0x0005, raw: "\x05".bytes() ),
      ]
    }
    assert_equal(expected, result)

    _test_define(memory: @memory, address: 0x0006, length: 0x0002, user_defined: { test: 'D'} )

    @memory.redo() # Should do nothing

    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
    expected = {
      revision: 0x08,
      entries: [
        _test_entry(address: 0x0000, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'A'} ),
        _test_entry_deleted(address: 0x0002, raw: "\x02".bytes() ),
        _test_entry_deleted(address: 0x0003, raw: "\x03".bytes() ),
        _test_entry_deleted(address: 0x0004, raw: "\x04".bytes() ),
        _test_entry_deleted(address: 0x0005, raw: "\x05".bytes() ),
        _test_entry(address: 0x0006, length: 0x02, raw: "\x06\x07".bytes(), user_defined: { test: 'D'} ),
      ]
    }
    assert_equal(expected, result)
  end

  def test_redo_too_much()
    _test_define(memory: @memory, address: 0x0000, length: 0x0002, user_defined: { test: 'A'} )
    @memory.undo()
    @memory.undo()
    @memory.redo()
    @memory.redo()
    @memory.redo()
    @memory.redo()

    _test_define(memory: @memory, address: 0x0002, length: 0x0002, user_defined: { test: 'B'} )
    result = @memory.get(address: 0x00, length: 0xFF, since: 0)

    expected = {
      revision: 0x04,
      entries: [
        _test_entry(address: 0x0000, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'A'} ),
        _test_entry(address: 0x0002, length: 0x02, raw: "\x02\x03".bytes(), user_defined: { test: 'B'} ),
      ]
    }

    assert_equal(expected, result)
  end

  def test_redo_overwrite()
    _test_define(memory: @memory, address: 0x0000, length: 0x0002, user_defined: { test: 'A'} )
    _test_define(memory: @memory, address: 0x0000, length: 0x0001, user_defined: { test: 'B'} )
    _test_define(memory: @memory, address: 0x0000, length: 0x0003, user_defined: { test: 'C'} )

    @memory.undo()
    @memory.undo()
    @memory.undo()
    @memory.redo()
    @memory.redo()
    @memory.redo()

    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
    expected = {
      revision: 0x09,
      entries: [
        _test_entry(address: 0x0000, length: 0x03, raw: "\x00\x01\x02".bytes(), user_defined: { test: 'C'} ),
      ]
    }
    assert_equal(expected, result)
  end

  def test_transaction_redo()
    @memory.transaction() do
    _test_define(memory: @memory, address: 0x0000, length: 0x0002, user_defined: { test: 'A'}, do_transaction: false)
    _test_define(memory: @memory, address: 0x0002, length: 0x0002, user_defined: { test: 'B'}, do_transaction: false)
    _test_define(memory: @memory, address: 0x0000, length: 0x0002, user_defined: { test: 'C'}, do_transaction: false)
    _test_define(memory: @memory, address: 0x0004, length: 0x0002, user_defined: { test: 'D'}, do_transaction: false)
    end

    @memory.transaction() do
    _test_define(memory: @memory, address: 0x0001, length: 0x0002, user_defined: { test: 'E'}, do_transaction: false)
    _test_define(memory: @memory, address: 0x0006, length: 0x0002, user_defined: { test: 'F'}, do_transaction: false)
    end

    result = @memory.get(address: 0x00, length: 0xFF, since: 0)

    @memory.undo()
    @memory.undo()

    @memory.redo()

    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
    expected = {
      revision: 0x05,
      entries: [
        _test_entry(address: 0x0000, length: 0x02, raw: "\x00\x01".bytes(), user_defined: { test: 'C'} ),
        _test_entry(address: 0x0002, length: 0x02, raw: "\x02\x03".bytes(), user_defined: { test: 'B'} ),
        _test_entry(address: 0x0004, length: 0x02, raw: "\x04\x05".bytes(), user_defined: { test: 'D'} ),
        _test_entry_deleted(address: 0x0006, raw: "\x06".bytes() ),
        _test_entry_deleted(address: 0x0007, raw: "\x07".bytes() ),
      ]
    }
    assert_equal(expected, result)


    @memory.redo()

    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
    expected = {
      revision: 0x06,
      entries: [
        _test_entry_deleted(address: 0x0000, raw: "\x00".bytes() ),
        _test_entry(address: 0x0001, length: 0x02, raw: "\x01\x02".bytes(), user_defined: { test: 'E'} ),
        _test_entry_deleted(address: 0x0003, raw: "\x03".bytes() ),
        _test_entry(address: 0x0004, length: 0x02, raw: "\x04\x05".bytes(), user_defined: { test: 'D'} ),
        _test_entry(address: 0x0006, length: 0x02, raw: "\x06\x07".bytes(), user_defined: { test: 'F'} ),
      ]
    }
    assert_equal(expected, result)
  end
end

class H2gb::Vault::GetChangesSinceTest < Test::Unit::TestCase
  def setup()
    @memory = H2gb::Vault::Memory.new(raw: RAW)
  end


  def test_get_from_minus_one()
    _test_define(memory: @memory, address: 0x0001, length: 0x0002, user_defined: { test: 'A'})

    result = @memory.get(address: 0x00, length: 0x04, since: -1)
    expected = {
      revision: 0x1,
      entries: [
        _test_entry_deleted(address: 0x0000, raw: "\x00".bytes() ),
        _test_entry(address: 0x0001, length: 0x02, raw: "\x01\x02".bytes(), user_defined: { test: 'A'} ),
        _test_entry_deleted(address: 0x0003, raw: "\x03".bytes() ),
      ]
    }

    assert_equal(expected, result)
  end

  def test_add_one()
    _test_define(memory: @memory, address: 0x0000, length: 0x0001, user_defined: { test: 'A'})

    result = @memory.get(address: 0x00, length: 0x10, since: 0)
    expected = {
      revision: 0x1,
      entries: [
        _test_entry(address: 0x0000, length: 0x01, raw: "\x00".bytes(), user_defined: { test: 'A'} ),
      ]
    }

    assert_equal(expected, result)
  end

  def test_add_multiple()
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "A", length: 0x04)
    _test_define(memory: @memory, address: 0x0000, length: 0x0004, user_defined: { test: 'A'})
#    end
#    @memory.transaction() do
#      @memory.insert(address: 0x04, data: "B", length: 0x04)
    _test_define(memory: @memory, address: 0x0004, length: 0x0004, user_defined: { test: 'B'})
#    end
#    @memory.transaction() do
#      @memory.insert(address: 0x08, data: "C", length: 0x04)
    _test_define(memory: @memory, address: 0x0008, length: 0x0004, user_defined: { test: 'C'})
#    end

    result = @memory.get(address: 0x00, length: 0x10, since: 0)
    expected = {
      revision: 0x3,
      entries: [
        _test_entry(address: 0x0000, length: 0x04, raw: "\x00\x01\x02\x03".bytes(), user_defined: { test: 'A'} ),
        _test_entry(address: 0x0004, length: 0x04, raw: "\x04\x05\x06\x07".bytes(), user_defined: { test: 'B'} ),
        _test_entry(address: 0x0008, length: 0x04, raw: "\x08\x09\x0a\x0b".bytes(), user_defined: { test: 'C'} ),
      ]
    }
    assert_equal(expected, result)

    result = @memory.get(address: 0x00, length: 0x10, since: 1)
    expected = {
      revision: 0x3,
      entries: [
        _test_entry(address: 0x0004, length: 0x04, raw: "\x04\x05\x06\x07".bytes(), user_defined: { test: 'B'} ),
        _test_entry(address: 0x0008, length: 0x04, raw: "\x08\x09\x0a\x0b".bytes(), user_defined: { test: 'C'} ),
      ]
    }
    assert_equal(expected, result)

    result = @memory.get(address: 0x00, length: 0x10, since: 2)
    expected = {
      revision: 0x3,
      entries: [
        _test_entry(address: 0x0008, length: 0x04, raw: "\x08\x09\x0a\x0b".bytes(), user_defined: { test: 'C'} ),
      ]
    }
    assert_equal(expected, result)

    result = @memory.get(address: 0x00, length: 0x10, since: 3)
    expected = {
      revision: 0x3,
      entries: []
    }
    assert_equal(expected, result)
  end

  def test_overwrite()
    _test_define(memory: @memory, address: 0x0000, length: 0x0004, user_defined: { test: 'A'})
    _test_define(memory: @memory, address: 0x0002, length: 0x0004, user_defined: { test: 'B'})
    _test_define(memory: @memory, address: 0x0004, length: 0x0004, user_defined: { test: 'C'})

    result = @memory.get(address: 0x00, length: 0x10, since: 0)
    expected = {
      revision: 0x3,
      entries: [
        _test_entry_deleted(address: 0x0000, raw: "\x00".bytes() ),
        _test_entry_deleted(address: 0x0001, raw: "\x01".bytes() ),
        _test_entry_deleted(address: 0x0002, raw: "\x02".bytes() ),
        _test_entry_deleted(address: 0x0003, raw: "\x03".bytes() ),
        _test_entry(address: 0x0004, length: 0x04, raw: "\x04\x05\x06\x07".bytes(), user_defined: { test: 'C'} ),
      ]
    }
    assert_equal(expected, result)

    result = @memory.get(address: 0x00, length: 0x10, since: 1)
    expected = {
      revision: 0x3,
      entries: [
        _test_entry_deleted(address: 0x0000, raw: "\x00".bytes() ),
        _test_entry_deleted(address: 0x0001, raw: "\x01".bytes() ),
        _test_entry_deleted(address: 0x0002, raw: "\x02".bytes() ),
        _test_entry_deleted(address: 0x0003, raw: "\x03".bytes() ),
        _test_entry(address: 0x0004, length: 0x04, raw: "\x04\x05\x06\x07".bytes(), user_defined: { test: 'C'} ),
      ]
    }
    assert_equal(expected, result)

    result = @memory.get(address: 0x00, length: 0x10, since: 2)
    expected = {
      revision: 0x3,
      entries: [
        _test_entry_deleted(address: 0x0002, raw: "\x02".bytes() ),
        _test_entry_deleted(address: 0x0003, raw: "\x03".bytes() ),
        _test_entry(address: 0x0004, length: 0x04, raw: "\x04\x05\x06\x07".bytes(), user_defined: { test: 'C'} ),
      ]
    }
    assert_equal(expected, result)

    result = @memory.get(address: 0x00, length: 0x10, since: 3)
    expected = {
      revision: 0x3,
      entries: []
    }
    assert_equal(expected, result)
  end

  def test_undo()
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "A", length: 0x02)
#    end
#    @memory.transaction() do
#      @memory.insert(address: 0x04, data: "B", length: 0x02)
#    end
#    @memory.transaction() do
#      @memory.insert(address: 0x08, data: "C", length: 0x02)
#    end
    _test_define(memory: @memory, address: 0x0000, length: 0x0002, user_defined: { test: 'A'})
    _test_define(memory: @memory, address: 0x0004, length: 0x0002, user_defined: { test: 'B'})
    _test_define(memory: @memory, address: 0x0008, length: 0x0002, user_defined: { test: 'C'})
    @memory.undo()
    @memory.undo()
    @memory.undo()

    result = @memory.get(address: 0x00, length: 0x10, since: 0)
    expected = {
      revision: 0x06,
      entries: [
        _test_entry_deleted(address: 0x0000, raw: "\x00".bytes() ),
        _test_entry_deleted(address: 0x0001, raw: "\x01".bytes() ),
        _test_entry_deleted(address: 0x0004, raw: "\x04".bytes() ),
        _test_entry_deleted(address: 0x0005, raw: "\x05".bytes() ),
        _test_entry_deleted(address: 0x0008, raw: "\x08".bytes() ),
        _test_entry_deleted(address: 0x0009, raw: "\x09".bytes() ),
      ]
    }
    assert_equal(expected, result)

    result = @memory.get(address: 0x00, length: 0x10, since: 3)
    expected = {
      revision: 0x06,
      entries: [
        _test_entry_deleted(address: 0x0000, raw: "\x00".bytes() ),
        _test_entry_deleted(address: 0x0001, raw: "\x01".bytes() ),
        _test_entry_deleted(address: 0x0004, raw: "\x04".bytes() ),
        _test_entry_deleted(address: 0x0005, raw: "\x05".bytes() ),
        _test_entry_deleted(address: 0x0008, raw: "\x08".bytes() ),
        _test_entry_deleted(address: 0x0009, raw: "\x09".bytes() ),
      ]
    }
    assert_equal(expected, result)

    result = @memory.get(address: 0x00, length: 0x10, since: 4)
    expected = {
      revision: 0x06,
      entries: [
        _test_entry_deleted(address: 0x0000, raw: "\x00".bytes() ),
        _test_entry_deleted(address: 0x0001, raw: "\x01".bytes() ),
        _test_entry_deleted(address: 0x0004, raw: "\x04".bytes() ),
        _test_entry_deleted(address: 0x0005, raw: "\x05".bytes() ),
      ]
    }
    assert_equal(expected, result)

    result = @memory.get(address: 0x00, length: 0x10, since: 5)
    expected = {
      revision: 0x06,
      entries: [
        _test_entry_deleted(address: 0x0000, raw: "\x00".bytes() ),
        _test_entry_deleted(address: 0x0001, raw: "\x01".bytes() ),
      ]
    }
    assert_equal(expected, result)

    result = @memory.get(address: 0x00, length: 0x10, since: 6)
    expected = {
      revision: 0x06,
      entries: [],
    }
    assert_equal(expected, result)
  end

  def test_redo()
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "A", length: 0x04)
#    end
#    @memory.transaction() do
#      @memory.insert(address: 0x02, data: "B", length: 0x04)
#    end
#    @memory.transaction() do
#      @memory.insert(address: 0x08, data: "C", length: 0x02)
#    end
    _test_define(memory: @memory, address: 0x0000, length: 0x0004, user_defined: { test: 'A'})
    _test_define(memory: @memory, address: 0x0002, length: 0x0004, user_defined: { test: 'B'})
    _test_define(memory: @memory, address: 0x0008, length: 0x0002, user_defined: { test: 'C'})
    @memory.undo()
    @memory.undo()
    @memory.undo()
    @memory.redo()
    @memory.redo()
    @memory.redo()

    result = @memory.get(address: 0x00, length: 0x10, since: 0)
    expected = {
      revision: 0x09,
      entries: [
        _test_entry_deleted(address: 0x0000, raw: "\x00".bytes() ),
        _test_entry_deleted(address: 0x0001, raw: "\x01".bytes() ),
        _test_entry(address: 0x0002, length: 0x04, raw: "\x02\x03\x04\x05".bytes(), user_defined: { test: 'B'} ),
        _test_entry(address: 0x0008, length: 0x02, raw: "\x08\x09".bytes(), user_defined: { test: 'C'} ),
      ]
    }
    assert_equal(expected, result)

    result = @memory.get(address: 0x00, length: 0x10, since: 6)
    expected = {
      revision: 0x09,
      entries: [
        _test_entry_deleted(address: 0x0000, raw: "\x00".bytes() ),
        _test_entry_deleted(address: 0x0001, raw: "\x01".bytes() ),
        _test_entry(address: 0x0002, length: 0x04, raw: "\x02\x03\x04\x05".bytes(), user_defined: { test: 'B'} ),
        _test_entry(address: 0x0008, length: 0x02, raw: "\x08\x09".bytes(), user_defined: { test: 'C'} ),
      ]
    }
    assert_equal(expected, result)

    result = @memory.get(address: 0x00, length: 0x10, since: 7)
    expected = {
      revision: 0x09,
      entries: [
        _test_entry_deleted(address: 0x0000, raw: "\x00".bytes() ),
        _test_entry_deleted(address: 0x0001, raw: "\x01".bytes() ),
        _test_entry(address: 0x0002, length: 0x04, raw: "\x02\x03\x04\x05".bytes(), user_defined: { test: 'B'} ),
        _test_entry(address: 0x0008, length: 0x02, raw: "\x08\x09".bytes(), user_defined: { test: 'C'} ),
      ]
    }
    assert_equal(expected, result)

    result = @memory.get(address: 0x00, length: 0x10, since: 8)
    expected = {
      revision: 0x09,
      entries: [
        _test_entry(address: 0x0008, length: 0x02, raw: "\x08\x09".bytes(), user_defined: { test: 'C'} ),
      ]
    }
    assert_equal(expected, result)
  end
end

class H2gb::Vault::XrefsTest < Test::Unit::TestCase
  def setup()
    @memory = H2gb::Vault::Memory.new(raw: RAW)
  end

  def test_basic_xref()
   _test_define(memory: @memory, address: 0x0000, length: 0x0004, user_defined: { test: 'A'})
   _test_define(memory: @memory, address: 0x0004, length: 0x0004, user_defined: { test: 'B'}, code_refs: [0x0000])

    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
    expected = {
      revision: 0x02,
      entries: [
        _test_entry(address: 0x0000, length: 0x04, raw: "\x00\x01\x02\x03".bytes(), user_defined: { test: 'A'}, code_xrefs: [0x0004] ),
        _test_entry(address: 0x0004, length: 0x04, raw: "\x04\x05\x06\x07".bytes(), user_defined: { test: 'B'}, code_refs: [0x0000] ),
      ]
    }
    assert_equal(expected, result)
  end

  # We just have one simple test, because as far as memory.rb is concerned, code and data xrefs are identical
  def test_basic_data_xref()
   _test_define(memory: @memory, address: 0x0000, length: 0x0004, user_defined: { test: 'A'})
   _test_define(memory: @memory, address: 0x0004, length: 0x0004, user_defined: { test: 'B'}, data_refs: [0x0000])

    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
    expected = {
      revision: 0x02,
      entries: [
        _test_entry(address: 0x0000, length: 0x04, raw: "\x00\x01\x02\x03".bytes(), user_defined: { test: 'A'}, data_xrefs: [0x0004] ),
        _test_entry(address: 0x0004, length: 0x04, raw: "\x04\x05\x06\x07".bytes(), user_defined: { test: 'B'}, data_refs: [0x0000] ),
      ]
    }
    assert_equal(expected, result)
  end

  def test_xref_to_middle()
    _test_define(memory: @memory, address: 0x0000, length: 0x0004, user_defined: { test: 'A'})
    _test_define(memory: @memory, address: 0x0004, length: 0x0004, user_defined: { test: 'B'}, code_refs: [0x0002])

    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
    expected = {
      revision: 0x02,
      entries: [
        _test_entry(address: 0x0000, length: 0x04, raw: "\x00\x01\x02\x03".bytes(), user_defined: { test: 'A'} ),
        _test_entry(address: 0x0004, length: 0x04, raw: "\x04\x05\x06\x07".bytes(), user_defined: { test: 'B'}, code_refs: [0x0002] ),
      ]
    }
    assert_equal(expected, result)
  end

  def test_multiple_same_refs()
    _test_define(memory: @memory, address: 0x0000, length: 0x0004, user_defined: { test: 'A'})
    _test_define(memory: @memory, address: 0x0004, length: 0x0004, user_defined: { test: 'B'}, code_refs: [0x0000, 0x0000, 0x0002])

    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
    expected = {
      revision: 0x02,
      entries: [
        _test_entry(address: 0x0000, length: 0x04, raw: "\x00\x01\x02\x03".bytes(), user_defined: { test: 'A'}, code_xrefs: [0x0004] ),
        _test_entry(address: 0x0004, length: 0x04, raw: "\x04\x05\x06\x07".bytes(), user_defined: { test: 'B'}, code_refs: [0x0000, 0x0002] ),
      ]
    }
    assert_equal(expected, result)
  end

  def test_multiple_refs()
    _test_define(memory: @memory, address: 0x0000, length: 0x0004, user_defined: { test: 'A'}, code_refs: [0x0004, 0x0008, 0x0009])
    _test_define(memory: @memory, address: 0x0004, length: 0x0004, user_defined: { test: 'B'}, code_refs: [])
    _test_define(memory: @memory, address: 0x0008, length: 0x0004, user_defined: { test: 'C'}, code_refs: [])

    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
    expected = {
      revision: 0x03,
      entries: [
        _test_entry(address: 0x0000, length: 0x04, raw: "\x00\x01\x02\x03".bytes(), user_defined: { test: 'A'}, code_refs: [0x0004, 0x0008, 0x0009] ),
        _test_entry(address: 0x0004, length: 0x04, raw: "\x04\x05\x06\x07".bytes(), user_defined: { test: 'B'}, code_xrefs: [0x0000] ),
        _test_entry(address: 0x0008, length: 0x04, raw: "\x08\x09\x0a\x0b".bytes(), user_defined: { test: 'C'}, code_xrefs: [0x0000] ),
      ]
    }
    assert_equal(expected, result)
  end

  def test_multiple_xrefs()
    _test_define(memory: @memory, address: 0x0000, length: 0x0004, user_defined: { test: 'A'}, code_refs: [0x0004, 0x0008, 0x0009])
    _test_define(memory: @memory, address: 0x0004, length: 0x0004, user_defined: { test: 'B'}, code_refs: [0x0008])
    _test_define(memory: @memory, address: 0x0008, length: 0x0004, user_defined: { test: 'C'}, code_refs: [])

    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
    expected = {
      revision: 0x03,
      entries: [
        _test_entry(address: 0x0000, length: 0x04, raw: "\x00\x01\x02\x03".bytes(), user_defined: { test: 'A'}, code_refs: [0x0004, 0x0008, 0x0009] ),
        _test_entry(address: 0x0004, length: 0x04, raw: "\x04\x05\x06\x07".bytes(), user_defined: { test: 'B'}, code_refs: [0x0008], code_xrefs: [0x0000] ),
        _test_entry(address: 0x0008, length: 0x04, raw: "\x08\x09\x0a\x0b".bytes(), user_defined: { test: 'C'}, code_xrefs: [0x000, 0x0004] ),
      ]
    }
    assert_equal(expected, result)
  end

  def test_self_ref()
    _test_define(memory: @memory, address: 0x0000, length: 0x0004, user_defined: { test: 'A'}, code_refs: [0x0000])
    _test_define(memory: @memory, address: 0x0004, length: 0x0004, user_defined: { test: 'B'}, code_refs: [0x0005])

    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
    expected = {
      revision: 0x02,
      entries: [
        _test_entry(address: 0x0000, length: 0x04, raw: "\x00\x01\x02\x03".bytes(), user_defined: { test: 'A'}, code_refs: [0x0000], code_xrefs: [0x0000] ),
        _test_entry(address: 0x0004, length: 0x04, raw: "\x04\x05\x06\x07".bytes(), user_defined: { test: 'B'}, code_refs: [0x0005], code_xrefs: [] ),
      ]
    }
    assert_equal(expected, result)
  end

  def test_delete_ref()
    _test_define(memory: @memory, address: 0x0000, length: 0x0004, user_defined: { test: 'A'}, code_refs: [0x0004, 0x0008, 0x0009])
    _test_define(memory: @memory, address: 0x0004, length: 0x0004, user_defined: { test: 'B'}, code_refs: [0x0000, 0x0002, 0x000a])
    _test_define(memory: @memory, address: 0x0008, length: 0x0004, user_defined: { test: 'C'}, code_refs: [])

    _test_undefine(memory: @memory, address: 0x0000, length: 0x01)

    result = @memory.get(address: 0x00, length: 0xFF, since: 0)
    expected = {
      revision: 0x04,
      entries: [
        _test_entry_deleted(address: 0x0000, raw: "\x00".bytes(), code_xrefs: [0x0004] ),
        _test_entry_deleted(address: 0x0001, raw: "\x01".bytes() ),
        _test_entry_deleted(address: 0x0002, raw: "\x02".bytes(), code_xrefs: [0x0002] ),
        _test_entry_deleted(address: 0x0003, raw: "\x03".bytes() ),
        _test_entry(address: 0x0004, length: 0x04, raw: "\x04\x05\x06\x07".bytes(), user_defined: { test: 'B'}, code_refs: [0x0000, 0x0002, 0x000a] ),
        _test_entry(address: 0x0008, length: 0x04, raw: "\x08\x09\x0a\x0b".bytes(), user_defined: { test: 'C'}, code_refs: [] ),
      ]
    }
    assert_equal(expected, result)
  end

  def test_xref_after_undos_and_redos()
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
    _test_define(memory: @memory, address: 0x0000, length: 0x0004, user_defined: { test: 'A'}, code_refs: [0x0004, 0x0008, 0x0009])
    _test_define(memory: @memory, address: 0x0004, length: 0x0004, user_defined: { test: 'B'}, code_refs: [0x0000, 0x0002, 0x000a])
    _test_define(memory: @memory, address: 0x0008, length: 0x0004, user_defined: { test: 'C'}, code_refs: [])
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
  end

  def test_xref_with_since()
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "A", length: 0x04, refs: [0x04, 0x05])
#    end
#    @memory.transaction() do
#      @memory.insert(address: 0x04, data: "B", length: 0x04, refs: [0x04])
#    end
#    @memory.transaction() do
#      @memory.insert(address: 0x05, data: "C", length: 0x04, refs: [0x05, 0x0a])
#    end
    _test_define(memory: @memory, address: 0x0000, length: 0x0004, user_defined: { test: 'A'}, code_refs: [0x0004, 0x0005])
    _test_define(memory: @memory, address: 0x0004, length: 0x0004, user_defined: { test: 'B'}, code_refs: [0x0004])
    _test_define(memory: @memory, address: 0x0005, length: 0x0004, user_defined: { test: 'C'}, code_refs: [0x0005, 0x000a])
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
  end
end

class H2gb::Vault::SaveRestoreTest < Test::Unit::TestCase
  def test_save_load()
    memory = H2gb::Vault::Memory.new(raw: RAW)
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
    _test_define(memory: memory, address: 0x0000, length: 0x0004, user_defined: { test: 'A'}, code_refs: [0x0004, 0x0005])
    _test_define(memory: memory, address: 0x0004, length: 0x0004, user_defined: { test: 'B'}, code_refs: [0x0004])
    _test_define(memory: memory, address: 0x0005, length: 0x0004, user_defined: { test: 'C'}, code_refs: [0x0005, 0x000a])
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
  end

  def test_bad_load()
#    assert_raises(H2gb::Vault::Memory::MemoryError) do
#      H2gb::Vault::Memory.load("Not valid YAML")
#    end
  end
end

class H2gb::Vault::EditTest < Test::Unit::TestCase
  def setup()
    @memory = H2gb::Vault::Memory.new(raw: RAW)
  end

  def test_edit()
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "A", length: 0x04)
#    end
    _test_define(memory: @memory, address: 0x0000, length: 0x0004, user_defined: { test: 'A'})
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
  end

  def test_edit_undo_redo()
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "A", length: 0x04)
#    end
    _test_define(memory: @memory, address: 0x0000, length: 0x0004, user_defined: { test: 'A'})
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
  end

  def test_edit_bad_memory()
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "A", length: 0x04)
#    end
    _test_define(memory: @memory, address: 0x0000, length: 0x0004, user_defined: { test: 'A'})
#
#    assert_raises(H2gb::Vault::Memory::MemoryError) do
#      @memory.transaction() do
#        @memory.edit(address: 0x08, new_data: "B")
#      end
#    end
  end

  def test_edit_and_since()
#    @memory.transaction() do
#      @memory.insert(address: 0x00, data: "A", length: 0x04)
#    end
    _test_define(memory: @memory, address: 0x0000, length: 0x0004, user_defined: { test: 'A'})
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
  end
end
#
class H2gb::Vault::EditTest < Test::Unit::TestCase
  def setup()
    @memory = H2gb::Vault::Memory.new(raw: RAW)
  end

  def test_get_raw()
#    raw = @memory.get_raw()
#    assert_equal(RAW, raw)
  end
end
# TODO: Test get_user_defined and update_user_defined
