# encoding: ASCII-8BIT
require 'test_helper'

require 'h2gb/vault/types/updater'

UPDATER_MEMORY = "\x00\x01\x02\x03\x03\x02\x01\x00\x00\x00\x04ABCDEFGH\0ABCDEFGH"

module H2gb
  module Vault
    class UpdaterTest < Test::Unit::TestCase
      def setup()
        @workspace = Workspace.new()
        @workspace.transaction() do
          @workspace.create_block(block_name: 'test', raw: UPDATER_MEMORY, base_address: 0x0000)
        end
        @updater = Updater.new(workspace: @workspace)
      end

      def test_simple_define()
        @updater.do([
          { block_name: 'test', action: :define_basic_type, address: 0x0000, type: :uint16_t, options: { endian: :little }, user_defined: { display_hint: :hex } }
        ])

        result = @workspace.get_single(block_name: 'test', address: 0x0000)
        expected = TestHelper.test_entry(address: 0x0000, type: :uint16_t, value: 0x0100, length: 2, user_defined: { display_hint: :hex }, comment: nil, raw: "\x00\x01".bytes())
        assert_equal(expected, result)
      end

      def test_multiple_define()
        @updater.do([
          { block_name: 'test', action: :define_basic_type, address: 0x00, type: :uint16_t, options: { endian: :little }, user_defined: { display_hint: :hex } },
          { block_name: 'test', action: :define_basic_type, address: 0x08, type: :uint8_t, user_defined: { display_hint: :decimal } },
        ])

        result = @workspace.get_single(block_name: 'test', address: 0x0000)
        expected = TestHelper.test_entry(address: 0x0000, type: :uint16_t, value: 0x0100, length: 2, user_defined: { display_hint: :hex }, comment: nil, raw: "\x00\x01".bytes())
        assert_equal(expected, result)

        result = @workspace.get_single(block_name: 'test', address: 0x0008)
        expected = TestHelper.test_entry(address: 0x0008, type: :uint8_t, value: 0x00, length: 1, user_defined: { display_hint: :decimal }, comment: nil, raw: "\x00".bytes())
        assert_equal(expected, result)
      end

      def test_define_with_comment()
        @updater.do([
          { block_name: 'test', action: :define_basic_type, address: 0x00, type: :uint16_t, options: { endian: :little }, user_defined: { display_hint: :hex } },
          { block_name: 'test', action: :define_basic_type, address: 0x08, type: :uint8_t, user_defined: { display_hint: :decimal }, comment: 'hihi' },
        ])

        result = @workspace.get_single(block_name: 'test', address: 0x0000)
        expected = TestHelper.test_entry(address: 0x0000, type: :uint16_t, value: 0x0100, length: 2, user_defined: { display_hint: :hex }, comment: nil, raw: "\x00\x01".bytes())
        assert_equal(expected, result)

        result = @workspace.get_single(block_name: 'test', address: 0x0008)
        expected = TestHelper.test_entry(address: 0x0008, type: :uint8_t, value: 0x00, length: 1, user_defined: { display_hint: :decimal }, comment: 'hihi', raw: "\x00".bytes())
        assert_equal(expected, result)
      end

      def test_add_comment()
        @updater.do([
          { block_name: 'test', action: :define_basic_type, address: 0x00, type: :uint16_t, options: { endian: :little }, user_defined: { display_hint: :hex } },
          { block_name: 'test', action: :define_basic_type, address: 0x08, type: :uint8_t, user_defined: { display_hint: :decimal } },
          { block_name: 'test', action: :set_comment, address: 0x08, comment: 'hihi' }
        ])

        result = @workspace.get_single(block_name: 'test', address: 0x0008)
        expected = TestHelper.test_entry(address: 0x0008, type: :uint8_t, value: 0x00, length: 1, user_defined: { display_hint: :decimal }, comment: 'hihi', raw: "\x00".bytes())
        assert_equal(expected, result)
      end

      def test_edit_comment()
        @updater.do([
          { block_name: 'test', action: :define_basic_type, address: 0x00, type: :uint16_t, options: { endian: :little }, user_defined: { display_hint: :hex } },
          { block_name: 'test', action: :define_basic_type, address: 0x08, type: :uint8_t, user_defined: { display_hint: :decimal }, comment: 'blahblah' },
          { block_name: 'test', action: :set_comment, address: 0x08, comment: 'hihi' }
        ])

        result = @workspace.get_single(block_name: 'test', address: 0x0008)
        expected = TestHelper.test_entry(address: 0x0008, type: :uint8_t, value: 0x00, length: 1, user_defined: { display_hint: :decimal }, comment: 'hihi', raw: "\x00".bytes())
        assert_equal(expected, result)
      end

      def test_overlapping_define()
        @updater.do([
          { block_name: 'test', action: :define_basic_type, address: 0x00, type: :uint16_t, options: { endian: :little }, user_defined: { display_hint: :hex } },
          { block_name: 'test', action: :define_basic_type, address: 0x01, type: :uint8_t, user_defined: { display_hint: :decimal } },
        ])

        result = @workspace.get_single(block_name: 'test', address: 0x0000)
        expected = TestHelper.test_entry_deleted(address: 0x0000, raw: "\x00".bytes())
        assert_equal(expected, result)

        result = @workspace.get_single(block_name: 'test', address: 0x0001)
        expected = TestHelper.test_entry(address: 0x0001, type: :uint8_t, value: 0x01, length: 1, user_defined: { display_hint: :decimal }, raw: "\x01".bytes(), comment: nil)
        assert_equal(expected, result)
      end

      def test_define_basic_type()
        @updater.do([
          { block_name: 'test', action: :define_basic_type, address: 0x07, type: :offset32, options: { endian: :big }, user_defined: { display_hint: :hex } },
        ])

        result = @workspace.get_single(block_name: 'test', address: 0x0007)
        expected = TestHelper.test_entry(address: 0x0007, type: :offset32, value: 0x00000004, length: 4, user_defined: { display_hint: :hex }, comment: nil, raw: "\x00\x00\x00\x04".bytes(), refs: {data: [0x00000004]})
        assert_equal(expected, result)

        result = @workspace.get_single(block_name: 'test', address: 0x0004)
        expected = TestHelper.test_entry_deleted(address: 0x0004, raw: "\x03".bytes(), xrefs: { data: [0x00000007] })
        assert_equal(expected, result)
      end

      def test_add_reference()
        @updater.do([
          { block_name: 'test', action: :define_basic_type, address: 0x00, type: :uint16_t, options: { endian: :big }},
          { block_name: 'test', action: :add_refs, address: 0x00, type: :code, tos: [0x06], options: {} }
        ])

        result = @workspace.get_single(block_name: 'test', address: 0x0000)
        expected = TestHelper.test_entry(address: 0x0000, type: :uint16_t, value: 0x0001, length: 2, user_defined: { }, comment: nil, raw: "\x00\x01".bytes(), refs: { code: [0x0006] })
        assert_equal(expected, result)

        result = @workspace.get_single(block_name: 'test', address: 0x0006)
        expected = TestHelper.test_entry_deleted(address: 0x0006, raw: "\x01".bytes(), xrefs: { code: [0x00000000] })
        assert_equal(expected, result)
      end

      def test_remove_reference()
        @updater.do([
          { block_name: 'test', action: :define_basic_type, address: 0x00, type: :uint16_t, options: { endian: :big }},
          { block_name: 'test', action: :add_refs, address: 0x00, type: :code, tos: [0x06], options: {} }
        ])
        @updater.do([
          { block_name: 'test', action: :remove_refs, address: 0x00, type: :code, tos: [0x06], options: {} }
        ])

        result = @workspace.get_single(block_name: 'test', address: 0x0000)
        expected = TestHelper.test_entry(address: 0x0000, type: :uint16_t, value: 0x0001, length: 2, user_defined: {}, comment: nil, raw: "\x00\x01".bytes(), refs: {})
        assert_equal(expected, result)

        result = @workspace.get_single(block_name: 'test', address: 0x0006)
        expected = TestHelper.test_entry_deleted(address: 0x0006, raw: "\x01".bytes(), xrefs: {})
        assert_equal(expected, result)
      end

      def test_undefine()
        @updater.do([
          { block_name: 'test', action: :define_basic_type, address: 0x0000, type: :uint16_t, options: { endian: :little }, user_defined: { display_hint: :hex }},
          { block_name: 'test', action: :define_basic_type, address: 0x0002, type: :uint16_t, options: { endian: :little }, user_defined: { display_hint: :hex }},
        ])

        @updater.do([
          { block_name: 'test', action: :undefine, address: 0x0000, length: 0x0010, type: :uint16_t, options: { endian: :little }, user_defined: { display_hint: :hex } }
        ])

        result = @workspace.get_single(block_name: 'test', address: 0x0000)
        expected = TestHelper.test_entry_deleted(address: 0x0000, raw: "\x00".bytes())
        assert_equal(expected, result)
      end

      def test_custom_type()
        @updater.do([
          { block_name: 'test', action: :define_custom_type, address: 0x0000, type: :custom_type, length: 4, value: "hi", options: { a: :b } }
        ])

        result = @workspace.get_single(block_name: 'test', address: 0x0000)
        expected = TestHelper.test_entry(address: 0x0000, type: :custom_type, value: "hi", length: 4, user_defined: {}, comment: nil, raw: "\x00\x01\x02\x03".bytes())
        assert_equal(expected, result)

        @updater.do([
          { block_name: 'test', action: :define_custom_type, address: 0x0004, type: :custom_type, length: 4, value: "hi", options: { a: :b }, refs: { code: [0x0000] }}
        ])

        result = @workspace.get_single(block_name: 'test', address: 0x0000)
        expected = TestHelper.test_entry(address: 0x0000, type: :custom_type, value: "hi", length: 4, user_defined: {}, comment: nil, raw: "\x00\x01\x02\x03".bytes(), xrefs: { code: [0x0004] })
        assert_equal(expected, result)

        result = @workspace.get_single(block_name: 'test', address: 0x0004)
        expected = TestHelper.test_entry(address: 0x0004, type: :custom_type, value: "hi", length: 4, user_defined: {}, comment: nil, raw: "\x03\x02\x01\x00".bytes(), refs: { code: [0x0000] })
        assert_equal(expected, result)
      end

      def test_replace_user_defined()
        @updater.do([
          { block_name: 'test', action: :define_basic_type, address: 0x0000, type: :uint16_t, options: { endian: :little }, user_defined: { display_hint: :hex } }
        ])
        @updater.do([
          { block_name: 'test', action: :replace_user_defined, address: 0x0000, user_defined: { display_sign: :signed } }
        ])

        result = @workspace.get_single(block_name: 'test', address: 0x0000)
        expected = TestHelper.test_entry(address: 0x0000, type: :uint16_t, value: 0x0100, length: 2, user_defined: { display_sign: :signed }, comment: nil, raw: "\x00\x01".bytes())
        assert_equal(expected, result)
      end

      def test_update_user_defined()
        @updater.do([
          { block_name: 'test', action: :define_basic_type, address: 0x0000, type: :uint16_t, options: { endian: :little }, user_defined: { display_hint: :hex } }
        ])
        @updater.do([
          { block_name: 'test', action: :update_user_defined, address: 0x0000, user_defined: { display_sign: :signed } }
        ])

        result = @workspace.get_single(block_name: 'test', address: 0x0000)
        expected = TestHelper.test_entry(address: 0x0000, type: :uint16_t, value: 0x0100, length: 2, user_defined: { display_hint: :hex, display_sign: :signed }, comment: nil, raw: "\x00\x01".bytes())
        assert_equal(expected, result)

        @updater.do([
          { block_name: 'test', action: :update_user_defined, address: 0x0000, user_defined: { display_hint: :decimal } }
        ])

        result = @workspace.get_single(block_name: 'test', address: 0x0000)
        expected = TestHelper.test_entry(address: 0x0000, type: :uint16_t, value: 0x0100, length: 2, user_defined: { display_hint: :decimal, display_sign: :signed }, comment: nil, raw: "\x00\x01".bytes())
        assert_equal(expected, result)
      end
    end
  end
end
