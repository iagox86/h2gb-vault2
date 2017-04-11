require 'test_helper'

require 'h2gb/vault/memory/memory'

class H2gb::Vault::InsertTest < Test::Unit::TestCase
  def test_empty()
    memory = H2gb::Vault::Memory.new()
    result = memory.get(address: 0x00, length: 0xFF)
    expected = {
      revision: 0x00,
      entries: [],
    }
    assert_equal(expected, result)
  end

  def test_single_entry()
    memory = H2gb::Vault::Memory.new()
    memory.transaction() do
      memory.insert(address: 0x00, data: "A", length: 0x01)
    end

    result = memory.get(address: 0x00, length: 0x01)
    expected = {
      revision: 0x1,
      entries: [{
        address: 0x00,
        data:    "A",
        length:  0x01,
        refs:    nil,
      }]
    }

    assert_equal(expected, result)
  end

  def test_get_longer_entry()
    memory = H2gb::Vault::Memory.new()
    memory.transaction() do
      memory.insert(address: 0x00, data: "A", length: 0x40)
    end

    result = memory.get(address: 0x00, length: 0xFF)
    expected = {
      revision: 1,
      entries: [{
        address: 0x00,
        data:    "A",
        length:  0x40,
        refs:    nil,
      }]
    }

    assert_equal(expected, result)
  end

  def test_get_entry_in_middle()
    memory = H2gb::Vault::Memory.new()
    memory.transaction() do
      memory.insert(address: 0x80, data: "A", length: 0x01)
    end

    result = memory.get(address: 0x00, length: 0xFF)
    expected = {
      revision: 0x01,
      entries: [{
        address: 0x80,
        data:    "A",
        length:  0x01,
        refs:    nil,
      }]
    }

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

    expected = {
      revision: 0x02,
      entries: [
        {
          address: 0x00,
          data: "A",
          length: 0x02,
          refs: nil,
        },
        {
          address: 0x02,
          data: "B",
          length: 0x02,
          refs: nil,
        }
      ]
    }

    assert_equal(expected, result)
  end

  def test_two_adjacent_in_same_transaction()
    memory = H2gb::Vault::Memory.new()
    memory.transaction do
      memory.insert(address: 0x00, data: "A", length: 0x02)
      memory.insert(address: 0x02, data: "B", length: 0x02)
    end

    result = memory.get(address: 0x00, length: 0xFF)

    expected = {
      revision: 1,
      entries: [
        {
          address: 0x00,
          data: "A",
          length: 0x02,
          refs: nil,
        },
        {
          address: 0x02,
          data: "B",
          length: 0x02,
          refs: nil,
        }
      ]
    }

    assert_equal(expected, result)
  end

  def test_two_not_adjacent()
    memory = H2gb::Vault::Memory.new()
    memory.transaction() do
      memory.insert(address: 0x00, data: "A", length: 0x02)
      memory.insert(address: 0x80, data: "B", length: 0x02)
    end

    result = memory.get(address: 0x00, length: 0xFF)

    expected = {
      revision: 0x01,
      entries: [
        {
          address: 0x00,
          data: "A",
          length: 0x02,
          refs: nil,
        },
        {
          address: 0x80,
          data: "B",
          length: 0x02,
          refs: nil,
        }
      ]
    }

    assert_equal(expected, result)
  end

#  # The goal of this test is to make sure that our array works as a sparse array
#  # and doesn't try to allocate memory for everything
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
    expected = {
      revision: 0x02,
      entries: [
        {
          address: 0x00,
          data: "A",
          length: 0x02,
          refs: nil,
        },
      ]
    }
    assert_equal(expected, result)

    result = memory.get(address: 0x0800000000000000, length: 0xFF)
    expected = {
      revision: 0x02,
      entries: [
        {
          address: 0x0800000000000000,
          data: "B",
          length: 0x02,
          refs: nil,
        },
      ]
    }
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
    expected = {
      revision: 0x02,
      entries: [{
        address: 0x00,
        data: "B",
        length: 0x01,
        refs: nil,
      }]
    }

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
    expected = {
      revision: 0x02,
      entries: [{
        address: 0x00,
        data: "B",
        length: 0x01,
        refs: nil,
      }]
    }

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
    expected = {
      revision: 0x02,
      entries: [{
        address: 0x21,
        data: "B",
        length: 0x01,
        refs: nil,
      }]
    }

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
    expected = {
      revision: 0x03,
      entries: [{
        address: 0x01,
        data: "C",
        length: 0x02,
        refs: nil,
      }]
    }

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
    expected = {
      revision: 0x03,
      entries: [{
        address: 0x00,
        data: "C",
        length: 0x80,
        refs: nil,
      }]
    }

    assert_equal(expected, result)
  end
end

##
# Since we already use transactions throughout other tests, this will simply
# ensure that transactions are required.
##
class H2gb::Vault::TransactionTest < Test::Unit::TestCase
  def test_add_transaction()
    memory = H2gb::Vault::Memory.new()
    assert_raises(H2gb::Vault::Memory::MemoryError) do
      memory.insert(address: 0x00, length: 0x01, data: 'A')
    end
  end

  def test_delete_transaction()
    memory = H2gb::Vault::Memory.new()
    assert_raises(H2gb::Vault::Memory::MemoryError) do
      memory.delete(address: 0x00, length: 0x01)
    end
  end

  def test_revision_increment()
    memory = H2gb::Vault::Memory.new()

    result = memory.get(address: 0x00, length: 0x00)
    assert_equal(0, result[:revision])

    memory.transaction() do
    end

    result = memory.get(address: 0x00, length: 0x00)
    assert_equal(1, result[:revision])
  end
end

class H2gb::Vault::DeleteTest < Test::Unit::TestCase
  def test_delete_nothing()
    memory = H2gb::Vault::Memory.new()
    memory.transaction() do
      memory.delete(address: 0x00, length: 0xFF)
    end

    result = memory.get(address: 0x00, length: 0xFF)

    expected = {
      revision: 0x01,
      entries: [],
    }
    assert_equal(expected, result)
  end

  def test_delete_one_byte()
    memory = H2gb::Vault::Memory.new()
    memory.transaction() do
      memory.insert(address: 0x00, data: "A", length: 0x01)
    end

    memory.transaction() do
      memory.delete(address: 0x00, length: 0x01)
    end

    result = memory.get(address: 0x00, length: 0xFF)
    expected = {
      revision: 0x02,
      entries: [],
    }

    assert_equal(expected, result)
  end

  def test_delete_multi_bytes()
    memory = H2gb::Vault::Memory.new()
    memory.transaction() do
      memory.insert(address: 0x00, data: "A", length: 0x10)
    end

    memory.transaction() do
      memory.delete(address: 0x00, length: 0x10)
    end

    result = memory.get(address: 0x00, length: 0xFF)
    expected = {
      revision: 0x02,
      entries: [],
    }

    assert_equal(expected, result)
  end

  def test_delete_zero_bytes()
    memory = H2gb::Vault::Memory.new()
    memory.transaction() do
      memory.insert(address: 0x00, data: "A", length: 0x10)
    end

    memory.transaction() do
      memory.delete(address: 0x00, length: 0x0)
    end

    result = memory.get(address: 0x00, length: 0xFF)
    expected = {
      revision: 0x02,
      entries: [{
        address: 0x00,
        data:    "A",
        length:  0x10,
        refs:    nil,
      }],
    }

    assert_equal(expected, result)
  end

  def test_delete_just_start()
    memory = H2gb::Vault::Memory.new()
    memory.transaction() do
      memory.insert(address: 0x00, data: "A", length: 0x10)
    end

    memory.transaction() do
      memory.delete(address: 0x00, length: 0x01)
    end

    result = memory.get(address: 0x00, length: 0xFF)
    expected = {
      revision: 0x02,
      entries: [],
    }

    assert_equal(expected, result)
  end

  def test_delete_just_middle()
    memory = H2gb::Vault::Memory.new()
    memory.transaction() do
      memory.insert(address: 0x00, data: "A", length: 0x10)
    end

    memory.transaction() do
      memory.delete(address: 0x00, length: 0x08)
    end

    result = memory.get(address: 0x00, length: 0xFF)
    expected = {
      revision: 0x02,
      entries: [],
    }

    assert_equal(expected, result)
  end

  def test_delete_multiple_entries()
    memory = H2gb::Vault::Memory.new()
    memory.transaction() do
      memory.insert(address: 0x00, data: "A", length: 0x10)
      memory.insert(address: 0x00, data: "B", length: 0x10)
      memory.insert(address: 0x00, data: "C", length: 0x10)
    end

    memory.transaction() do
      memory.delete(address: 0x00, length: 0xFF)
    end

    result = memory.get(address: 0x00, length: 0xFF)
    expected = {
      revision: 0x02,
      entries: [],
    }

    assert_equal(expected, result)
  end

  def test_delete_but_leave_adjacent()
    memory = H2gb::Vault::Memory.new()
    memory.transaction() do
      memory.insert(address: 0x00, data: "A", length: 0x10)
      memory.insert(address: 0x10, data: "B", length: 0x10)
      memory.insert(address: 0x20, data: "C", length: 0x10)
    end
    memory.transaction() do
      memory.delete(address: 0x10, length: 0x10)
    end

    result = memory.get(address: 0x00, length: 0xFF)
    expected = {
      revision: 0x02,
      entries: [
        {
          address: 0x00,
          data:    "A",
          length:  0x10,
          refs:    nil,
        },
        {
          address: 0x20,
          data:    "C",
          length:  0x10,
          refs:    nil,
        }
      ],
    }
    assert_equal(expected, result)
  end

  def test_delete_multi_but_leave_adjacent()
    memory = H2gb::Vault::Memory.new()
    memory.transaction() do
      memory.insert(address: 0x00, data: "A", length: 0x10)
      memory.insert(address: 0x10, data: "B", length: 0x10)
      memory.insert(address: 0x20, data: "C", length: 0x10)
      memory.insert(address: 0x30, data: "D", length: 0x10)
    end
    memory.transaction() do
      memory.delete(address: 0x18, length: 0x10)
    end

    result = memory.get(address: 0x00, length: 0xFF)
    expected = {
      revision: 0x02,
      entries: [
        {
          address: 0x00,
          data:    "A",
          length:  0x10,
          refs:    nil,
        },
        {
          address: 0x30,
          data:    "D",
          length:  0x10,
          refs:    nil,
        }
      ],
    }
    assert_equal(expected, result)
  end
end

class H2gb::Vault::UndoTest < Test::Unit::TestCase
  def test_basic_undo()
    memory = H2gb::Vault::Memory.new()
    memory.transaction() do
      memory.insert(address: 0x00, data: "A", length: 0x02)
    end
    memory.transaction() do
      memory.insert(address: 0x02, data: "B", length: 0x02)
    end
    memory.undo()

    result = memory.get(address: 0x00, length: 0xFF)

    expected = {
      revision: 0x03,
      entries: [{
        address: 0x00,
        data: "A",
        length: 0x02,
        refs: nil,
      }],
    }

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
    expected = {
      revision: 0x03,
      entries: [
        {
          address: 0x00,
          data: "A",
          length: 0x02,
          refs: nil,
        },
        {
          address: 0x02,
          data: "B",
          length: 0x02,
          refs: nil,
        },
        {
          address: 0x04,
          data: "C",
          length: 0x02,
          refs: nil,
        },
      ]
    }
    assert_equal(expected, result)

    memory.undo()
    result = memory.get(address: 0x00, length: 0xFF)
    expected = {
      revision: 0x04,
      entries: [
        {
          address: 0x00,
          data: "A",
          length: 0x02,
          refs: nil,
        },
        {
          address: 0x02,
          data: "B",
          length: 0x02,
          refs: nil,
        },
      ]
    }
    assert_equal(expected, result)

    memory.undo()
    result = memory.get(address: 0x00, length: 0xFF)
    expected = {
      revision: 0x05,
      entries: [
        {
          address: 0x00,
          data: "A",
          length: 0x02,
          refs: nil,
        },
      ]
    }
    assert_equal(expected, result)

    memory.undo()
    result = memory.get(address: 0x00, length: 0xFF)
    expected = {
      revision: 0x06,
      entries: [],
    }
    assert_equal(expected, result)
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

    expected = {
      revision: 4,
      entries: [
        {
          address: 0x00,
          data: "A",
          length: 0x02,
          refs: nil,
        },
        {
          address: 0x04,
          data: "C",
          length: 0x02,
          refs: nil,
        },
      ]
    }

    assert_equal(expected, result)
  end

  ##
  # Attempts to exercise the situation where an undo would inappropriately undo
  # another undo.
  ##
  def test_undo_across_other_undos()
    memory = H2gb::Vault::Memory.new()
    memory.transaction() do
      memory.insert(address: 0x00, data: "A", length: 0x02)
    end
    memory.transaction() do
      memory.insert(address: 0x02, data: "B", length: 0x02)
    end

    memory.undo() # undo B

    result = memory.get(address: 0x00, length: 0xFF)
    expected = {
      revision: 0x03,
      entries: [{
          address: 0x00,
          data: "A",
          length: 0x02,
          refs: nil,
      }],
    }
    assert_equal(expected, result)

    memory.transaction() do
      memory.insert(address: 0x04, data: "C", length: 0x02)
    end

    result = memory.get(address: 0x00, length: 0xFF)
    expected = {
      revision: 0x04,
      entries: [
        {
          address: 0x00,
          data: "A",
          length: 0x02,
          refs: nil,
        },
        {
          address: 0x04,
          data: "C",
          length: 0x02,
          refs: nil,
        }
      ],
    }
    assert_equal(expected, result)

    memory.undo() # undo C

    result = memory.get(address: 0x00, length: 0xFF)
    expected = {
      revision: 0x05,
      entries: [{
          address: 0x00,
          data: "A",
          length: 0x02,
          refs: nil,
      }],
    }
    assert_equal(expected, result)

    memory.undo() # undo A

    result = memory.get(address: 0x00, length: 0xFF)
    expected = {
      revision: 0x06,
      entries: [],
    }
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
    expected = {
      revision: 0x04,
      entries: [
        {
          address: 0x00,
          data: "A",
          length: 0x02,
          refs: nil,
        },
        {
          address: 0x04,
          data: "C",
          length: 0x02,
          refs: nil,
        },
      ]
    }
    assert_equal(expected, result)

    memory.undo()
    result = memory.get(address: 0x00, length: 0xFF)
    expected = {
      revision: 0x05,
      entries: [{
        address: 0x00,
        data: "A",
        length: 0x02,
        refs: nil,
      }]
    }
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

    expected = {
      revision: 0x03,
      entries: [{
        address: 0x00,
        data: "A",
        length: 0x02,
        refs: nil,
      }]
    }

    assert_equal(expected, result)
  end

  def test_undo_overwrite()
    memory = H2gb::Vault::Memory.new()
    memory.transaction() do
      memory.insert(address: 0x00, data: "A", length: 0x02)
    end

    result = memory.get(address: 0x00, length: 0xFF)
    expected = {
      revision: 0x01,
      entries: [{
        address: 0x00,
        data: "A",
        length: 0x02,
        refs: nil,
      }]
    }
    assert_equal(expected, result)

    memory.transaction() do
      memory.insert(address: 0x01, data: "B", length: 0x02)
    end
    result = memory.get(address: 0x00, length: 0xFF)
    expected = {
      revision: 0x02,
      entries: [{
        address: 0x01,
        data: "B",
        length: 0x02,
        refs: nil,
      }]
    }
    assert_equal(expected, result)

    memory.undo()
    result = memory.get(address: 0x00, length: 0xFF)
    expected = {
      revision: 0x03,
      entries: [{
        address: 0x00,
        data: "A",
        length: 0x02,
        refs: nil,
      }]
    }
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
    expected = {
      revision: 0x02,
        entries: [
        {
          address: 0x01,
          data: "C",
          length: 0x02,
          refs: nil,
        },
        {
          address: 0x03,
          data: "D",
          length: 0x02,
          refs: nil,
        },
      ]
    }
    assert_equal(expected, result)

    memory.undo()

    result = memory.get(address: 0x00, length: 0xFF)
    expected = {
      revision: 0x03,
      entries: [
        {
          address: 0x00,
          data: "A",
          length: 0x02,
          refs: nil,
        },
        {
          address: 0x02,
          data: "B",
          length: 0x02,
          refs: nil,
        },
      ]
    }
    assert_equal(expected, result)
  end
end

class H2gb::Vault::RedoTest < Test::Unit::TestCase
  def test_basic_redo()
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

    expected = {
      revision: 0x04,
      entries: [
        {
          address: 0x00,
          data: "A",
          length: 0x02,
          refs: nil,
        },
        {
          address: 0x02,
          data: "B",
          length: 0x02,
          refs: nil,
        },
      ]
    }

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
    expected = {
      revision: 0x06,
      entries: []
    }
    assert_equal(expected, result)

    memory.redo()
    result = memory.get(address: 0x00, length: 0xFF)
    expected = {
      revision: 0x07,
      entries: [
        {
          address: 0x00,
          data: "A",
          length: 0x02,
          refs: nil,
        },
      ]
    }
    assert_equal(expected, result)

    memory.redo()
    result = memory.get(address: 0x00, length: 0xFF)
    expected = {
      revision: 0x08,
      entries: [
        {
          address: 0x00,
          data: "A",
          length: 0x02,
          refs: nil,
        },
        {
          address: 0x02,
          data: "B",
          length: 0x02,
          refs: nil,
        },
      ]
    }
    assert_equal(expected, result)

    memory.redo()
    result = memory.get(address: 0x00, length: 0xFF)
    expected = {
      revision: 0x09,
      entries: [
        {
          address: 0x00,
          data: "A",
          length: 0x02,
          refs: nil,
        },
        {
          address: 0x02,
          data: "B",
          length: 0x02,
          refs: nil,
        },
        {
          address: 0x04,
          data: "C",
          length: 0x02,
          refs: nil,
        },
      ]
    }
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

    expected = {
      revision: 0x05,
      entries: [
        {
          address: 0x00,
          data: "C",
          length: 0x02,
          refs: nil,
        },
        {
          address: 0x02,
          data: "B",
          length: 0x02,
          refs: nil,
        },
      ]
    }

    assert_equal(expected, result)
  end

  ##
  # Attempts to exercise the situation where an undo would inappropriately undo
  # another undo.
  ##
  def test_redo_across_other_undos()
    memory = H2gb::Vault::Memory.new()
    memory.transaction() do
      memory.insert(address: 0x00, data: "A", length: 0x02)
    end
    memory.transaction() do
      memory.insert(address: 0x02, data: "B", length: 0x02)
    end

    memory.undo() # undo B

    result = memory.get(address: 0x00, length: 0xFF)
    expected = {
      revision: 0x03,
      entries: [{
          address: 0x00,
          data: "A",
          length: 0x02,
          refs: nil,
      }],
    }
    assert_equal(expected, result)

    memory.transaction() do
      memory.insert(address: 0x04, data: "C", length: 0x02)
    end

    result = memory.get(address: 0x00, length: 0xFF)
    expected = {
      revision: 0x04,
      entries: [
        {
          address: 0x00,
          data: "A",
          length: 0x02,
          refs: nil,
        },
        {
          address: 0x04,
          data: "C",
          length: 0x02,
          refs: nil,
        }
      ],
    }
    assert_equal(expected, result)

    memory.undo() # undo C

    result = memory.get(address: 0x00, length: 0xFF)
    expected = {
      revision: 0x05,
      entries: [{
          address: 0x00,
          data: "A",
          length: 0x02,
          refs: nil,
      }],
    }
    assert_equal(expected, result)

    memory.undo() # undo A

    result = memory.get(address: 0x00, length: 0xFF)
    expected = {
      revision: 0x06,
      entries: [],
    }
    assert_equal(expected, result)

    memory.redo() # redo A

    result = memory.get(address: 0x00, length: 0xFF)
    expected = {
      revision: 0x07,
      entries: [
        {
          address: 0x00,
          data: "A",
          length: 0x02,
          refs: nil,
        },
      ],
    }
    assert_equal(expected, result)

    memory.redo() # redo C

    result = memory.get(address: 0x00, length: 0xFF)
    expected = {
      revision: 0x08,
      entries: [
        {
          address: 0x00,
          data: "A",
          length: 0x02,
          refs: nil,
        },
        {
          address: 0x04,
          data: "C",
          length: 0x02,
          refs: nil,
        }
      ],
    }
    assert_equal(expected, result)

    memory.redo() # Should do nothing
    result = memory.get(address: 0x00, length: 0xFF)
    expected = {
      revision: 0x08,
      entries: [
        {
          address: 0x00,
          data: "A",
          length: 0x02,
          refs: nil,
        },
        {
          address: 0x04,
          data: "C",
          length: 0x02,
          refs: nil,
        }
      ],
    }
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

    memory.undo()
    memory.undo()
    memory.undo()

    result = memory.get(address: 0x00, length: 0xFF)
    assert_equal({
      revision: 0x06,
      entries: [],
    }, result)

    memory.redo()

    result = memory.get(address: 0x00, length: 0xFF)
    expected = {
      revision: 0x07,
      entries: [
        {
          address: 0x00,
          data: "A",
          length: 0x02,
          refs: nil,
        },
      ]
    }
    assert_equal(expected, result)

    memory.transaction() do
      memory.insert(address: 0x06, data: "D", length: 0x02)
    end

    memory.redo() # Should do nothing

    result = memory.get(address: 0x00, length: 0xFF)
    expected = {
      revision: 0x08,
      entries: [
        {
          address: 0x00,
          data: "A",
          length: 0x02,
          refs: nil,
        },
        {
          address: 0x06,
          data: "D",
          length: 0x02,
          refs: nil,
        },
      ]
    }
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

    expected = {
      revision: 0x04,
      entries: [
        {
          address: 0x00,
          data: "A",
          length: 0x02,
          refs: nil,
        },
        {
          address: 0x02,
          data: "B",
          length: 0x02,
          refs: nil,
        },
      ]
    }

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
    expected = {
      revision: 0x09,
      entries: [
        {
          address: 0x00,
          data: "C",
          length: 0x03,
          refs: nil,
        },
      ]
    }
    assert_equal(expected, result)
  end

  def test_transaction_redo()
    memory = H2gb::Vault::Memory.new()
    memory.transaction() do
      memory.insert(address: 0x00, data: "A", length: 0x02)
      memory.insert(address: 0x02, data: "B", length: 0x02)
      memory.insert(address: 0x00, data: "C", length: 0x02)
      memory.insert(address: 0x04, data: "D", length: 0x02)
    end

    memory.transaction() do
      memory.insert(address: 0x01, data: "E", length: 0x02)
      memory.insert(address: 0x06, data: "F", length: 0x02)
    end

    result = memory.get(address: 0x00, length: 0xFF)
    expected = {
      revision: 0x02,
      entries: [
        {
          address: 0x01,
          data: "E",
          length: 0x02,
          refs: nil,
        },
        {
          address: 0x04,
          data: "D",
          length: 0x02,
          refs: nil,
        },
        {
          address: 0x06,
          data: "F",
          length: 0x02,
          refs: nil,
        },
      ]
    }
    assert_equal(expected, result)

    memory.undo()

      memory.insert(address: 0x00, data: "A", length: 0x02)
      memory.insert(address: 0x02, data: "B", length: 0x02)
      memory.insert(address: 0x00, data: "C", length: 0x02)
      memory.insert(address: 0x04, data: "D", length: 0x02)
    result = memory.get(address: 0x00, length: 0xFF)
    expected = {
      revision: 0x03,
      entries: [
        {
          address: 0x00,
          data: "C",
          length: 0x02,
          refs: nil,
        },
        {
          address: 0x02,
          data: "B",
          length: 0x02,
          refs: nil,
        },
        {
          address: 0x04,
          data: "D",
          length: 0x02,
          refs: nil,
        },
      ]
    }
    assert_equal(expected, result)

    memory.redo()

    result = memory.get(address: 0x00, length: 0xFF)
    expected = {
      revision: 0x04,
      entries: [
        {
          address: 0x01,
          data: "E",
          length: 0x02,
          refs: nil,
        },
        {
          address: 0x04,
          data: "D",
          length: 0x02,
          refs: nil,
        },
        {
          address: 0x06,
          data: "F",
          length: 0x02,
          refs: nil,
        },
      ]
    }
    assert_equal(expected, result)
  end
end

class H2gb::Vault::GetChangesSinceTest < Test::Unit::TestCase
  def test_get_changes_since()
  end
end

class H2gb::Vault::SaveRestoreTest < Test::Unit::TestCase
end
