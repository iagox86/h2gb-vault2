require 'test_helper'

require 'h2gb/vault/memory/memory_block'
require 'h2gb/vault/memory/memory_entry'

class H2gb::Vault::MemoryBlockTest < Test::Unit::TestCase
  def setup()
    raw = (0..255).to_a().map() { |b| b.chr() }.join()
    @memory_block = H2gb::Vault::Memory::MemoryBlock.new(raw: raw)
  end

  def test_empty()
    @memory_block.each_entry_in_range(address: 0x00, length: 0xFF) do |address, type, entry, raw|
      assert_equal(type, :no_entry)
    end
  end

  def test_single_byte()
    memory_entry = H2gb::Vault::Memory::MemoryEntry.new(
      address: 0x0000,
      length: 0x0001,
      data: "data",
      refs: "refs",
    )

    @memory_block.insert(entry: memory_entry)

    entries = []
    @memory_block.each_entry_in_range(address: 0x0000, length: 0x0001) do |address, type, entry, raw|
      entries << entry
    end
    assert_equal([memory_entry], entries)
  end

  def test_each_entry_no_entry()
    memory_entry = H2gb::Vault::Memory::MemoryEntry.new(
      address: 0x0000,
      length: 0x0001,
      data: "data",
      refs: "refs",
    )

    @memory_block.insert(entry: memory_entry)

    @memory_block.each_entry_in_range(address: 0x0010, length: 0x0004) do |address, type, entry, raw|
      assert_equal(:no_entry, type)
      assert_nil(entry)
      assert_equal(1, raw.length())
      # Check against the address, because that's how I set up the memory in setup()
      assert_equal(address, raw[0])
    end
  end

  def test_each_entry_outside_raw()
    memory_entry = H2gb::Vault::Memory::MemoryEntry.new(
      address: 0x0000,
      length: 0x0001,
      data: "data",
      refs: "refs",
    )

    @memory_block.insert(entry: memory_entry)

    assert_raises(H2gb::Vault::Memory::MemoryError) do
      @memory_block.each_entry_in_range(address: 0x00F8, length: 0x0010) do |address, type, entry, raw|
        assert_equal(:no_entry, type)
        assert_nil(entry)
        assert_equal(1, raw.length())
        # Check against the address, because that's how I set up the memory in setup()
        assert_equal(address, raw[0])
      end
    end
  end

  def test_single_byte_middle_of_range()
    memory_entry = H2gb::Vault::Memory::MemoryEntry.new(
      address: 0x0080,
      length: 0x0001,
      data: "data",
      refs: "refs",
    )

    @memory_block.insert(entry: memory_entry)
    @memory_block.each_entry_in_range(address: 0x0000, length: 0x0100) do |address, type, entry, raw|
      if type == :entry
        assert_equal(0x80, address)
        assert_equal([0x80], raw)
        assert_equal(memory_entry, entry)
      else
        assert_equal(:no_entry, type)
      end
    end
  end

  def test_multiple_bytes()
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
      @memory_block.insert(entry: memory_entry)
    end

    entries = []
    @memory_block.each_entry_in_range(address: 0x0000, length: 0x0100) do |address, type, entry, raw|
      if type == :entry
        entries << entry
      else
        assert_equal(type, :no_entry)
      end
    end
    assert_equal(memory_entries, entries)
  end

  def test_overlapping()
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
        @memory_block.insert(entry: memory_entry)
      end
    end
  end

  def test_delete()
    memory_entry = H2gb::Vault::Memory::MemoryEntry.new(
      address: 0x0000,
      length: 0x0010,
      data: "data",
      refs: "refs",
    )

    @memory_block.insert(entry: memory_entry)
    @memory_block.delete(entry: memory_entry)

    @memory_block.each_entry_in_range(address: 0x0000, length: 0x00FF) do |address, type, entry, raw|
      assert_equal(type, :no_entry)
    end
  end

  def test_delete_multiple()
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
      @memory_block.insert(entry: memory_entry)
    end
    memory_entries.each do |memory_entry|
      @memory_block.delete(entry: memory_entry)
    end
    @memory_block.each_entry_in_range(address: 0x0000, length: 0x0100) do |address, type, entry, raw|
      assert_equal(type, :no_entry)
    end

    # Do it again, but reverse the deletion list to make sure it's order
    # agnostic
    memory_entries.each do |memory_entry|
      @memory_block.insert(entry: memory_entry)
    end
    memory_entries.each do |memory_entry|
      @memory_block.delete(entry: memory_entry)
    end
    @memory_block.each_entry_in_range(address: 0x0000, length: 0x0100) do |address, type, entry, raw|
      assert_equal(type, :no_entry)
    end
  end

  def test_delete_empty()
    memory_entry = H2gb::Vault::Memory::MemoryEntry.new(
      address: 0x0000,
      length: 0x0010,
      data: "data",
      refs: "refs",
    )

    assert_raises(H2gb::Vault::Memory::MemoryError) do
      @memory_block.delete(entry: memory_entry)
    end
  end
end
