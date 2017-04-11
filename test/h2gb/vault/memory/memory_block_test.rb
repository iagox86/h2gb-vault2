require 'test_helper'

require 'h2gb/vault/memory/memory_block'
require 'h2gb/vault/memory/memory_entry'

class H2gb::Vault::MemoryBlockTest < Test::Unit::TestCase
  def test_empty()
    memory_block = H2gb::Vault::Memory::MemoryBlock.new()
    memory_block.each_entry_in_range(address: 0x0000, length: 0xFFFF) do |address|
      assert_true(false) # This shouldn't be reached
    end
  end

  def test_single_byte()
    memory_block = H2gb::Vault::Memory::MemoryBlock.new()

    memory_entry = H2gb::Vault::Memory::MemoryEntry.new(
      address: 0x0000,
      length: 0x0001,
      data: "data",
      refs: "refs",
    )

    memory_block.insert(entry: memory_entry)

    entries = []
    memory_block.each_entry_in_range(address: 0x0000, length: 0x0001) do |entry|
      entries << entry
    end
    assert_equal([memory_entry], entries)
  end

  def test_single_byte_outside_range()
    memory_block = H2gb::Vault::Memory::MemoryBlock.new()

    memory_entry = H2gb::Vault::Memory::MemoryEntry.new(
      address: 0x0000,
      length: 0x0001,
      data: "data",
      refs: "refs",
    )

    memory_block.insert(entry: memory_entry)

    memory_block.each_entry_in_range(address: 0x0010, length: 0x0010) do |entry|
      assert_true(false) # Shouldn't happen
    end
  end

  def test_single_byte_middle_of_range()
    memory_block = H2gb::Vault::Memory::MemoryBlock.new()

    memory_entry = H2gb::Vault::Memory::MemoryEntry.new(
      address: 0x0080,
      length: 0x0001,
      data: "data",
      refs: "refs",
    )

    memory_block.insert(entry: memory_entry)

    entries = []
    memory_block.each_entry_in_range(address: 0x0000, length: 0x0100) do |entry|
      entries << entry
    end
    assert_equal([memory_entry], entries)
  end

  def test_multiple_bytes()
    memory_block = H2gb::Vault::Memory::MemoryBlock.new()

    memory_entries = [
      H2gb::Vault::Memory::MemoryEntry.new(
        address: 0x0010,
        length: 0x0010,
        data: "data",
        refs: "refs",
      ),
      H2gb::Vault::Memory::MemoryEntry.new(
        address: 0x0020,
        length: 0x0010,
        data: "data",
        refs: "refs",
      ),
      H2gb::Vault::Memory::MemoryEntry.new(
        address: 0x0030,
        length: 0x0010,
        data: "data",
        refs: "refs",
      ),
    ]

    memory_entries.each do |memory_entry|
      memory_block.insert(entry: memory_entry)
    end

    entries = []
    memory_block.each_entry_in_range(address: 0x0000, length: 0x0100) do |entry|
      entries << entry
    end
    assert_equal(memory_entries, entries)
  end

  def test_overlapping()
    memory_block = H2gb::Vault::Memory::MemoryBlock.new()

    memory_entries = [
      H2gb::Vault::Memory::MemoryEntry.new(
        address: 0x0000,
        length: 0x0010,
        data: "data",
        refs: "refs",
      ),
      H2gb::Vault::Memory::MemoryEntry.new(
        address: 0x0008,
        length: 0x0010,
        data: "data",
        refs: "refs",
      ),
    ]

    assert_raises(H2gb::Vault::Memory::MemoryError) do
      memory_entries.each do |memory_entry|
        memory_block.insert(entry: memory_entry)
      end
    end
  end

  def test_delete()
    memory_block = H2gb::Vault::Memory::MemoryBlock.new()

    memory_entry = H2gb::Vault::Memory::MemoryEntry.new(
      address: 0x0000,
      length: 0x0010,
      data: "data",
      refs: "refs",
    )

    memory_block.insert(entry: memory_entry)
    memory_block.delete(entry: memory_entry)

    memory_block.each_entry_in_range(address: 0x0000, length: 0x00FF) do |entry|
      assert_true(false) # Shouldn't happen
    end
  end

  def test_delete_multiple()
    memory_block = H2gb::Vault::Memory::MemoryBlock.new()

    memory_entries = [
      H2gb::Vault::Memory::MemoryEntry.new(
        address: 0x0010,
        length: 0x0010,
        data: "data",
        refs: "refs",
      ),
      H2gb::Vault::Memory::MemoryEntry.new(
        address: 0x0020,
        length: 0x0010,
        data: "data",
        refs: "refs",
      ),
      H2gb::Vault::Memory::MemoryEntry.new(
        address: 0x0030,
        length: 0x0010,
        data: "data",
        refs: "refs",
      ),
    ]

    memory_entries.each do |memory_entry|
      memory_block.insert(entry: memory_entry)
    end
    memory_entries.each do |memory_entry|
      memory_block.delete(entry: memory_entry)
    end
    memory_block.each_entry_in_range(address: 0x0000, length: 0x0100) do |entry|
      assert_true(false) # Shouldn't happen
    end

    # Do it again, but reverse the deletion list to make sure it's order
    # agnostic
    memory_entries.each do |memory_entry|
      memory_block.insert(entry: memory_entry)
    end
    memory_entries.each do |memory_entry|
      memory_block.delete(entry: memory_entry)
    end
    memory_block.each_entry_in_range(address: 0x0000, length: 0x0100) do |entry|
      assert_true(false) # Shouldn't happen
    end
  end

  def test_delete_empty()
    memory_block = H2gb::Vault::Memory::MemoryBlock.new()

    memory_entry = H2gb::Vault::Memory::MemoryEntry.new(
      address: 0x0000,
      length: 0x0010,
      data: "data",
      refs: "refs",
    )

    assert_raises(H2gb::Vault::Memory::MemoryError) do
      memory_block.delete(entry: memory_entry)
    end
  end
end
