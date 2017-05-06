require 'test_helper'

require 'h2gb/vault/memory/memory_entry'

class H2gb::Vault::MemoryEntryTest < Test::Unit::TestCase
  def test_fields()
    memory_entry = H2gb::Vault::Memory::MemoryEntry.new(
      address: 0x1234,
      type: :type,
      value: "value",
      length: 10,
      code_refs: [123],
      data_refs: [321],
      user_defined: {test: "hi"},
      comment: "bye",
    )

    assert_equal(0x1234, memory_entry.address)
    assert_equal(:type, memory_entry.type)
    assert_equal("value", memory_entry.value)
    assert_equal(10, memory_entry.length)
    assert_equal([123], memory_entry.code_refs)
    assert_equal([321], memory_entry.data_refs)
    assert_equal({test: "hi"}, memory_entry.user_defined)
    assert_equal("bye", memory_entry.comment)
  end

  def test_validation()
    assert_raises(H2gb::Vault::Memory::MemoryError) do
      H2gb::Vault::Memory::MemoryEntry.new(
        address: 'hi', type: :type, value: "value", length: 10,
        code_refs: [123], data_refs: [321], user_defined: {test: "hi"}, comment: "bye",
      )
    end
    assert_raises(H2gb::Vault::Memory::MemoryError) do
      H2gb::Vault::Memory::MemoryEntry.new(
        address: -1, type: :type, value: "value", length: 10,
        code_refs: [123], data_refs: [321], user_defined: {test: "hi"}, comment: "bye",
      )
    end
    assert_raises(H2gb::Vault::Memory::MemoryError) do
      H2gb::Vault::Memory::MemoryEntry.new(
        address: 0x1234, type: [], value: "value", length: 10,
        code_refs: [123], data_refs: [321], user_defined: {test: "hi"}, comment: "bye",
      )
    end
    assert_raises(H2gb::Vault::Memory::MemoryError) do
      H2gb::Vault::Memory::MemoryEntry.new(
        address: 0x1234, type: :type, value: "value", length: "hi",
        code_refs: [123], data_refs: [321], user_defined: {test: "hi"}, comment: "bye",
      )
    end
    assert_raises(H2gb::Vault::Memory::MemoryError) do
      H2gb::Vault::Memory::MemoryEntry.new(
        address: 0x1234, type: :type, value: "value", length: 0,
        code_refs: [123], data_refs: [321], user_defined: {test: "hi"}, comment: "bye",
      )
    end
    assert_raises(H2gb::Vault::Memory::MemoryError) do
      H2gb::Vault::Memory::MemoryEntry.new(
        address: 0x1234, type: :type, value: "value", length: 10,
        code_refs: "hi", data_refs: [321], user_defined: {test: "hi"}, comment: "bye",
      )
    end
    assert_raises(H2gb::Vault::Memory::MemoryError) do
      H2gb::Vault::Memory::MemoryEntry.new(
        address: 0x1234, type: :type, value: "value", length: 10,
        code_refs: ["hi"], data_refs: [321], user_defined: {test: "hi"}, comment: "bye",
      )
    end
    assert_raises(H2gb::Vault::Memory::MemoryError) do
      H2gb::Vault::Memory::MemoryEntry.new(
        address: 0x1234, type: :type, value: "value", length: 10,
        code_refs: [123], data_refs: "hi", user_defined: {test: "hi"}, comment: "bye",
      )
    end
    assert_raises(H2gb::Vault::Memory::MemoryError) do
      H2gb::Vault::Memory::MemoryEntry.new(
        address: 0x1234, type: :type, value: "value", length: 10,
        code_refs: [123], data_refs: ["hi"], user_defined: {test: "hi"}, comment: "bye",
      )
    end
    assert_raises(H2gb::Vault::Memory::MemoryError) do
      H2gb::Vault::Memory::MemoryEntry.new(
        address: 0x1234, type: :type, value: "value", length: 10,
        code_refs: [123], data_refs: [321], user_defined: "hi", comment: "bye",
      )
    end
  end

  def test_each_address_one_byte()
    memory_entry = H2gb::Vault::Memory::MemoryEntry.new(
      address: 0x0000,
      type: :type,
      value: "value",
      length: 1,
      code_refs: [123],
      data_refs: [321],
      user_defined: {test: "hi"},
      comment: "bye",
    )

    addresses = []
    memory_entry.each_address() do |address|
      addresses << address
    end

    assert_equal([0], addresses)
  end

  def test_each_address_one_byte_non_zero()
    memory_entry = H2gb::Vault::Memory::MemoryEntry.new(
      address: 0x1234,
      type: :type,
      value: "value",
      length: 1,
      code_refs: [123],
      data_refs: [321],
      user_defined: {test: "hi"},
      comment: "bye",
    )

    addresses = []
    memory_entry.each_address() do |address|
      addresses << address
    end

    expected = [0x1234]
    assert_equal(expected, addresses)
  end
#
  def test_each_address_multi_byte()
    memory_entry = H2gb::Vault::Memory::MemoryEntry.new(
      address: 0x1000,
      type: :type,
      value: "value",
      length: 0x0004,
      code_refs: [123],
      data_refs: [321],
      user_defined: {test: "hi"},
      comment: "bye",
    )

    addresses = []
    memory_entry.each_address() do |address|
      addresses << address
    end

    expected = [0x1000, 0x1001, 0x1002, 0x1003]
    assert_equal(expected, addresses)
  end
end
