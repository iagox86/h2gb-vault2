# encoding: ASCII-8BIT
require 'test_helper'

require 'h2gb/vault/types/updater'

#MEMORY = "\x00\x01\x02\x03\x03\x02\x01\x00\x00\x00\x04ABCDEFGH\0ABCDEFGH"
#
#class H2gb::Vault::BasicTypesTest < Test::Unit::TestCase
#  def setup()
#    @memory = H2gb::Vault::Memory.new(raw: MEMORY)
#    @updater = H2gb::Vault::Updater.new(memory: @memory)
#  end
#
#  def test_simple_define()
#    @updater.do([
#      { action: :define_basic_type, address: 0x0000, type: :uint16_t, options: { endian: :little }, user_defined: { display_hint: :hex } }
#    ])
#
#    result = @memory.get_single(address: 0x0000)
#    expected = TestHelper.test_entry(address: 0x0000, type: :uint16_t, value: 0x0100, length: 2, user_defined: { display_hint: :hex }, comment: nil, raw: "\x00\x01".bytes())
#    assert_equal(expected, result)
#  end
#
#  def test_multiple_define()
#    @updater.do([
#      { action: :define_basic_type, address: 0x00, type: :uint16_t, options: { endian: :little }, user_defined: { display_hint: :hex } },
#      { action: :define_basic_type, address: 0x08, type: :uint8_t, user_defined: { display_hint: :decimal } },
#    ])
#
#    result = @memory.get_single(address: 0x0000)
#    expected = TestHelper.test_entry(address: 0x0000, type: :uint16_t, value: 0x0100, length: 2, user_defined: { display_hint: :hex }, comment: nil, raw: "\x00\x01".bytes())
#    assert_equal(expected, result)
#
#    result = @memory.get_single(address: 0x0008)
#    expected = TestHelper.test_entry(address: 0x0008, type: :uint8_t, value: 0x00, length: 1, user_defined: { display_hint: :decimal }, comment: nil, raw: "\x00".bytes())
#    assert_equal(expected, result)
#  end
#
#  def test_define_with_comment()
#    @updater.do([
#      { action: :define_basic_type, address: 0x00, type: :uint16_t, options: { endian: :little }, user_defined: { display_hint: :hex } },
#      { action: :define_basic_type, address: 0x08, type: :uint8_t, user_defined: { display_hint: :decimal }, comment: 'hihi' },
#    ])
#
#    result = @memory.get_single(address: 0x0000)
#    expected = TestHelper.test_entry(address: 0x0000, type: :uint16_t, value: 0x0100, length: 2, user_defined: { display_hint: :hex }, comment: nil, raw: "\x00\x01".bytes())
#    assert_equal(expected, result)
#
#    result = @memory.get_single(address: 0x0008)
#    expected = TestHelper.test_entry(address: 0x0008, type: :uint8_t, value: 0x00, length: 1, user_defined: { display_hint: :decimal }, comment: 'hihi', raw: "\x00".bytes())
#    assert_equal(expected, result)
#  end
#
#  def test_add_comment()
#    @updater.do([
#      { action: :define_basic_type, address: 0x00, type: :uint16_t, options: { endian: :little }, user_defined: { display_hint: :hex } },
#      { action: :define_basic_type, address: 0x08, type: :uint8_t, user_defined: { display_hint: :decimal } },
#      { action: :set_comment, address: 0x08, comment: 'hihi' }
#    ])
#
#    result = @memory.get_single(address: 0x0008)
#    expected = TestHelper.test_entry(address: 0x0008, type: :uint8_t, value: 0x00, length: 1, user_defined: { display_hint: :decimal }, comment: 'hihi', raw: "\x00".bytes())
#    assert_equal(expected, result)
#  end
#
#  def test_edit_comment()
#    @updater.do([
#      { action: :define_basic_type, address: 0x00, type: :uint16_t, options: { endian: :little }, user_defined: { display_hint: :hex } },
#      { action: :define_basic_type, address: 0x08, type: :uint8_t, user_defined: { display_hint: :decimal }, comment: 'blahblah' },
#      { action: :set_comment, address: 0x08, comment: 'hihi' }
#    ])
#
#    result = @memory.get_single(address: 0x0008)
#    expected = TestHelper.test_entry(address: 0x0008, type: :uint8_t, value: 0x00, length: 1, user_defined: { display_hint: :decimal }, comment: 'hihi', raw: "\x00".bytes())
#    assert_equal(expected, result)
#  end
#
#  def test_overlapping_define()
#    @updater.do([
#      { action: :define_basic_type, address: 0x00, type: :uint16_t, options: { endian: :little }, user_defined: { display_hint: :hex } },
#      { action: :define_basic_type, address: 0x01, type: :uint8_t, user_defined: { display_hint: :decimal } },
#    ])
#
#    result = @memory.get_single(address: 0x0000)
#    expected = TestHelper.test_entry_deleted(address: 0x0000, raw: "\x00".bytes())
#    assert_equal(expected, result)
#
#    result = @memory.get_single(address: 0x0001)
#    expected = TestHelper.test_entry(address: 0x0001, type: :uint8_t, value: 0x01, length: 1, user_defined: { display_hint: :decimal }, raw: "\x01".bytes(), comment: nil)
#    assert_equal(expected, result)
#  end
#
#  def test_define_offset()
#    @updater.do([
#      { action: :define_basic_type, address: 0x07, type: :offset32, options: { endian: :big }, user_defined: { display_hint: :hex } },
#    ])
#
#    result = @memory.get_single(address: 0x0007)
#    expected = TestHelper.test_entry(address: 0x0007, type: :offset32, value: 0x00000004, length: 4, user_defined: { display_hint: :hex }, comment: nil, raw: "\x00\x00\x00\x04".bytes(), refs: {data: [0x00000004]})
#    assert_equal(expected, result)
#
#    result = @memory.get_single(address: 0x0004)
#    expected = TestHelper.test_entry_deleted(address: 0x0004, raw: "\x03".bytes(), xrefs: { data: [0x00000007] })
#    assert_equal(expected, result)
#  end
#
#  def test_add_reference()
#    @updater.do([
#      { action: :define_basic_type, address: 0x00, type: :uint16_t, options: { endian: :big }},
#      { action: :add_reference, address: 0x00, type: :code, to: 0x06, options: {} }
#    ])
#
#    result = @memory.get_single(address: 0x0000)
#    expected = TestHelper.test_entry(address: 0x0000, type: :uint16_t, value: 0x0100, length: 2, user_defined: { display_hint: :hex }, comment: nil, raw: "\x00\x01".bytes(), refs: { code: [0x0006] })
#    assert_equal(expected, result)
#
#    result = @memory.get_single(address: 0x0006)
#    expected = TestHelper.test_entry_deleted(address: 0x0006, raw: "\x01".bytes(), xrefs: { code: [0x00000000] })
#    assert_equal(expected, result)
#  end
#
#  def test_remove_reference()
#  end
#
#  def test_undefine()
#  end
#
#  def test_multiple_transactions()
#  end
#
#  def test_custom_type()
#  end
#
#  def test_replace_user_defined()
#  end
#
#  def test_update_user_defined()
#  end
#
#  def test_undo()
#  end
#end
