# encoding: ASCII-8BIT
require 'test_helper'

require 'h2gb/vault/types/basic_types'

MEMORY = "\x00\x01\x02\x03\x03\x02\x01\x00ABCDEFGH\0ABCDEFGH"

class H2gb::Vault::BasicTypesTest < Test::Unit::TestCase
  def setup()
    @memory = H2gb::Vault::Memory.new(raw: MEMORY)
    @basic_types = H2gb::Vault::BasicTypes.new(memory: @memory)
  end

  def test_uint8_t_start()
    @basic_types.uint8_t(offset: 0)
    result = @memory.get(address: 0)
    expected = {
      revision: 1,
      entries: [
        { address: 0, length: 1, raw: [0x00], refs: [], xrefs: [], data: { type: :uint8_t, value: 0 } },
      ]
    }

    assert_equal(expected, result)
  end

  def test_uint8_t_end()
    @basic_types.uint8_t(offset: 0x18)
    result = @memory.get(address: 0x18)[:entries][0]
    expected = { address: 0x18, length: 1, raw: [0x48], refs: [], xrefs: [], data: { type: :uint8_t, value: 0x48 } }

    assert_equal(expected, result)
  end

  def test_uint8_t_out_of_bounds()
    assert_raises(H2gb::Vault::Memory::MemoryError) do
      @basic_types.uint8_t(offset: 0x19)
    end
  end

  def test_uint16_t_big_endian()
    @basic_types.uint16_t(offset: 0x00, endian: H2gb::Vault::BasicTypes::BIG_ENDIAN)
    result = @memory.get(address: 0x00)[:entries][0]
    expected = { address: 0x00, length: 2, raw: [0x00, 0x01], refs: [], xrefs: [], data: { type: :uint16_t, value: 0x0001, endian: :big_endian } }

    assert_equal(expected, result)
  end

  def test_uint16_t_little_endian()
    @basic_types.uint16_t(offset: 0x00, endian: H2gb::Vault::BasicTypes::LITTLE_ENDIAN)
    result = @memory.get(address: 0x00)[:entries][0]
    expected = { address: 0x00, length: 2, raw: [0x00, 0x01], refs: [], xrefs: [], data: { type: :uint16_t, value: 0x0100, endian: :little_endian } }

    assert_equal(expected, result)
  end

  def test_uint16_t_end()
    @basic_types.uint16_t(offset: 0x17, endian: H2gb::Vault::BasicTypes::BIG_ENDIAN)
    result = @memory.get(address: 0x17)[:entries][0]
    expected = { address: 0x17, length: 2, raw: [0x47, 0x48], refs: [], xrefs: [], data: { type: :uint16_t, value: 0x4748, endian: :big_endian } }

    assert_equal(expected, result)
  end

  def test_uint16_t_out_of_bounds()
    assert_raises(H2gb::Vault::Memory::MemoryError) do
      @basic_types.uint16_t(offset: 0x18, endian: H2gb::Vault::BasicTypes::BIG_ENDIAN)
    end
  end
end

