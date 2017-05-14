##
# bitmap.rb
# Created April, 2017
# By Ron Bowes
#
# See: LICENSE.md
#
# A simple "analyzer" script that I'm writing to help myself understand the
# requirements of a "real" script.
#
# Ultimately the goal of h2gb is to analyze a binary executable file, but
# file formats are definitely a practical use-case for the framework, and .bmp
# is super well understood!
##

require 'h2gb/vault/memory/memory'
require 'h2gb/vault/types/updater'

module H2gb
  module Vault
    class BitmapAnalyzer
      IN = :raw
      OUT = :parsed_bmp

      def initialize(memory)
        @memory = memory
        @updater = Updater.new(memory: @memory)
      end

      def analyze()
        # Update the easy stuff
        @updater.do([
          # Bitmap header
          { action: :define_basic_type, address: 0x0000, type: :uint16_t, options: { endian: :big }, user_defined: { display_hint: :string }, comment: 'BMP header' },
          { action: :define_basic_type, address: 0x0002, type: :uint32_t, options: { endian: :little }, comment: 'File size' },
          { action: :define_basic_type, address: 0x0006, type: :uint16_t, options: { endian: :little }, comment: 'Reserved (1)' },
          { action: :define_basic_type, address: 0x0008, type: :uint16_t, options: { endian: :little }, comment: 'Reserved (2)' },
          { action: :define_basic_type, address: 0x000a, type: :offset32, options: { endian: :little }, comment: 'Offset to pixel data' },

          # DIB header
          { action: :define_basic_type, address: 0x000e, type: :uint32_t, options: { endian: :little }, comment: 'DIB header size' },
        ])

        # Validate fields in the bitmap header
        header = @memory.get_value(address: 0x0000)
        if header != 0x424d
          @updater.do([
            { action: :set_comment, address: 0x0000, comment: 'BMP header (invalid)' },
            { action: :update_user_defined, address: 0x0000, user_defined: { error: warning, error_text: 'Invalid BMP header' } },
          ])
        end

        # Validate the file size
        file_size_entry = @memory.get_single(address: 0x0002)
        if file_size_entry[:value] != @memory.raw.length()
          @updater.do([
            { action: :set_comment, address: 0x0000, comment: 'File size (invalid)' },
            { action: :update_user_defined, address: 0x0000, user_defined: { error: warning, error_text: "Doesn't match the file's actual size!" } },
          ])
        end

        # Different lengths mean a different pixel structure
        dib_length_entry = @memory.get_single(address: 0x000e)
        dib_length = dib_length_entry[:value]

        # TODO: Use this as an excuse to implement array, struct, and enum support
        if dib_length == 12
          @updater.do([
            { action: :set_comment,         address: 0x000e, comment: "DIB structure length (BIGMAPCOREHEADER)" },
            { action: :update_user_defined, address: 0x000e, user_defined: { error: warning, error_text: 'Parsing not implemented' } },
            { action: :define_custom_type,  address: 0x0012, type: :custom_type, length: dib_length, value: "n/a", comment: 'Unparsed DIB header' }
          ])
        elsif dib_length == 64
          @updater.do([
            { action: :set_comment,         address: 0x000e, comment: "DIB structure length (OS22XBITMAPHEADER)" },
            { action: :update_user_defined, address: 0x000e, user_defined: { error: warning, error_text: 'Parsing not implemented' } },
            { action: :define_custom_type,  address: 0x0012, type: :custom_type, length: dib_length, value: "n/a", comment: 'Unparsed DIB header' }
          ])
        elsif dib_length == 16
          @updater.do([
            { action: :set_comment,         address: 0x000e, comment: "DIB structure length (OS22XBITMAPHEADER_shortened)" },
            { action: :update_user_defined, address: 0x000e, user_defined: { error: warning, error_text: 'Parsing not implemented' } },
            { action: :define_custom_type,  address: 0x0012, type: :custom_type, length: dib_length, value: "n/a", comment: 'Unparsed DIB header' }
          ])
        elsif dib_length == 40
          @updater.do([
            { action: :set_comment,         address: 0x000e, comment: "DIB structure length (BITMAPINFOHEADER)" },
            { action: :update_user_defined, address: 0x000e, user_defined: { error: warning, error_text: 'Parsing not implemented' } },
            { action: :define_custom_type,  address: 0x0012, type: :custom_type, length: dib_length, value: "n/a", comment: 'Unparsed DIB header' }
          ])
        elsif dib_length == 52
          @updater.do([
            { action: :set_comment,         address: 0x000e, comment: "DIB structure length (BITMAPV2INFOHEADER)" },
            { action: :update_user_defined, address: 0x000e, user_defined: { error: warning, error_text: 'Parsing not implemented' } },
            { action: :define_custom_type,  address: 0x0012, type: :custom_type, length: dib_length, value: "n/a", comment: 'Unparsed DIB header' }
          ])
        elsif dib_length == 56
          @updater.do([
            { action: :set_comment,         address: 0x000e, comment: "DIB structure length (BITMAPV3INFOHEADER)" },
            { action: :update_user_defined, address: 0x000e, user_defined: { error: warning, error_text: 'Parsing not implemented' } },
            { action: :define_custom_type,  address: 0x0012, type: :custom_type, length: dib_length, value: "n/a", comment: 'Unparsed DIB header' }
          ])
        elsif dib_length == 108
          @updater.do([
            { action: :set_comment,         address: 0x000e, comment: "DIB structure length (BITMAPV4HEADER)" },
            { action: :define_basic_type,   address: 0x0012, type: :uint32_t, options: { endian: :little }, comment: 'Image width' },
            { action: :define_basic_type,   address: 0x0016, type: :uint32_t, options: { endian: :little }, comment: 'Image height' },
            { action: :define_basic_type,   address: 0x001a, type: :uint16_t, options: { endian: :little }, comment: 'Number of colour planes' },
            { action: :define_basic_type,   address: 0x001c, type: :uint16_t, options: { endian: :little }, comment: 'Bits per pixel' },
            { action: :define_basic_type,   address: 0x001e, type: :uint32_t, options: { endian: :little }, comment: 'bi_bitfields' },
            { action: :define_basic_type,   address: 0x0022, type: :uint32_t, options: { endian: :little }, comment: 'Raw image size' },
            { action: :define_basic_type,   address: 0x0026, type: :uint32_t, options: { endian: :little }, comment: 'Horizontal print resolution' },
            { action: :define_basic_type,   address: 0x002a, type: :uint32_t, options: { endian: :little }, comment: 'Vertrical print resolution' },
            { action: :define_basic_type,   address: 0x002e, type: :uint32_t, options: { endian: :little }, comment: 'Number of colours in the pallette' },
            { action: :define_basic_type,   address: 0x0032, type: :uint32_t, options: { endian: :little }, comment: 'Colour importance' },
            { action: :define_basic_type,   address: 0x0036, type: :uint32_t, options: { endian: :little }, comment: 'Red bitmask' },
            { action: :define_basic_type,   address: 0x003a, type: :uint32_t, options: { endian: :little }, comment: 'Green bitmask' },
            { action: :define_basic_type,   address: 0x003e, type: :uint32_t, options: { endian: :little }, comment: 'Blue bitmask' },
            { action: :define_basic_type,   address: 0x0042, type: :uint32_t, options: { endian: :little }, comment: 'Alpha bitmask' },
            { action: :define_basic_type,   address: 0x0046, type: :uint32_t, options: { endian: :little }, comment: 'Windows colour space' },
            { action: :define_custom_type,  address: 0x004a, type: :colour_space_endpoints, length: 0x24, value: 'n/a', comment: 'Colour space endpoints' },
            { action: :define_basic_type,   address: 0x006e, type: :uint32_t, options: { endian: :little }, comment: 'Red gamma' },
            { action: :define_basic_type,   address: 0x0072, type: :uint32_t, options: { endian: :little }, comment: 'Green gamma' },
            { action: :define_basic_type,   address: 0x0076, type: :uint32_t, options: { endian: :little }, comment: 'Blue gamma' },
          ])
        elsif dib_length == 124
          @updater.do([
            { action: :set_comment,         address: 0x000e, comment: "DIB structure length (BITMAPV5HEADER)" },
            { action: :update_user_defined, address: 0x000e, user_defined: { error: warning, error_text: 'Parsing not implemented' } },
            { action: :define_custom_type,  address: 0x0012, type: :custom_type, length: dib_length, value: "n/a", comment: 'Unparsed DIB header' }
          ])
        else
          @updater.do([
            { action: :set_comment,         address: 0x000e, comment: "DIB structure length (Unknown header type!)" },
            { action: :update_user_defined, address: 0x000e, user_defined: { error: error, error_text: 'Unknown header type!' } },
            { action: :define_custom_type,  address: 0x0012, type: :custom_type, length: dib_length, value: "n/a", comment: 'Unknown DIB header' }
          ])
        end

        # Raw pixels
        pixel_offset = @memory.get_single(address: 0x000a)[:value]
        # TODO: This hardcoded offset won't work if I implement other bitmap types
        bits_per_pixel = @memory.get_single(address: 0x001c)[:value]

        if bits_per_pixel == 24
          updates = []
          pixel_offset.step(@memory.raw.length() - 1, 3) do |i|
            updates << { action: :define_basic_type, address: i, type: :rgb, options: { endian: :little }}
          end

          @updater.do(updates)
        end
      end
    end
  end
end

