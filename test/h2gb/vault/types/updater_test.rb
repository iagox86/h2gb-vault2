# encoding: ASCII-8BIT
require 'test_helper'

require 'h2gb/vault/types/updater'

MEMORY = "\x00\x01\x02\x03\x03\x02\x01\x00ABCDEFGH\0ABCDEFGH"

class H2gb::Vault::BasicTypesTest < Test::Unit::TestCase
  def setup()
    @memory = H2gb::Vault::Memory.new(raw: MEMORY)
    @updater = H2gb::Vault::Updater.new(memory: @memory)
  end

  def test_simple_define()
    @updater.do([
      { action: :define_basic_type, address: 0x0000, type: :uint16_t, options: { endian: :little }, user_defined: { display_hint: :hex } }
    ])

    result = @memory.get_single(address: 0x0000)
    expected = TestHelper.test_entry(address: 0x0000, type: :uint16_t, value: 0x0100, length: 2, user_defined: { display_hint: :hex }, comment: nil, raw: "\x00\x01".bytes())

    assert_equal(expected, result)
  end

  def test_multiple_define()
    @updater.do([
      { action: :define_basic_type, address: 0x00, type: :uint16_t, options: { endian: :little }, user_defined: { display_hint: :hex } },
      { action: :define_basic_type, address: 0x08, type: :uint8_t, user_defined: { display_hint: :decimal } },
    ])

    result = @memory.get_single(address: 0x0000)
    expected = TestHelper.test_entry(address: 0x0000, type: :uint16_t, value: 0x0100, length: 2, user_defined: { display_hint: :hex }, comment: nil, raw: "\x00\x01".bytes())
    assert_equal(expected, result)

    result = @memory.get_single(address: 0x0008)
    expected = TestHelper.test_entry(address: 0x0008, type: :uint8_t, value: 0x41, length: 1, user_defined: { display_hint: :decimal }, comment: nil, raw: "\x41".bytes())
    assert_equal(expected, result)
  end

  def test_define_with_comment()
  end

  def test_overlapping_define()
  end

  def test_reference()
  end

  def test_undefine()
  end

  def test_multiple_transactions()
  end

  def test_custom_type()
  end

  def test_replace_user_defined()
  end

  def test_update_user_defined()
  end

  def test_add_comment()
  end

  def test_edit_comment()
  end
end
