require 'test_helper'

require 'h2gb/vault/memory/memory'
require 'h2gb/vault/memory/memory_refs'

class H2gb::Vault::MemoryRefsTest < Test::Unit::TestCase
  def setup()
    @memory_refs = H2gb::Vault::Memory::MemoryRefs.new()
  end

  def test_insert()
    updates = @memory_refs.insert(address: 0x0000, refs: [0x0004])
    assert_equal([0x0004], updates)

    refs = @memory_refs.get_refs(address: 0x0000)
    assert_equal([0x0004], refs)

    xrefs = @memory_refs.get_xrefs(address: 0x0004)
    assert_equal([0x0000], xrefs)
  end

  def test_insert_bad_duplicate()
    @memory_refs.insert(address: 0x0000, refs: [0x0004])

    assert_raises(H2gb::Vault::Memory::MemoryError) do
      @memory_refs.insert(address: 0x0000, refs: [0x0008])
    end
  end

  def get_refs_no_refs()
    @memory_refs.insert(address: 0x0000, refs: [])

    refs = @memory_refs.get_refs(address: 0x0000)
    assert_equal([], refs)
  end

  def get_refs_from_not_defined_address()
    refs = @memory_refs.get_refs(address: 0x0000)
    assert_equal([], refs)
  end

  def test_multiple_refs()
    # Note: These are out of order to ensure that they get sorted
    updates = @memory_refs.insert(address: 0x0000, refs: [0x0002, 0x0001, 0x0003])
    assert_equal([0x0001, 0x0002, 0x0003], updates)

    refs = @memory_refs.get_refs(address: 0x0000)
    assert_equal([0x0001, 0x0002, 0x0003], refs)

    xrefs = @memory_refs.get_xrefs(address: 0x0001)
    assert_equal([0x0000], xrefs)
    xrefs = @memory_refs.get_xrefs(address: 0x0002)
    assert_equal([0x0000], xrefs)
    xrefs = @memory_refs.get_xrefs(address: 0x0003)
    assert_equal([0x0000], xrefs)
  end

  def test_multiple_xrefs()
    # Note: Defining these backwards to ensure the order is sorted
    @memory_refs.insert(address: 0x0008, refs: [0x0004])
    @memory_refs.insert(address: 0x0000, refs: [0x0004])

    refs = @memory_refs.get_refs(address: 0x0000)
    assert_equal([0x0004], refs)

    refs = @memory_refs.get_refs(address: 0x0008)
    assert_equal([0x0004], refs)

    xrefs = @memory_refs.get_xrefs(address: 0x0004)
    assert_equal([0x0000, 0x0008], xrefs)
  end

  def get_xrefs_when_there_are_none()
    xrefs = @memory_refs.get_xrefs(address: 0x0004)
    assert_equal([], xrefs)
  end

  def test_duplicate_refs()
    @memory_refs.insert(address: 0x0000, refs: [0x0004, 0x0004])

    refs = @memory_refs.get_refs(address: 0x0000)
    assert_equal([0x0004], refs)

    xrefs = @memory_refs.get_xrefs(address: 0x0004)
    assert_equal([0x0000], xrefs)
  end

  def test_self_reference()
    @memory_refs.insert(address: 0x0000, refs: [0x0000])

    refs = @memory_refs.get_refs(address: 0x0000)
    assert_equal([0x0000], refs)

    xrefs = @memory_refs.get_xrefs(address: 0x0000)
    assert_equal([0x0000], xrefs)
  end

  def test_input_validation()
    assert_raises(H2gb::Vault::Memory::MemoryError) do
      @memory_refs.insert(address: 'hi', refs: [0x0004])
    end
    assert_raises(H2gb::Vault::Memory::MemoryError) do
      @memory_refs.insert(address: -1, refs: [0x0004])
    end

    assert_raises(H2gb::Vault::Memory::MemoryError) do
      @memory_refs.insert(address: 0x0000, refs: 0x0004)
    end
    assert_raises(H2gb::Vault::Memory::MemoryError) do
      @memory_refs.insert(address: 0x0000, refs: ['hi'])
    end
    assert_raises(H2gb::Vault::Memory::MemoryError) do
      @memory_refs.insert(address: 0x0000, refs: [])
    end
  end

  def test_delete()
    @memory_refs.insert(address: 0x0000, refs: [0x0004])
    updates = @memory_refs.delete(address: 0x0000)
    assert_equal([0x0004], updates)

    refs = @memory_refs.get_refs(address: 0x0000)
    assert_equal([], refs)

    xrefs = @memory_refs.get_xrefs(address: 0x0004)
    assert_equal([], xrefs)
  end

  def test_delete_when_there_are_multiple_refs()
    @memory_refs.insert(address: 0x0000, refs: [0x0004, 0x0005])
    updates = @memory_refs.delete(address: 0x0000)
    assert_equal([0x0004, 0x0005], updates)

    refs = @memory_refs.get_refs(address: 0x0000)
    assert_equal([], refs)

    xrefs = @memory_refs.get_xrefs(address: 0x0004)
    assert_equal([], xrefs)
    xrefs = @memory_refs.get_xrefs(address: 0x0005)
    assert_equal([], xrefs)
  end

  def test_delete_when_there_are_multiple_xrefs()
    @memory_refs.insert(address: 0x0000, refs: [0x0004])
    @memory_refs.insert(address: 0x0001, refs: [0x0004])
    @memory_refs.insert(address: 0x0002, refs: [0x0004])

    xrefs = @memory_refs.get_xrefs(address: 0x0004)
    assert_equal([0x0000, 0x0001, 0x0002], xrefs)

    @memory_refs.delete(address: 0x0000)

    xrefs = @memory_refs.get_xrefs(address: 0x0004)
    assert_equal([0x0001, 0x0002], xrefs)

    @memory_refs.delete(address: 0x0001)

    xrefs = @memory_refs.get_xrefs(address: 0x0004)
    assert_equal([0x0002], xrefs)

    @memory_refs.delete(address: 0x0002)

    xrefs = @memory_refs.get_xrefs(address: 0x0004)
    assert_equal([], xrefs)
  end

  def test_delete_missing()
    @memory_refs.delete(address: 0x0000)
  end
end
