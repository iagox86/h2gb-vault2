# encoding: ASCII-8BIT
require 'test_helper'

require 'h2gb/vault/analyzers/bitmap'

class H2gb::Vault::RealBmpTest < Test::Unit::TestCase
  def setup()
    test_file = File.dirname(__FILE__) + '/data/test.bmp'
    File.open(test_file, 'rb') do |f|
      @memory = H2gb::Vault::Memory.new(raw: f.read())
    end
    @analyzer = H2gb::Vault::BitmapAnalyzer.new(@memory)
    @analyzer.analyze()
  end

  def test_parsing()
    header_entry = @memory.get(address: 0x00)
    expected = {
      revision: 0x01,
      entries: [{
        address: 0x00,
        data: {
          comment: "Bitmap header",
          type: :uint16_t,
          value: 0x424d
        },
        length: 0x02,
        refs: [],
        raw: [?B.ord, ?M.ord],
        xrefs: []
      }],
    }
    assert_equal(expected, header_entry)

    length_entry = @memory.get(address: 0x02)
    expected = {
      revision: 0x01,
      entries: [{
        address: 0x02,
        data: {
          comment: "File size (valid)",
          type: :uint32_t,
          value: 0xaa
        },
        length: 0x04,
        refs: [],
        raw: [0xaa, 0x00, 0x00, 0x00],
        xrefs: []
      }],
    }
    assert_equal(expected, length_entry)

    reserved1_entry = @memory.get(address: 0x06)
    expected = {
      revision: 0x01,
      entries: [{
        address: 0x06,
        data: {
          comment: "Reserved",
          type: :uint16_t,
          value: 0x00
        },
        length: 2,
        refs: [],
        raw: [0x00, 0x00],
        xrefs: []
      }],
    }
    assert_equal(expected, reserved1_entry)

    reserved2_entry = @memory.get(address: 0x08)
    expected = {
      revision: 0x01,
      entries: [{
        address: 0x08,
        data: {
          comment: "Reserved",
          type: :uint16_t,
          value: 0x00
        },
        length: 2,
        refs: [],
        raw: [0x00, 0x00],
        xrefs: []
      }],
    }
    assert_equal(expected, reserved2_entry)

    offset_entry = @memory.get(address: 0x0a)
    expected = {
      revision: 0x01,
      entries: [{
        address: 0x0a,
        data: {
          comment: "Offset to pixel data",
          type: :offset,
          value: 0x7a
        },
        length: 4,
        refs: [0x7a],
        raw: [0x7a, 0x00, 0x00, 0x00],
        xrefs: []
      }],
    }
    assert_equal(expected, offset_entry)

    pixels = @memory.get(address: 0x7a, length: 0x30)
    expected = {
      revision: 1,
      entries: [
        # Row 4
        { address: 0x7a, data: { type: :bgr, value: "\xFF\xFF\xFF", }, length: 3, refs: [], raw: [0xFF, 0xFF, 0xFF], xrefs: [0x0a]},
        { address: 0x7d, data: { type: :bgr, value: "\x00\x00\x00", }, length: 3, refs: [], raw: [0x00, 0x00, 0x00], xrefs: []},
        { address: 0x80, data: { type: :bgr, value: "\xFF\x00\x00", }, length: 3, refs: [], raw: [0xFF, 0x00, 0x00], xrefs: []},
        { address: 0x83, data: { type: :bgr, value: "\xFF\xFF\xFF", }, length: 3, refs: [], raw: [0xFF, 0xFF, 0xFF], xrefs: []},

        # Row 3
        { address: 0x86, data: { type: :bgr, value: "\x00\x00\x00", }, length: 3, refs: [], raw: [0x00, 0x00, 0x00], xrefs: []},
        { address: 0x89, data: { type: :bgr, value: "\x00\xFF\x00", }, length: 3, refs: [], raw: [0x00, 0xFF, 0x00], xrefs: []},
        { address: 0x8c, data: { type: :bgr, value: "\xFF\xFF\xFF", }, length: 3, refs: [], raw: [0xFF, 0xFF, 0xFF], xrefs: []},
        { address: 0x8f, data: { type: :bgr, value: "\x00\x00\xFF", }, length: 3, refs: [], raw: [0x00, 0x00, 0xFf], xrefs: []},

        # Row 2
        { address: 0x92, data: { type: :bgr, value: "\x00\x00\xFF", }, length: 3, refs: [], raw: [0x00, 0x00, 0xFF], xrefs: []},
        { address: 0x95, data: { type: :bgr, value: "\xFF\xFF\xFF", }, length: 3, refs: [], raw: [0xFF, 0xFF, 0xFF], xrefs: []},
        { address: 0x98, data: { type: :bgr, value: "\x00\xFF\x00", }, length: 3, refs: [], raw: [0x00, 0xFF, 0x00], xrefs: []},
        { address: 0x9b, data: { type: :bgr, value: "\x00\x00\x00", }, length: 3, refs: [], raw: [0x00, 0x00, 0x00], xrefs: []},

        # Row 1
        { address: 0x9e, data: { type: :bgr, value: "\xFF\xFF\xFF", }, length: 3, refs: [], raw: [0xFF, 0xFF, 0xFF], xrefs: []},
        { address: 0xa1, data: { type: :bgr, value: "\xFF\x00\x00", }, length: 3, refs: [], raw: [0xFF, 0x00, 0x00], xrefs: []},
        { address: 0xa4, data: { type: :bgr, value: "\x00\x00\x00", }, length: 3, refs: [], raw: [0x00, 0x00, 0x00], xrefs: []},
        { address: 0xa7, data: { type: :bgr, value: "\xFF\xFF\xFF", }, length: 3, refs: [], raw: [0xFF, 0xFF, 0xFF], xrefs: []},
      ]
    }

    assert_equal(expected, pixels)
  end
end

