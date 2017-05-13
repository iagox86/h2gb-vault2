require 'test_helper'

require 'h2gb/vault/memory/memory'
require 'h2gb/vault/memory/memory_refs'

class H2gb::Vault::MemoryRefsTest < Test::Unit::TestCase
  def setup()
    @memory_refs = H2gb::Vault::Memory::MemoryRefs.new()
  end

  def test_insert()
    @memory_refs.insert(from: 0x0000, to: 0x0004)
    assert_equal([0x0004], @memory_refs.get_refs(from: 0x0000))
    assert_equal([0x0000], @memory_refs.get_xrefs(to: 0x0004))
  end

  def test_get_refs_no_refs()
    assert_equal([], @memory_refs.get_refs(from: 0x0000))
    assert_equal([], @memory_refs.get_xrefs(to: 0x0004))
  end

  def test_multiple_refs()
    # Note: These are out of order to ensure that they get sorted
    @memory_refs.insert_all(from: 0x0000, tos: [0x0002, 0x0001, 0x0003])
    assert_equal([0x0001, 0x0002, 0x0003], @memory_refs.get_refs(from: 0x0000))
    assert_equal([0x0000], @memory_refs.get_xrefs(to: 0x0001))
    assert_equal([0x0000], @memory_refs.get_xrefs(to: 0x0002))
    assert_equal([0x0000], @memory_refs.get_xrefs(to: 0x0003))
  end

  def test_multiple_xrefs()
    @memory_refs.insert(from: 0x0000, to: 0x0008)
    @memory_refs.insert(from: 0x0004, to: 0x0008)
    @memory_refs.insert(from: 0x0008, to: 0x0008)

    assert_equal([0x0008], @memory_refs.get_refs(from: 0x0000))
    assert_equal([0x0008], @memory_refs.get_refs(from: 0x0004))
    assert_equal([0x0008], @memory_refs.get_refs(from: 0x0008))
    assert_equal([0x0000, 0x0004, 0x0008], @memory_refs.get_xrefs(to: 0x0008))
  end

  def test_duplicate_refs()
    @memory_refs.insert(from: 0x0000, to: 0x0004)
    @memory_refs.insert(from: 0x0000, to: 0x0004)
    @memory_refs.insert(from: 0x0000, to: 0x0004)

    assert_equal([0x0004, 0x0004, 0x0004], @memory_refs.get_refs(from: 0x0000))
    assert_equal([0x0000, 0x0000, 0x0000], @memory_refs.get_xrefs(to: 0x0004))
  end

  def test_delete()
    @memory_refs.insert(from: 0x0000, to: 0x0004)
    @memory_refs.delete(from: 0x0000, to: 0x0004)
    assert_equal([], @memory_refs.get_refs(from: 0x0000))
    assert_equal([], @memory_refs.get_xrefs(to: 0x0004))
  end

  def test_delete_when_there_are_multiple_refs()
    @memory_refs.insert(from: 0x0000, to: 0x0004)
    @memory_refs.insert(from: 0x0000, to: 0x0008)

    @memory_refs.delete(from: 0x0000, to: 0x0004)
    assert_equal([0x0008], @memory_refs.get_refs(from: 0x0000))
    assert_equal([], @memory_refs.get_xrefs(to: 0x0004))
    assert_equal([0x0000], @memory_refs.get_xrefs(to: 0x0008))

    @memory_refs.delete(from: 0x0000, to: 0x0008)
    assert_equal([], @memory_refs.get_refs(from: 0x0000))
    assert_equal([], @memory_refs.get_xrefs(to: 0x0004))
    assert_equal([], @memory_refs.get_xrefs(to: 0x0008))
  end

  def test_delete_when_there_are_multiple_xrefs()
    @memory_refs.insert(from: 0x0000, to: 0x0004)
    @memory_refs.insert(from: 0x0004, to: 0x0004)
    @memory_refs.insert(from: 0x0008, to: 0x0004)

    assert_equal([0x0004], @memory_refs.get_refs(from: 0x0000))
    assert_equal([0x0004], @memory_refs.get_refs(from: 0x0004))
    assert_equal([0x0004], @memory_refs.get_refs(from: 0x0008))
    assert_equal([0x0000, 0x0004, 0x0008], @memory_refs.get_xrefs(to: 0x0004))

    @memory_refs.delete(from: 0x0000, to: 0x0004)
    assert_equal([], @memory_refs.get_refs(from: 0x0000))
    assert_equal([0x0004], @memory_refs.get_refs(from: 0x0004))
    assert_equal([0x0004], @memory_refs.get_refs(from: 0x0008))
    assert_equal([0x0004, 0x0008], @memory_refs.get_xrefs(to: 0x0004))

    @memory_refs.delete(from: 0x0004, to: 0x0004)
    assert_equal([], @memory_refs.get_refs(from: 0x0000))
    assert_equal([], @memory_refs.get_refs(from: 0x0004))
    assert_equal([0x0004], @memory_refs.get_refs(from: 0x0008))
    assert_equal([0x0008], @memory_refs.get_xrefs(to: 0x0004))

    @memory_refs.delete(from: 0x0008, to: 0x0004)
    assert_equal([], @memory_refs.get_refs(from: 0x0000))
    assert_equal([], @memory_refs.get_refs(from: 0x0004))
    assert_equal([], @memory_refs.get_refs(from: 0x0008))
    assert_equal([], @memory_refs.get_xrefs(to: 0x0004))
  end

  def test_delete_missing()
    assert_raises(H2gb::Vault::Memory::MemoryError) do
      @memory_refs.delete(from: 0x0000, to: 0x0000)
    end

    @memory_refs.insert(from: 0x0000, to: 0x0000)
    @memory_refs.delete(from: 0x0000, to: 0x0000)
    assert_raises(H2gb::Vault::Memory::MemoryError) do
      @memory_refs.delete(from: 0x0000, to: 0x0000)
    end
  end

  def test_delete_all()
    @memory_refs.insert(from: 0x0000, to: 0x0004)
    @memory_refs.insert(from: 0x0000, to: 0x0008)
    @memory_refs.insert(from: 0x0004, to: 0x0004)

    @memory_refs.delete_all(from: 0x0000)

    assert_equal([], @memory_refs.get_refs(from: 0x0000))
    assert_equal([], @memory_refs.get_xrefs(to: 0x0000))
    assert_equal([0x0004], @memory_refs.get_xrefs(to: 0x0004))
    assert_equal([], @memory_refs.get_xrefs(to: 0x0008))
  end
end
