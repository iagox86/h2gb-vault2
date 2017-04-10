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
    memory.transaction() do
      memory.insert(address: 0x00, data: "A", length: 0x01)
    end

    result = memory.get(address: 0x00, length: 0x01)
    expected = [{
      :revision => 0x01,
      :address  => 0x00,
      :data     => "A",
      :length   => 0x01,
      :refs     => nil,
    }]

    assert_equal(expected, result)
  end

  def test_get_longer_entry()
    memory = H2gb::Vault::Memory.new()
    memory.transaction() do
      memory.insert(address: 0x00, data: "A", length: 0x40)
    end

    result = memory.get(address: 0x00, length: 0xFF)
    expected = [{
      :revision => 0x01,
      :address  => 0x00,
      :data     => "A",
      :length   => 0x40,
      :refs     => nil,
    }]

    assert_equal(expected, result)
  end

  def test_get_entry_in_middle()
    memory = H2gb::Vault::Memory.new()
    memory.transaction() do
      memory.insert(address: 0x80, data: "A", length: 0x01)
    end

    result = memory.get(address: 0x00, length: 0xFF)
    expected = [{
      :revision => 0x01,
      :address  => 0x80,
      :data     => "A",
      :length   => 0x01,
      :refs     => nil,
    }]

    assert_equal(expected, result)
  end

  def test_two_adjacent()
    memory = H2gb::Vault::Memory.new()
    memory.transaction() do
      memory.insert(address: 0x00, data: "A", length: 0x02)
    end

    memory.transaction() do
      memory.insert(address: 0x02, data: "B", length: 0x02)
    end

    result = memory.get(address: 0x00, length: 0xFF)

    expected = [
      {
        :revision => 0x01,
        :address => 0x00,
        :data => "A",
        :length => 0x02,
        :refs => nil,
      },
      {
        :revision => 0x02,
        :address => 0x02,
        :data => "B",
        :length => 0x02,
        :refs => nil,
      }
    ]

    assert_equal(expected, result)
  end

  def test_two_adjacent_in_same_transaction()
    memory = H2gb::Vault::Memory.new()
    memory.transaction do
      memory.insert(address: 0x00, data: "A", length: 0x02)
      memory.insert(address: 0x02, data: "B", length: 0x02)
    end

    result = memory.get(address: 0x00, length: 0xFF)

    expected = [
      {
        :revision => 0x01,
        :address => 0x00,
        :data => "A",
        :length => 0x02,
        :refs => nil,
      },
      {
        :revision => 0x01,
        :address => 0x02,
        :data => "B",
        :length => 0x02,
        :refs => nil,
      }
    ]

    assert_equal(expected, result)
  end

  def test_two_not_adjacent()
    memory = H2gb::Vault::Memory.new()
    memory.transaction() do
      memory.insert(address: 0x00, data: "A", length: 0x02)
      memory.insert(address: 0x80, data: "B", length: 0x02)
    end

    result = memory.get(address: 0x00, length: 0xFF)

    expected = [
      {
        :revision => 0x01,
        :address => 0x00,
        :data => "A",
        :length => 0x02,
        :refs => nil,
      },
      {
        :revision => 0x01,
        :address => 0x80,
        :data => "B",
        :length => 0x02,
        :refs => nil,
      }
    ]

    assert_equal(expected, result)
  end

  # The goal of this test is to make sure that our array works as a sparse array
  # and doesn't try to allocate memory for everything
  def test_two_very_not_adjacent()
    memory = H2gb::Vault::Memory.new()
    memory.transaction() do
      memory.insert(address: 0x0000000000000000, data: "A", length: 0x02)
    end
    memory.transaction() do
      memory.insert(address: 0x0800000000000000, data: "B", length: 0x02)
    end

    # Note: we are NOT going to try to get both, since the get() function has
    # to walk the entire space. We can implement that functionality later
    # (walking the list of entries instead of walking the address space) if we
    # choose to
    result = memory.get(address: 0x00, length: 0xFF)
    expected = [
      {
        :revision => 0x01,
        :address => 0x00,
        :data => "A",
        :length => 0x02,
        :refs => nil,
      },
    ]
    assert_equal(expected, result)

    result = memory.get(address: 0x0800000000000000, length: 0xFF)
    expected = [
      {
        :revision => 0x02,
        :address => 0x0800000000000000,
        :data => "B",
        :length => 0x02,
        :refs => nil,
      },
    ]
    assert_equal(expected, result)
  end

  def test_overwrite()
    memory = H2gb::Vault::Memory.new()

    memory.transaction() do
      memory.insert(address: 0x00, data: "A", length: 0x01)
    end
    memory.transaction() do
      memory.insert(address: 0x00, data: "B", length: 0x01)
    end

    result = memory.get(address: 0x00, length: 0xFF)
    expected = [{
      :revision => 0x02,
      :address => 0x00,
      :data => "B",
      :length => 0x01,
      :refs => nil,
    }]

    assert_equal(expected, result)
  end

  def test_overwrite_shorter()
    memory = H2gb::Vault::Memory.new()

    memory.transaction() do
      memory.insert(address: 0x00, data: "A", length: 0x41)
    end
    memory.transaction() do
      memory.insert(address: 0x00, data: "B", length: 0x01)
    end

    result = memory.get(address: 0x00, length: 0xFF)
    expected = [{
      :revision => 0x02,
      :address => 0x00,
      :data => "B",
      :length => 0x01,
      :refs => nil,
    }]

    assert_equal(expected, result)
  end

  def test_overwrite_middle()
    memory = H2gb::Vault::Memory.new()

    memory.transaction() do
      memory.insert(address: 0x00, data: "A", length: 0x41)
    end
    memory.transaction() do
      memory.insert(address: 0x21, data: "B", length: 0x01)
    end

    result = memory.get(address: 0x00, length: 0xFF)
    expected = [{
      :revision => 0x02,
      :address => 0x21,
      :data => "B",
      :length => 0x01,
      :refs => nil,
    }]

    assert_equal(expected, result)
  end

  def test_overwrite_multiple()
    memory = H2gb::Vault::Memory.new()

    memory.transaction() do
      memory.insert(address: 0x00, data: "A", length: 0x02)
    end
    memory.transaction() do
      memory.insert(address: 0x02, data: "B", length: 0x04)
    end
    memory.transaction() do
      memory.insert(address: 0x01, data: "C", length: 0x02)
    end

    result = memory.get(address: 0x00, length: 0xFF)
    expected = [{
      :revision => 0x03,
      :address => 0x01,
      :data => "C",
      :length => 0x02,
      :refs => nil,
    }]

    assert_equal(expected, result)
  end

  def test_overwrite_multiple_with_gap()
    memory = H2gb::Vault::Memory.new()

    memory.transaction() do
      memory.insert(address: 0x00, data: "A", length: 0x02)
    end
    memory.transaction() do
      memory.insert(address: 0x10, data: "B", length: 0x10)
    end
    memory.transaction() do
      memory.insert(address: 0x00, data: "C", length: 0x80)
    end

    result = memory.get(address: 0x00, length: 0xFF)
    expected = [{
      :revision => 0x03,
      :address => 0x00,
      :data => "C",
      :length => 0x80,
      :refs => nil,
    }]

    assert_equal(expected, result)
  end

  def test_undo()
    memory = H2gb::Vault::Memory.new()
    memory.transaction() do
      memory.insert(address: 0x00, data: "A", length: 0x02)
    end
    memory.transaction() do
      memory.insert(address: 0x02, data: "B", length: 0x02)
    end
    memory.undo()

    result = memory.get(address: 0x00, length: 0xFF)

    expected = [
      {
        :revision => 0x01,
        :address => 0x00,
        :data => "A",
        :length => 0x02,
        :refs => nil,
      },
    ]

    assert_equal(expected, result)
  end

  def test_undo_multiple_steps()
    memory = H2gb::Vault::Memory.new()
    memory.transaction() do
      memory.insert(address: 0x00, data: "A", length: 0x02)
    end
    memory.transaction() do
      memory.insert(address: 0x02, data: "B", length: 0x02)
    end
    memory.transaction() do
      memory.insert(address: 0x04, data: "C", length: 0x02)
    end

    result = memory.get(address: 0x00, length: 0xFF)
    expected = [
      {
        :revision => 0x01,
        :address => 0x00,
        :data => "A",
        :length => 0x02,
        :refs => nil,
      },
      {
        :revision => 0x02,
        :address => 0x02,
        :data => "B",
        :length => 0x02,
        :refs => nil,
      },
      {
        :revision => 0x03,
        :address => 0x04,
        :data => "C",
        :length => 0x02,
        :refs => nil,
      },
    ]
    assert_equal(expected, result)

    memory.undo()
    result = memory.get(address: 0x00, length: 0xFF)
    expected = [
      {
        :revision => 0x01,
        :address => 0x00,
        :data => "A",
        :length => 0x02,
        :refs => nil,
      },
      {
        :revision => 0x02,
        :address => 0x02,
        :data => "B",
        :length => 0x02,
        :refs => nil,
      },
    ]
    assert_equal(expected, result)

    memory.undo()
    result = memory.get(address: 0x00, length: 0xFF)
    expected = [
      {
        :revision => 0x01,
        :address => 0x00,
        :data => "A",
        :length => 0x02,
        :refs => nil,
      },
    ]
    assert_equal(expected, result)

    memory.undo()
    result = memory.get(address: 0x00, length: 0xFF)
    assert_equal([], result)
  end

  def test_undo_then_set()
    memory = H2gb::Vault::Memory.new()
    memory.transaction() do
      memory.insert(address: 0x00, data: "A", length: 0x02)
    end
    memory.transaction() do
      memory.insert(address: 0x02, data: "B", length: 0x02)
    end
    memory.undo()
    memory.transaction() do
      memory.insert(address: 0x04, data: "C", length: 0x02)
    end

    result = memory.get(address: 0x00, length: 0xFF)

    expected = [
      {
        :revision => 0x01,
        :address => 0x00,
        :data => "A",
        :length => 0x02,
        :refs => nil,
      },
      {
        :revision => 0x02,
        :address => 0x04,
        :data => "C",
        :length => 0x02,
        :refs => nil,
      },
    ]

    assert_equal(expected, result)
  end

  def test_undo_then_set_then_undo_again()
    memory = H2gb::Vault::Memory.new()
    memory.transaction() do
      memory.insert(address: 0x00, data: "A", length: 0x02)
    end
    memory.transaction() do
      memory.insert(address: 0x02, data: "B", length: 0x02)
    end
    memory.undo()
    memory.transaction() do
      memory.insert(address: 0x04, data: "C", length: 0x02)
    end

    result = memory.get(address: 0x00, length: 0xFF)
    expected = [
      {
        :revision => 0x01,
        :address => 0x00,
        :data => "A",
        :length => 0x02,
        :refs => nil,
      },
      {
        :revision => 0x02,
        :address => 0x04,
        :data => "C",
        :length => 0x02,
        :refs => nil,
      },
    ]
    assert_equal(expected, result)

    memory.undo()
    result = memory.get(address: 0x00, length: 0xFF)
    expected = [
      {
        :revision => 0x01,
        :address => 0x00,
        :data => "A",
        :length => 0x02,
        :refs => nil,
      },
    ]
    assert_equal(expected, result)
  end

  def test_undo_too_much()
    memory = H2gb::Vault::Memory.new()
    memory.transaction() do
      memory.insert(address: 0x00, data: "A", length: 0x02)
    end
    memory.undo()
    memory.undo()
    memory.undo()
    memory.undo()
    memory.undo()
    memory.undo()

    memory.transaction() do
      memory.insert(address: 0x00, data: "A", length: 0x02)
    end
    result = memory.get(address: 0x00, length: 0xFF)

    expected = [
      {
        :revision => 0x01,
        :address => 0x00,
        :data => "A",
        :length => 0x02,
        :refs => nil,
      },
    ]

    assert_equal(expected, result)
  end

  def test_undo_overwrite()
    memory = H2gb::Vault::Memory.new()
    memory.transaction() do
      memory.insert(address: 0x00, data: "A", length: 0x02)
    end

    result = memory.get(address: 0x00, length: 0xFF)
    expected = [
      {
        :revision => 0x01,
        :address => 0x00,
        :data => "A",
        :length => 0x02,
        :refs => nil,
      },
    ]
    assert_equal(expected, result)

    memory.transaction() do
      memory.insert(address: 0x01, data: "B", length: 0x02)
    end
    result = memory.get(address: 0x00, length: 0xFF)
    expected = [
      {
        :revision => 0x02,
        :address => 0x01,
        :data => "B",
        :length => 0x02,
        :refs => nil,
      },
    ]
    assert_equal(expected, result)

    memory.undo()
    result = memory.get(address: 0x00, length: 0xFF)
    expected = [
      {
        :revision => 0x01,
        :address => 0x00,
        :data => "A",
        :length => 0x02,
        :refs => nil,
      },
    ]
    assert_equal(expected, result)
  end

  def test_transaction_undo()
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
        :revision => 0x02,
        :address => 0x01,
        :data => "C",
        :length => 0x02,
        :refs => nil,
      },
      {
        :revision => 0x02,
        :address => 0x03,
        :data => "D",
        :length => 0x02,
        :refs => nil,
      },
    ]
    assert_equal(expected, result)

    memory.undo()

    result = memory.get(address: 0x00, length: 0xFF)
    expected = [
      {
        :revision => 0x01,
        :address => 0x00,
        :data => "A",
        :length => 0x02,
        :refs => nil,
      },
      {
        :revision => 0x01,
        :address => 0x02,
        :data => "B",
        :length => 0x02,
        :refs => nil,
      },
    ]
    assert_equal(expected, result)
  end

  def test_redo()
    memory = H2gb::Vault::Memory.new()
    memory.transaction() do
      memory.insert(address: 0x00, data: "A", length: 0x02)
    end
    memory.transaction() do
      memory.insert(address: 0x02, data: "B", length: 0x02)
    end
    memory.undo()
    memory.redo()

    result = memory.get(address: 0x00, length: 0xFF)

    expected = [
      {
        :revision => 0x01,
        :address => 0x00,
        :data => "A",
        :length => 0x02,
        :refs => nil,
      },
      {
        :revision => 0x02,
        :address => 0x02,
        :data => "B",
        :length => 0x02,
        :refs => nil,
      },
    ]

    assert_equal(expected, result)
  end

  def test_redo_multiple_steps()
    memory = H2gb::Vault::Memory.new()
    memory.transaction() do
      memory.insert(address: 0x00, data: "A", length: 0x02)
    end
    memory.transaction() do
      memory.insert(address: 0x02, data: "B", length: 0x02)
    end
    memory.transaction() do
      memory.insert(address: 0x04, data: "C", length: 0x02)
    end

    memory.undo()
    memory.undo()
    memory.undo()

    result = memory.get(address: 0x00, length: 0xFF)
    assert_equal([], result)

    memory.redo()
    result = memory.get(address: 0x00, length: 0xFF)
    expected = [
      {
        :revision => 0x01,
        :address => 0x00,
        :data => "A",
        :length => 0x02,
        :refs => nil,
      },
    ]
    assert_equal(expected, result)

    memory.redo()
    result = memory.get(address: 0x00, length: 0xFF)
    expected = [
      {
        :revision => 0x01,
        :address => 0x00,
        :data => "A",
        :length => 0x02,
        :refs => nil,
      },
      {
        :revision => 0x02,
        :address => 0x02,
        :data => "B",
        :length => 0x02,
        :refs => nil,
      },
    ]
    assert_equal(expected, result)

    memory.redo()
    result = memory.get(address: 0x00, length: 0xFF)
    expected = [
      {
        :revision => 0x01,
        :address => 0x00,
        :data => "A",
        :length => 0x02,
        :refs => nil,
      },
      {
        :revision => 0x02,
        :address => 0x02,
        :data => "B",
        :length => 0x02,
        :refs => nil,
      },
      {
        :revision => 0x03,
        :address => 0x04,
        :data => "C",
        :length => 0x02,
        :refs => nil,
      },
    ]
    assert_equal(expected, result)
  end

  def test_redo_then_set()
    memory = H2gb::Vault::Memory.new()
    memory.transaction() do
      memory.insert(address: 0x00, data: "A", length: 0x02)
    end
    memory.transaction() do
      memory.insert(address: 0x02, data: "B", length: 0x02)
    end
    memory.undo()
    memory.redo()
    memory.transaction() do
      memory.insert(address: 0x00, data: "C", length: 0x02)
    end

    result = memory.get(address: 0x00, length: 0xFF)

    expected = [
      {
        :revision => 0x03,
        :address => 0x00,
        :data => "C",
        :length => 0x02,
        :refs => nil,
      },
      {
        :revision => 0x02,
        :address => 0x02,
        :data => "B",
        :length => 0x02,
        :refs => nil,
      },
    ]

    assert_equal(expected, result)
  end

  def test_redo_goes_away_after_edit()
    memory = H2gb::Vault::Memory.new()
    memory.transaction() do
      memory.insert(address: 0x00, data: "A", length: 0x02)
    end
    memory.transaction() do
      memory.insert(address: 0x02, data: "B", length: 0x02)
    end
    memory.transaction() do
      memory.insert(address: 0x04, data: "C", length: 0x02)
    end

    puts()
    puts("Initial:")
    puts(memory)

    memory.undo()

    puts()
    puts("Undo 1:")
    puts(memory)

    memory.undo()

    puts()
    puts("Undo 2:")
    puts(memory)

    memory.undo()

    puts()
    puts("Undo 3:")
    puts(memory)

    result = memory.get(address: 0x00, length: 0xFF)
    assert_equal([], result)

    memory.redo()

    puts()
    puts("Redo 1:")
    puts(memory)

    result = memory.get(address: 0x00, length: 0xFF)
    expected = [
      {
        :revision => 0x01,
        :address => 0x00,
        :data => "A",
        :length => 0x02,
        :refs => nil,
      },
    ]
    assert_equal(expected, result)

    memory.transaction() do
      memory.insert(address: 0x06, data: "D", length: 0x02)
    end

    puts()
    puts("Insert")
    puts(memory)

    memory.redo() # Should do nothing

    puts()
    puts("Redo 2:")
    puts(memory)

    result = memory.get(address: 0x00, length: 0xFF)
    expected = [
      {
        :revision => 0x01,
        :address => 0x00,
        :data => "A",
        :length => 0x02,
        :refs => nil,
      },
      {
        :revision => 0x02,
        :address => 0x06,
        :data => "D",
        :length => 0x02,
        :refs => nil,
      },
    ]
    assert_equal(expected, result)
  end

  def test_redo_too_much()
    memory = H2gb::Vault::Memory.new()
    memory.transaction() do
      memory.insert(address: 0x00, data: "A", length: 0x02)
    end
    memory.undo()
    memory.undo()
    memory.redo()
    memory.redo()
    memory.redo()
    memory.redo()

    memory.transaction() do
      memory.insert(address: 0x02, data: "B", length: 0x02)
    end
    result = memory.get(address: 0x00, length: 0xFF)

    expected = [
      {
        :revision => 0x01,
        :address => 0x00,
        :data => "A",
        :length => 0x02,
        :refs => nil,
      },
      {
        :revision => 0x02,
        :address => 0x02,
        :data => "B",
        :length => 0x02,
        :refs => nil,
      },
    ]

    assert_equal(expected, result)
  end

  def test_redo_overwrite()
    memory = H2gb::Vault::Memory.new()
    memory.transaction() do
      memory.insert(address: 0x00, data: "A", length: 0x02)
    end
    memory.transaction() do
      memory.insert(address: 0x00, data: "B", length: 0x01)
    end
    memory.transaction() do
      memory.insert(address: 0x00, data: "C", length: 0x03)
    end

    memory.undo()
    memory.undo()
    memory.undo()
    memory.redo()
    memory.redo()
    memory.redo()

    result = memory.get(address: 0x00, length: 0xFF)
    expected = [
      {
        :revision => 0x03,
        :address => 0x00,
        :data => "C",
        :length => 0x03,
        :refs => nil,
      },
    ]
    assert_equal(expected, result)
  end

  def test_transaction_redo()
    memory = H2gb::Vault::Memory.new()
    memory.transaction() do
      memory.insert(address: 0x00, data: "A", length: 0x02)
      memory.insert(address: 0x02, data: "B", length: 0x02)
    end

    memory.transaction() do
      memory.insert(address: 0x01, data: "C", length: 0x02)
      memory.insert(address: 0x03, data: "D", length: 0x02)
    end

    memory.undo()
    memory.redo()

    result = memory.get(address: 0x00, length: 0xFF)
    expected = [
      {
        :revision => 0x02,
        :address => 0x01,
        :data => "C",
        :length => 0x02,
        :refs => nil,
      },
      {
        :revision => 0x02,
        :address => 0x03,
        :data => "D",
        :length => 0x02,
        :refs => nil,
      },
    ]
    assert_equal(expected, result)
  end

  def test_memory_entry_is_private()
    assert_raises(NameError) do
      H2gb::Vault::Memory::MemoryEntry.new(address: 0)
    end
  end

  # TODO: I don't think get_changes_since will work, since @revision jumps
  # around. Now that (as of the time of this commenting) I have all my undo and
  # redo tests passing, and a good idea of where the pain points are, I think
  # I have to re-design the revision code so that the revision number is
  # constantly incrementing.
  def test_get_changes_since()
  end
end
