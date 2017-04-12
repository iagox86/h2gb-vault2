require 'test_helper'

require 'h2gb/vault/memory/memory_transaction'

class H2gb::Vault::MemoryTransactionTest < Test::Unit::TestCase
  def test_empty()
    memory_transaction = H2gb::Vault::Memory::MemoryTransaction.new(
      opposites: {},
    )

    memory_transaction.undo_transaction() do |action, entry|
      assert_true(false) # Should not happen
    end

    memory_transaction.redo_transaction() do |action, entry|
      assert_true(false) # Should not happen
    end
  end

  def test_one_transaction_entry()
    memory_transaction = H2gb::Vault::Memory::MemoryTransaction.new(
      opposites: {},
    )

    assert_equal(0, memory_transaction.revision)
    memory_transaction.increment()
    assert_equal(1, memory_transaction.revision)

    expected = {
      entries: [],
      undoable: true,
    }
    assert_equal(expected, memory_transaction._test_get_transaction(revision: 1))
  end

  def test_multiple_transaction_entries()
    memory_transaction = H2gb::Vault::Memory::MemoryTransaction.new(
      opposites: {},
    )

    assert_equal(0, memory_transaction.revision)
    memory_transaction.increment()
    assert_equal(1, memory_transaction.revision)
    memory_transaction.increment()
    assert_equal(2, memory_transaction.revision)

    expected = {
      entries: [],
      undoable: true,
    }
    assert_equal(expected, memory_transaction._test_get_transaction(revision: 1))
    assert_equal(expected, memory_transaction._test_get_transaction(revision: 2))
  end

  def test_add_to_transaction()
    memory_transaction = H2gb::Vault::Memory::MemoryTransaction.new(
      opposites: {},
    )

    memory_transaction.increment()
    memory_transaction.add_to_current_transaction(type: :a, entry: "1")

    expected = {
      entries: [{
        type: :a,
        entry: "1",
      }],
      undoable: true,
    }
    assert_equal(expected, memory_transaction._test_get_transaction(revision: 1))
  end

  def test_add_multiple_to_transaction()
    memory_transaction = H2gb::Vault::Memory::MemoryTransaction.new(
      opposites: {},
    )

    memory_transaction.increment()
    memory_transaction.add_to_current_transaction(type: :a, entry: "1")
    memory_transaction.add_to_current_transaction(type: :a, entry: "2")

    expected = {
      entries: [
        {
          type: :a,
          entry: "1",
        },
        {
          type: :a,
          entry: "2",
        }
      ],
      undoable: true,
    }
    assert_equal(expected, memory_transaction._test_get_transaction(revision: 1))
  end
end

class H2gb::Vault::MemoryTransactionUndoTest < Test::Unit::TestCase
  def test_undo_nothing()
    memory_transaction = H2gb::Vault::Memory::MemoryTransaction.new(
      opposites: {},
    )

    memory_transaction.increment()
    memory_transaction.undo_transaction() do
      assert_true(false) # Should never happen
    end
  end

  def test_basic_undo()
    memory_transaction = H2gb::Vault::Memory::MemoryTransaction.new(
      opposites: {:a => :A, :A => :a},
    )

    memory_transaction.increment()
    memory_transaction.add_to_current_transaction(type: :a, entry: "1")
    assert_equal(1, memory_transaction.revision)
    results = []
    memory_transaction.undo_transaction() do |type, entry|
      results << {
        type: type,
        entry: entry,
      }
    end
    assert_equal(2, memory_transaction.revision)

    expected = [{
      type: :A,
      entry: "1",
    }]

    assert_equal(expected, results)
  end

  def test_undo_multiple()
    memory_transaction = H2gb::Vault::Memory::MemoryTransaction.new(
      opposites: {:a => :A, :A => :a},
    )

    memory_transaction.increment()
    memory_transaction.add_to_current_transaction(type: :a, entry: "1")
    memory_transaction.add_to_current_transaction(type: :a, entry: "2")
    memory_transaction.add_to_current_transaction(type: :a, entry: "3")
    assert_equal(1, memory_transaction.revision)

    results = []
    memory_transaction.undo_transaction() do |type, entry|
      results << {
        type: type,
        entry: entry,
      }
    end
    assert_equal(2, memory_transaction.revision)

    # Note that the order is backwards
    expected = [
      {
        type: :A,
        entry: "3",
      },
      {
        type: :A,
        entry: "2",
      },
      {
        type: :A,
        entry: "1",
      },
    ]

    assert_equal(expected, results)
  end

  def test_not_undoable()
    memory_transaction = H2gb::Vault::Memory::MemoryTransaction.new(
      opposites: {:a => :A, :A => :a},
    )

    memory_transaction.increment(undoable: false)
    memory_transaction.add_to_current_transaction(type: :a, entry: "1")
    assert_equal(1, memory_transaction.revision)
    memory_transaction.undo_transaction() do |type, entry|
      assert_true(false) # Shouldn't happen
    end
    # Revision doesn't change
    assert_equal(1, memory_transaction.revision)
  end

  def test_skip_not_undoable()
    memory_transaction = H2gb::Vault::Memory::MemoryTransaction.new(
      opposites: {:a => :A, :A => :a},
    )

    memory_transaction.increment()
    memory_transaction.add_to_current_transaction(type: :a, entry: "1")
    assert_equal(1, memory_transaction.revision)

    memory_transaction.increment(undoable: false)
    memory_transaction.add_to_current_transaction(type: :a, entry: "2")
    assert_equal(2, memory_transaction.revision)

    results = []
    memory_transaction.undo_transaction() do |type, entry|
      results << {
        type: type,
        entry: entry,
      }
    end

    expected = [{
      type: :A,
      entry: "1",
    }]
    assert_equal(expected, results)

    memory_transaction.undo_transaction() do
      assert_true(false)
    end
  end

  def test_undo_multiple_steps()
    memory_transaction = H2gb::Vault::Memory::MemoryTransaction.new(
      opposites: {:a => :A, :A => :a},
    )

    memory_transaction.increment()
    memory_transaction.add_to_current_transaction(type: :a, entry: "1")
    memory_transaction.add_to_current_transaction(type: :a, entry: "2")
    assert_equal(1, memory_transaction.revision)

    memory_transaction.increment()
    memory_transaction.add_to_current_transaction(type: :a, entry: "3")
    assert_equal(2, memory_transaction.revision)

    results = []
    memory_transaction.undo_transaction() do |type, entry|
      results << {
        type: type,
        entry: entry,
      }
    end

    expected = [{
      type: :A,
      entry: "3",
    }]
    assert_equal(expected, results)

    results = []
    memory_transaction.undo_transaction() do |type, entry|
      results << {
        type: type,
        entry: entry,
      }
    end

    expected = [
      {
        type: :A,
        entry: "2",
      },
      {
        type: :A,
        entry: "1",
      },
    ]
    assert_equal(expected, results)
  end

  def test_undo_across_other_undos()
    memory_transaction = H2gb::Vault::Memory::MemoryTransaction.new(
      opposites: {:a => :A, :A => :a},
    )

    memory_transaction.increment()
    memory_transaction.add_to_current_transaction(type: :a, entry: "1")
    memory_transaction.increment()
    memory_transaction.add_to_current_transaction(type: :a, entry: "2")

    results = []
    memory_transaction.undo_transaction() do |type, entry|
      results << {
        type: type,
        entry: entry,
      }
    end
    expected = [
      {
        type: :A,
        entry: "2",
      },
    ]
    assert_equal(expected, results)

    memory_transaction.increment()
    memory_transaction.add_to_current_transaction(type: :a, entry: "3")

    results = []
    memory_transaction.undo_transaction() do |type, entry|
      results << {
        type: type,
        entry: entry,
      }
    end
    expected = [
      {
        type: :A,
        entry: "3",
      },
    ]
    assert_equal(expected, results)

    results = []
    memory_transaction.undo_transaction() do |type, entry|
      results << {
        type: type,
        entry: entry,
      }
    end
    expected = [
      {
        type: :A,
        entry: "1",
      },
    ]
    assert_equal(expected, results)
  end

  def test_undo_too_much()
    memory_transaction = H2gb::Vault::Memory::MemoryTransaction.new(
      opposites: {:a => :A, :A => :a},
    )

    memory_transaction.increment()
    assert_equal(1, memory_transaction.revision)

    memory_transaction.add_to_current_transaction(type: :a, entry: "1")

    memory_transaction.undo_transaction() do |type, entry|
    end
    assert_equal(2, memory_transaction.revision)

    memory_transaction.undo_transaction() do |type, entry|
      assert_true(false) # Should never happen
    end
    assert_equal(2, memory_transaction.revision)

    memory_transaction.undo_transaction() do |type, entry|
      assert_true(false) # Should never happen
    end
    assert_equal(2, memory_transaction.revision)
  end
end

class H2gb::Vault::MemoryTransactionRedoTest < Test::Unit::TestCase
  def test_basic_redo()
    memory_transaction = H2gb::Vault::Memory::MemoryTransaction.new(
      opposites: {:a => :A, :A => :a},
    )

    memory_transaction.increment()
    memory_transaction.add_to_current_transaction(type: :a, entry: "1")
    assert_equal(1, memory_transaction.revision)

    results = []
    memory_transaction.undo_transaction() do |type, entry|
      results << {
        type: type,
        entry: entry,
      }
    end
    assert_equal(2, memory_transaction.revision)

    expected = [{
      type: :A,
      entry: "1",
    }]
    assert_equal(expected, results)

    results = []
    memory_transaction.redo_transaction() do |type, entry|
      results << {
        type: type,
        entry: entry,
      }
    end
    assert_equal(3, memory_transaction.revision)

    expected = [{
      type: :a,
      entry: "1",
    }]
    assert_equal(expected, results)
  end

  def test_redo_multiple_steps()
    memory_transaction = H2gb::Vault::Memory::MemoryTransaction.new(
      opposites: {:a => :A, :A => :a},
    )

    memory_transaction.increment()
    memory_transaction.add_to_current_transaction(type: :a, entry: "1")
    memory_transaction.add_to_current_transaction(type: :a, entry: "2")
    assert_equal(1, memory_transaction.revision)

    results = []
    memory_transaction.undo_transaction() do |type, entry|
      results << {
        type: type,
        entry: entry,
      }
    end
    assert_equal(2, memory_transaction.revision)

    expected = [
      {
        type: :A,
        entry: "2",
      },
      {
        type: :A,
        entry: "1",
      }
    ]
    assert_equal(expected, results)

    results = []
    memory_transaction.redo_transaction() do |type, entry|
      results << {
        type: type,
        entry: entry,
      }
    end
    assert_equal(3, memory_transaction.revision)

    expected = [
      {
        type: :a,
        entry: "1",
      },
      {
        type: :a,
        entry: "2",
      }
    ]
    assert_equal(expected, results)
  end

  def test_redo_multiple_transactions()
    memory_transaction = H2gb::Vault::Memory::MemoryTransaction.new(
      opposites: {:a => :A, :A => :a},
    )

    memory_transaction.increment()
    memory_transaction.add_to_current_transaction(type: :a, entry: "1")
    assert_equal(1, memory_transaction.revision)

    memory_transaction.increment()
    memory_transaction.add_to_current_transaction(type: :a, entry: "2")
    assert_equal(2, memory_transaction.revision)

    memory_transaction.undo_transaction() do |type, entry|
    end
    assert_equal(3, memory_transaction.revision)

    memory_transaction.undo_transaction() do |type, entry|
    end
    assert_equal(4, memory_transaction.revision)

    results = []
    memory_transaction.redo_transaction() do |type, entry|
      results << {
        type: type,
        entry: entry,
      }
    end
    assert_equal(5, memory_transaction.revision)
    expected = [
      {
        type: :a,
        entry: "1",
      },
    ]
    assert_equal(expected, results)

    results = []
    memory_transaction.redo_transaction() do |type, entry|
      results << {
        type: type,
        entry: entry,
      }
    end
    assert_equal(6, memory_transaction.revision)
    expected = [
      {
        type: :a,
        entry: "2",
      },
    ]
    assert_equal(expected, results)
  end

  def test_redo_goes_away_after_edit()
    memory_transaction = H2gb::Vault::Memory::MemoryTransaction.new(
      opposites: {:a => :A, :A => :a},
    )

    memory_transaction.increment()
    memory_transaction.add_to_current_transaction(type: :a, entry: "1")

    memory_transaction.increment()
    memory_transaction.add_to_current_transaction(type: :a, entry: "2")

    memory_transaction.undo_transaction() do |type, entry|
    end

    memory_transaction.undo_transaction() do |type, entry|
    end

    results = []
    memory_transaction.redo_transaction() do |type, entry|
      results << {
        type: type,
        entry: entry,
      }
    end
    expected = [
      {
        type: :a,
        entry: "1",
      },
    ]
    assert_equal(expected, results)

    memory_transaction.increment(kill_redo_buffer: true)
    memory_transaction.add_to_current_transaction(type: :a, entry: "3")

    memory_transaction.redo_transaction() do |type, entry|
      assert_true(false) # Should never happen
    end

    memory_transaction.redo_transaction() do |type, entry|
      assert_true(false)
    end

    results = []
    memory_transaction.undo_transaction() do |type, entry|
      results << {
        type: type,
        entry: entry,
      }
    end
    expected = [
      {
        type: :A,
        entry: "3",
      },
    ]
    assert_equal(expected, results)

    results = []
    memory_transaction.redo_transaction() do |type, entry|
      results << {
        type: type,
        entry: entry,
      }
    end
    expected = [
      {
        type: :a,
        entry: "3",
      },
    ]
    assert_equal(expected, results)

    memory_transaction.redo_transaction() do |type, entry|
      assert_true(false)
    end
  end

  def test_redo_too_much()
    # I ended up doing this on paper due to the complexity.. good luck understanding it. :)
    memory_transaction = H2gb::Vault::Memory::MemoryTransaction.new(
      opposites: {:a => :A, :A => :a},
    )

    memory_transaction.increment()
    memory_transaction.add_to_current_transaction(type: :a, entry: "1")
    assert_equal(1, memory_transaction.revision)

    memory_transaction.increment()
    memory_transaction.add_to_current_transaction(type: :a, entry: "2")
    assert_equal(2, memory_transaction.revision)

    memory_transaction.undo_transaction() do |type, entry|
    end
    assert_equal(3, memory_transaction.revision)

    memory_transaction.undo_transaction() do |type, entry|
    end
    assert_equal(4, memory_transaction.revision)

    memory_transaction.redo_transaction() do |type, entry|
    end
    assert_equal(5, memory_transaction.revision)

    results = []
    memory_transaction.redo_transaction() do |type, entry|
      results << {
        type: type,
        entry: entry,
      }
    end
    assert_equal(6, memory_transaction.revision)
    expected = [
      {
        type: :a,
        entry: "2",
      },
    ]
    assert_equal(expected, results)

    memory_transaction.redo_transaction() do |type, entry|
      assert_true(false) # Should never happen
    end
    assert_equal(6, memory_transaction.revision)

    memory_transaction.redo_transaction() do |type, entry|
      assert_true(false) # Should never happen
    end
    assert_equal(6, memory_transaction.revision)
  end

  def redo_after_undoing_over_a_non_undoable()
    memory_transaction = H2gb::Vault::Memory::MemoryTransaction.new(
      opposites: {:a => :A, :A => :a},
    )

    memory_transaction.increment()
    memory_transaction.add_to_current_transaction(type: :a, entry: "1")
    assert_equal(1, memory_transaction.revision)

    memory_transaction.increment(undoable: false)
    memory_transaction.add_to_current_transaction(type: :a, entry: "2")
    assert_equal(2, memory_transaction.revision)

    memory_transaction.increment()
    memory_transaction.add_to_current_transaction(type: :a, entry: "3")
    assert_equal(3, memory_transaction.revision)

    results = []
    memory_transaction.undo_transaction() do |type, entry|
      results << {
        type: type,
        entry: entry,
      }
    end
    expected = [{
      type: :A,
      entry: "3",
    }]
    assert_equal(expected, results)

    results = []
    memory_transaction.undo_transaction() do |type, entry|
      results << {
        type: type,
        entry: entry,
      }
    end
    expected = [{
      type: :A,
      entry: "1",
    }]
    assert_equal(expected, results)

    memory_transaction.undo_transaction() do
      assert_true(false)
    end

    results = []
    memory_transaction.redo_transaction() do |type, entry|
      results << {
        type: type,
        entry: entry,
      }
    end
    expected = [{
      type: :a,
      entry: "1",
    }]
    assert_equal(expected, results)

    results = []
    memory_transaction.redo_transaction() do |type, entry|
      results << {
        type: type,
        entry: entry,
      }
    end
    expected = [{
      type: :a,
      entry: "3",
    }]
    assert_equal(expected, results)

    memory_transaction.redo_transaction() do
      assert_true(false)
    end
  end
end
