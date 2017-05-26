# encoding: ASCII-8BIT
require 'test_helper'

require 'h2gb/vault/hex'
require 'h2gb/vault/error'
require 'h2gb/vault/types/basic_types'

BASIC_TYPES_MEMORY = "\x00\x01\x02\x03\x03\x02\x01\x00ABCDEFGH\x00ABCDEFGH".force_encoding('ASCII-8BIT')
module H2gb
  module Vault
    class BasicTypesTest < Test::Unit::TestCase
      def setup()
        @memory = Memory::Workspace.new(raw: BASIC_TYPES_MEMORY)
        @updater = Updater.new(memory: @memory)
      end

      def test_uint8_t_start()
        @updater.do([
          { action: :define_basic_type, address: 0x0000, type: :uint8_t }
        ])

        entry = @memory.get_single(address: 0x0000)
        expected = TestHelper.test_entry(address: 0x0000, type: :uint8_t, value: 0x00, length: 1, raw: "\x00".bytes())

        assert_equal(expected, entry)
      end

      def test_uint8_t_end()
        @updater.do([
          { action: :define_basic_type, address: 0x0018, type: :uint8_t }
        ])

        entry = @memory.get_single(address: 0x0018)
        expected = TestHelper.test_entry(address: 0x0018, type: :uint8_t, value: 0x48, length: 1, raw: "\x48".bytes())

        assert_equal(expected, entry)
      end

      def test_uint8_t_out_of_bounds()
        assert_raises(Error) do
          @updater.do([
            { action: :define_basic_type, address: 0x0019, type: :uint8_t }
          ])
        end
      end

      def test_uint16_t()
        @updater.do([
          { action: :define_basic_type, address: 0x0000, type: :uint16_t, options: { endian: :big} },
          { action: :define_basic_type, address: 0x0004, type: :uint16_t, options: { endian: :little} },
          { action: :define_basic_type, address: 0x0017, type: :uint16_t, options: { endian: :big} },
        ])

        entry = @memory.get_single(address: 0x0000)
        expected = TestHelper.test_entry(address: 0x0000, type: :uint16_t, value: 0x0001, length: 2, raw: "\x00\x01".bytes())
        assert_equal(expected, entry)

        entry = @memory.get_single(address: 0x0004)
        expected = TestHelper.test_entry(address: 0x0004, type: :uint16_t, value: 0x0203, length: 2, raw: "\x03\x02".bytes())
        assert_equal(expected, entry)

        entry = @memory.get_single(address: 0x0017)
        expected = TestHelper.test_entry(address: 0x0017, type: :uint16_t, value: 0x4748, length: 2, raw: "\x47\x48".bytes())
        assert_equal(expected, entry)
      end

      def test_uint16_t_out_of_bounds()
        assert_raises(Error) do
          @updater.do([
            { action: :define_basic_type, address: 0x0018, type: :uint16_t }
          ])
        end
      end

      def test_uint32_t()
        @updater.do([
          { action: :define_basic_type, address: 0x0000, type: :uint32_t, options: { endian: :big} },
          { action: :define_basic_type, address: 0x0004, type: :uint32_t, options: { endian: :little} },
          { action: :define_basic_type, address: 0x0015, type: :uint32_t, options: { endian: :big} },
        ])

        entry = @memory.get_single(address: 0x0000)
        expected = TestHelper.test_entry(address: 0x0000, type: :uint32_t, value: 0x00010203, length: 4, raw: "\x00\x01\x02\x03".bytes())
        assert_equal(expected, entry)

        entry = @memory.get_single(address: 0x0004)
        expected = TestHelper.test_entry(address: 0x0004, type: :uint32_t, value: 0x00010203, length: 4, raw: "\x03\x02\x01\x00".bytes())
        assert_equal(expected, entry)

        entry = @memory.get_single(address: 0x0015)
        expected = TestHelper.test_entry(address: 0x0015, type: :uint32_t, value: 0x45464748, length: 4, raw: "\x45\x46\x47\x48".bytes())
        assert_equal(expected, entry)
      end

      def test_uint32_t_out_of_bounds()
        assert_raises(Error) do
          @updater.do([
            { action: :define_basic_type, address: 0x0016, type: :uint32_t }
          ])
        end
      end

      def test_offset32()
        @updater.do([
          { action: :define_basic_type, address: 0x0000, type: :offset32, options: { endian: :big} },
          { action: :define_basic_type, address: 0x0004, type: :offset32, options: { endian: :little} },
          { action: :define_basic_type, address: 0x0015, type: :offset32, options: { endian: :big} },
        ])

        entry = @memory.get_single(address: 0x0000)
        expected = TestHelper.test_entry(address: 0x0000, type: :offset32, value: 0x00010203, length: 4, raw: "\x00\x01\x02\x03".bytes(), refs: { data: [0x00010203] })
        assert_equal(expected, entry)

        entry = @memory.get_single(address: 0x0004)
        expected = TestHelper.test_entry(address: 0x0004, type: :offset32, value: 0x00010203, length: 4, raw: "\x03\x02\x01\x00".bytes(), refs: { data: [0x00010203] })
        assert_equal(expected, entry)

        entry = @memory.get_single(address: 0x0015)
        expected = TestHelper.test_entry(address: 0x0015, type: :offset32, value: 0x45464748, length: 4, raw: "\x45\x46\x47\x48".bytes(), refs: { data: [0x45464748] })
        assert_equal(expected, entry)
      end

      def test_rgb()
        @updater.do([
          { action: :define_basic_type, address: 0x0000, type: :rgb, options: { endian: :big} },
          { action: :define_basic_type, address: 0x0004, type: :rgb, options: { endian: :little} },
          { action: :define_basic_type, address: 0x0015, type: :rgb, options: { endian: :big} },
        ])

        entry = @memory.get_single(address: 0x0000)
        expected = TestHelper.test_entry(address: 0x0000, type: :rgb, value: "000102", length: 3, raw: "\x00\x01\x02".bytes())
        assert_equal(expected, entry)

        entry = @memory.get_single(address: 0x0004)
        expected = TestHelper.test_entry(address: 0x0004, type: :rgb, value: "010203", length: 3, raw: "\x03\x02\x01".bytes())
        assert_equal(expected, entry)

        entry = @memory.get_single(address: 0x0015)
        expected = TestHelper.test_entry(address: 0x0015, type: :rgb, value: "454647", length: 3, raw: "\x45\x46\x47".bytes())
        assert_equal(expected, entry)
      end

      def test_ntstring()
        @updater.do([
          { action: :define_basic_type, address: 0x0000, type: :ntstring },
          { action: :define_basic_type, address: 0x0008, type: :ntstring },
        ])

        entry = @memory.get_single(address: 0x0000)
        expected = TestHelper.test_entry(address: 0x0000, type: :ntstring, value: "", length: 1, raw: "\0".bytes())
        assert_equal(expected, entry)

        entry = @memory.get_single(address: 0x0008)
        expected = TestHelper.test_entry(address: 0x0008, type: :ntstring, value: "ABCDEFGH", length: 9, raw: "ABCDEFGH\0".bytes())
        assert_equal(expected, entry)
      end

      def test_ntstring_runs_out_of_bounds()
        assert_raises(Error) do
          @updater.do([
            { action: :define_basic_type, address: 0x0011, type: :ntstring },
          ])
        end
      end
    end
  end
end
