require 'test_helper'

require 'h2gb/vault/memory'

class H2gb::Vault::MemoryTest < Test::Unit::TestCase
  def test_empty()
    memory = H2gb::Vault::Memory.new()
    result = memory.get(address: 0x00, length: 0xFF)
    assert_equal([], result)
  end

  def test_single_entry()
    memory = H2gb::Vault::Memory.new()
    memory.insert(address: 0x00, data: "A", length: 0x01)

    result = memory.get(address: 0x00, length: 0x01)
    expected = [{
      :address => 0x00,
      :data => "A",
      :length => 0x01,
    }]

    assert_equal(expected, result)
  end

  def test_get_longer_entry()
    memory = H2gb::Vault::Memory.new()
    memory.insert(address: 0x00, data: "A", length: 0x40)

    result = memory.get(address: 0x00, length: 0xFF)
    expected = [{
      :address => 0x00,
      :data => "A",
      :length => 0x40,
    }]

    assert_equal(expected, result)
  end

  def test_get_entry_in_middle()
    memory = H2gb::Vault::Memory.new()
    memory.insert(address: 0x80, data: "A", length: 0x01)

    result = memory.get(address: 0x00, length: 0xFF)
    expected = [{
      :address => 0x80,
      :data => "A",
      :length => 0x01,
    }]

    assert_equal(expected, result)
  end

  def test_two_adjacent()
    memory = H2gb::Vault::Memory.new()
    memory.insert(address: 0x00, data: "A", length: 0x02)
    memory.insert(address: 0x02, data: "B", length: 0x02)

    result = memory.get(address: 0x00, length: 0xFF)

    expected = [
      {
        :address => 0x00,
        :data => "A",
        :length => 0x02,
      },
      {
        :address => 0x02,
        :data => "B",
        :length => 0x02,
      }
    ]

    assert_equal(expected, result)
  end

  def test_two_not_adjacent()
    memory = H2gb::Vault::Memory.new()
    memory.insert(address: 0x00, data: "A", length: 0x02)
    memory.insert(address: 0x80, data: "B", length: 0x02)

    result = memory.get(address: 0x00, length: 0xFF)

    expected = [
      {
        :address => 0x00,
        :data => "A",
        :length => 0x02,
      },
      {
        :address => 0x80,
        :data => "B",
        :length => 0x02,
      }
    ]

    assert_equal(expected, result)
  end

  # The goal of this test is to make sure that our array works as a sparse array
  # and doesn't try to allocate memory for everything
  def test_two_very_not_adjacent()
    memory = H2gb::Vault::Memory.new()
    memory.insert(address: 0x0000000000000000, data: "A", length: 0x02)
    memory.insert(address: 0x0800000000000000, data: "B", length: 0x02)

    # Note: we are NOT going to try to get both, since the get() function has
    # to walk the entire space. We can implement that functionality later
    # (walking the list of entries instead of walking the address space) if we
    # choose to
    result = memory.get(address: 0x00, length: 0xFF)
    expected = [
      {
        :address => 0x00,
        :data => "A",
        :length => 0x02,
      },
    ]
    assert_equal(expected, result)

    result = memory.get(address: 0x0800000000000000, length: 0xFF)
    expected = [
      {
        :address => 0x0800000000000000,
        :data => "B",
        :length => 0x02,
      },
    ]
    assert_equal(expected, result)
  end

  def test_overwrite()
    memory = H2gb::Vault::Memory.new()

    memory.insert(address: 0x00, data: "A", length: 0x01)
    memory.insert(address: 0x00, data: "B", length: 0x01)

    result = memory.get(address: 0x00, length: 0xFF)
    expected = [{
      :address => 0x00,
      :data => "B",
      :length => 0x01,
    }]

    assert_equal(expected, result)
  end

  def test_overwrite_shorter()
    memory = H2gb::Vault::Memory.new()

    memory.insert(address: 0x00, data: "A", length: 0x41)
    memory.insert(address: 0x00, data: "B", length: 0x01)

    result = memory.get(address: 0x00, length: 0xFF)
    expected = [{
      :address => 0x00,
      :data => "B",
      :length => 0x01,
    }]

    assert_equal(expected, result)
  end

  def test_overwrite_middle()
    memory = H2gb::Vault::Memory.new()

    memory.insert(address: 0x00, data: "A", length: 0x41)
    memory.insert(address: 0x21, data: "B", length: 0x01)

    result = memory.get(address: 0x00, length: 0xFF)
    expected = [{
      :address => 0x21,
      :data => "B",
      :length => 0x01,
    }]

    assert_equal(expected, result)
  end

  def test_overwrite_multiple()
    memory = H2gb::Vault::Memory.new()

    memory.insert(address: 0x00, data: "A", length: 0x02)
    memory.insert(address: 0x02, data: "B", length: 0x04)
    memory.insert(address: 0x01, data: "C", length: 0x02)

    result = memory.get(address: 0x00, length: 0xFF)
    expected = [{
      :address => 0x01,
      :data => "C",
      :length => 0x02,
    }]

    assert_equal(expected, result)
  end

  def test_overwrite_multiple_with_gap()
    memory = H2gb::Vault::Memory.new()

    memory.insert(address: 0x00, data: "A", length: 0x02)
    memory.insert(address: 0x10, data: "B", length: 0x10)
    memory.insert(address: 0x00, data: "C", length: 0x80)

    result = memory.get(address: 0x00, length: 0xFF)
    expected = [{
      :address => 0x00,
      :data => "C",
      :length => 0x80,
    }]

    assert_equal(expected, result)
  end

  def test_undo()
    memory = H2gb::Vault::Memory.new()
    memory.insert(address: 0x00, data: "A", length: 0x02)
    memory.insert(address: 0x02, data: "B", length: 0x02)
    memory.undo()

    result = memory.get(address: 0x00, length: 0xFF)

    expected = [
      {
        :address => 0x00,
        :data => "A",
        :length => 0x02,
      },
    ]

    assert_equal(expected, result)
  end

  def test_overwrite_undo()
    memory = H2gb::Vault::Memory.new()
    memory.insert(address: 0x00, data: "A", length: 0x02)

    result = memory.get(address: 0x00, length: 0xFF)
    expected = [
      {
        :address => 0x00,
        :data => "A",
        :length => 0x02,
      },
    ]
    assert_equal(expected, result)

    memory.insert(address: 0x01, data: "B", length: 0x02)
    result = memory.get(address: 0x00, length: 0xFF)
    expected = [
      {
        :address => 0x01,
        :data => "B",
        :length => 0x02,
      },
    ]
    assert_equal(expected, result)

    memory.undo()
    result = memory.get(address: 0x00, length: 0xFF)
    expected = [
      {
        :address => 0x00,
        :data => "A",
        :length => 0x02,
      },
    ]
    assert_equal(expected, result)
  end

  def test_undo_transaction()
    memory = H2gb::Vault::Memory.new()
    memory.transaction() do
      memory.insert(address: 0x00, data: "A", length: 0x02)
      memory.insert(address: 0x02, data: "B", length: 0x02)
    end

    memory.transaction() do
      memory.insert(address: 0x01, data: "C", length: 0x02)
      memory.insert(address: 0x03, data: "D", length: 0x02)
    end

    result = memory.get(address: 0x00, length: 0xFF)
    expected = [
      {
        :address => 0x01,
        :data => "C",
        :length => 0x02,
      },
      {
        :address => 0x03,
        :data => "D",
        :length => 0x02,
      },
    ]
    assert_equal(expected, result)

    memory.undo()

    result = memory.get(address: 0x00, length: 0xFF)
    expected = [
      {
        :address => 0x00,
        :data => "A",
        :length => 0x02,
      },
      {
        :address => 0x02,
        :data => "B",
        :length => 0x02,
      },
    ]
    assert_equal(expected, result)
  end

  def test_memory_entry_is_private
    assert_raises(NameError) do
      H2gb::Vault::Memory::MemoryEntry.new(address: 0)
    end
  end
end
