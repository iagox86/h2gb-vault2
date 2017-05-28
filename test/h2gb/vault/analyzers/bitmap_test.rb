# encoding: ASCII-8BIT
require 'test_helper'

require 'h2gb/vault/analyzers/bitmap'

module H2gb
  module Vault
    class RealBmpTest < Test::Unit::TestCase
      def test_parsing()
        test_file = File.dirname(__FILE__) + '/data/test.bmp'
        File.open(test_file, 'rb') do |f|
          @memory = Workspace.new(raw: f.read())
        end
        @analyzer = BitmapAnalyzer.new(@memory)
        @analyzer.analyze()

        header = @memory[0x0000]
        expected = TestHelper.test_entry(address: 0x0000, type: :uint16_t, value: 0x424d, length: 2, user_defined: { display_hint: :string }, comment: "BMP header", raw: "BM".bytes())
        assert_equal(expected, header)

        length = @memory[0x0002]
        expected = TestHelper.test_entry(address: 0x0002, type: :uint32_t, value: 0x000000aa, length: 4, user_defined: {}, comment: "File size", raw: "\xaa\x00\x00\x00".bytes())
        assert_equal(expected, length)

        reserved1 = @memory[0x0006]
        expected = TestHelper.test_entry(address: 0x0006, type: :uint16_t, value: 0x0000, length: 2, user_defined: {}, comment: "Reserved (1)", raw: "\x00\x00".bytes())
        assert_equal(expected, reserved1)

        reserved2 = @memory[0x0008]
        expected = TestHelper.test_entry(address: 0x0008, type: :uint16_t, value: 0x0000, length: 2, user_defined: {}, comment: "Reserved (2)", raw: "\x00\x00".bytes())
        assert_equal(expected, reserved2)

    #    offset_entry = @memory.get(address: 0x0a)
        offset = @memory[0x000a]
        expected = TestHelper.test_entry(address: 0x000a, type: :offset32, value: 0x0000007a, length: 4, user_defined: {}, comment: "Offset to pixel data", raw: "\x7a\x00\x00\x00".bytes(), refs: { data: [0x0000007a] })
        assert_equal(expected, offset)

        dib_length = @memory[0x000e]
        expected = TestHelper.test_entry(address: 0x000e, type: :uint32_t, value: 0x0000006c, length: 4, user_defined: {}, comment: "DIB structure length (BITMAPV4HEADER)", raw: "\x6c\x00\x00\x00".bytes())
        assert_equal(expected, dib_length)

        width = @memory[0x0012]
        expected = TestHelper.test_entry(address: 0x0012, type: :uint32_t, value: 0x00000004, length: 4, user_defined: {}, comment: "Image width", raw: "\x04\x00\x00\x00".bytes())
        assert_equal(expected, width)

        height = @memory[0x0016]
        expected = TestHelper.test_entry(address: 0x0016, type: :uint32_t, value: 0x00000004, length: 4, user_defined: {}, comment: "Image height", raw: "\x04\x00\x00\x00".bytes())
        assert_equal(expected, height)

        pixels = @memory.get(address: 0x7a, length: 0x30)[:entries]

        expected = [
          # Row 4
          TestHelper.test_entry({ address: 0x7a, type: :rgb, value: "ffffff", length: 3, raw: [0xFF, 0xFF, 0xFF], xrefs: { data: [0x0a]} }),
          TestHelper.test_entry({ address: 0x7d, type: :rgb, value: "000000", length: 3, raw: [0x00, 0x00, 0x00] }),
          TestHelper.test_entry({ address: 0x80, type: :rgb, value: "0000ff", length: 3, raw: [0xFF, 0x00, 0x00] }),
          TestHelper.test_entry({ address: 0x83, type: :rgb, value: "ffffff", length: 3, raw: [0xFF, 0xFF, 0xFF] }),

          # Row 3
          TestHelper.test_entry({ address: 0x86, type: :rgb, value: "000000", length: 3, raw: [0x00, 0x00, 0x00] }),
          TestHelper.test_entry({ address: 0x89, type: :rgb, value: "00ff00", length: 3, raw: [0x00, 0xFF, 0x00] }),
          TestHelper.test_entry({ address: 0x8c, type: :rgb, value: "ffffff", length: 3, raw: [0xFF, 0xFF, 0xFF] }),
          TestHelper.test_entry({ address: 0x8f, type: :rgb, value: "ff0000", length: 3, raw: [0x00, 0x00, 0xFF] }),

          # Row 2
          TestHelper.test_entry({ address: 0x92, type: :rgb, value: "ff0000", length: 3, raw: [0x00, 0x00, 0xFF] }),
          TestHelper.test_entry({ address: 0x95, type: :rgb, value: "ffffff", length: 3, raw: [0xFF, 0xFF, 0xFF] }),
          TestHelper.test_entry({ address: 0x98, type: :rgb, value: "00ff00", length: 3, raw: [0x00, 0xFF, 0x00] }),
          TestHelper.test_entry({ address: 0x9b, type: :rgb, value: "000000", length: 3, raw: [0x00, 0x00, 0x00] }),

          # Row 1
          TestHelper.test_entry({ address: 0x9e, type: :rgb, value: "ffffff", length: 3, raw: [0xFF, 0xFF, 0xFF] }),
          TestHelper.test_entry({ address: 0xa1, type: :rgb, value: "0000ff", length: 3, raw: [0xFF, 0x00, 0x00] }),
          TestHelper.test_entry({ address: 0xa4, type: :rgb, value: "000000", length: 3, raw: [0x00, 0x00, 0x00] }),
          TestHelper.test_entry({ address: 0xa7, type: :rgb, value: "ffffff", length: 3, raw: [0xFF, 0xFF, 0xFF] }),
        ]

        assert_equal(expected, pixels)
      end
    end
  end
end
