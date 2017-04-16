require 'test_helper'

require 'h2gb/vault/memory/memory_entry'

class H2gb::Vault::MemoryEntryTest < Test::Unit::TestCase
  def test_fields()
    memory_entry = H2gb::Vault::Memory::MemoryEntry.new(
      address: 0x1234,
      length: 0x4321,
      data: "data",
      refs: "refs",
      revision: 0,
    )

    assert_equal(0x1234, memory_entry.address)
    assert_equal(0x4321, memory_entry.length)
    assert_equal("data", memory_entry.data)
    assert_equal("refs", memory_entry.refs)
  end

  def test_each_address_zero_length()
    memory_entry = H2gb::Vault::Memory::MemoryEntry.new(
      address: 0x0000,
      length: 0x0000,
      data: "data",
      refs: "refs",
      revision: 0,
    )

    memory_entry.each_address() do |address|
      assert_true(false) # This loop shouldn't happen
    end
  end

  def test_each_address_one_byte()
    memory_entry = H2gb::Vault::Memory::MemoryEntry.new(
      address: 0x0000,
      length: 0x0001,
      data: "data",
      refs: "refs",
      revision: 0,
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
      length: 0x0001,
      data: "data",
      refs: "refs",
      revision: 0,
    )

    addresses = []
    memory_entry.each_address() do |address|
      addresses << address
    end

    expected = [0x1234]
    assert_equal(expected, addresses)
  end

  def test_each_address_multi_byte()
    memory_entry = H2gb::Vault::Memory::MemoryEntry.new(
      address: 0x1000,
      length: 0x0004,
      data: "data",
      refs: "refs",
      revision: 0,
    )

    addresses = []
    memory_entry.each_address() do |address|
      addresses << address
    end

    expected = [0x1000, 0x1001, 0x1002, 0x1003]
    assert_equal(expected, addresses)
  end

  def test_negative_address()
    assert_raises(H2gb::Vault::Memory::MemoryError) do
      H2gb::Vault::Memory::MemoryEntry.new(
        address: -1,
        length: 0x0010,
        data: "data",
        refs: "refs",
        revision: 0,
      )
    end
  end

  def test_negative_length()
    assert_raises(H2gb::Vault::Memory::MemoryError) do
      H2gb::Vault::Memory::MemoryEntry.new(
        address: 0x1000,
        length: -1,
        data: "data",
        refs: "refs",
        revision: 0,
      )
    end
  end
end
