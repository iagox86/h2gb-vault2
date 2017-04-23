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

module H2gb
  module Vault
    class BitmapAnalyzer
      IN = :raw
      OUT = :parsed_bmp

      def initialize(memory)
        @memory = memory
      end

      def analyze()
        @memory.transaction() do
          raw = @memory.get_raw()

          header, size, reserved1, reserved2, data_offset = raw.unpack('nVvvV')
          # Bitmap header
          if header != 0x424d
            @memory.insert(address: 0, length: 2, data: {
              error: true,
              type: :uint16_t,
              value: header,
              comment: "Unknown bitmap header: 0x%02x" % header,
            })
            return
          end
          @memory.insert(address: 0x00, length: 2, data: {
            type: :uint16_t,
            value: header,
            comment: "Bitmap header",
          })

          # Bitmap size
          if size != raw.length()
            @memory.insert(address: 0x02, length: 4, data: {
              warning: true,
              type: :uint32_t,
              value: size,
              comment: "File size (invalid)",
            })
          else
            @memory.insert(address: 0x02, length: 4, data: {
              type: :uint32_t,
              value: size,
              comment: "File size (valid)",
            })
          end

          # Two reserved fields
          @memory.insert(address: 0x06, length: 2, data: {
            type: :uint16_t,
            value: reserved1,
            comment: "Reserved",
          })
          @memory.insert(address: 0x08, length: 2, data: {
            type: :uint16_t,
            value: reserved2,
            comment: "Reserved",
          })

          # Offset to data
          @memory.insert(address: 0x0a, length: 4, refs: [data_offset], data: {
            type: :offset,
            value: data_offset,
            comment: "Offset to pixel data",
          })

          # DIB fields
          dib_length = raw[0x0e, 4].unpack('V').pop()

          # Different lengths mean a different pixel structure
          bits_per_pixel = nil
          if dib_length == 12
            @memory.insert(address: 0x0e, length: 4, data: {
              type: :uint32_t,
              value: dib_length,
              comment: "DIB structure length (BITMAPCOREHEADER) [not implemented]",
            })
          elsif dib_length == 64
            @memory.insert(address: 0x0e, length: 4, data: {
              type: :uint32_t,
              value: dib_length,
              comment: "DIB structure length (OS22XBITMAPHEADER) [not implemented]",
            })
          elsif dib_length == 16
            @memory.insert(address: 0x0e, length: 4, data: {
              type: :uint32_t,
              value: dib_length,
              comment: "DIB structure length (OS22XBITMAPHEADER [shortened]) [not implemented]",
            })
          elsif dib_length == 40
            @memory.insert(address: 0x0e, length: 4, data: {
              type: :uint32_t,
              value: dib_length,
              comment: "DIB structure length (BITMAPINFOHEADER) [not implemented]",
            })
          elsif dib_length == 52
            @memory.insert(address: 0x0e, length: 4, data: {
              type: :uint32_t,
              value: dib_length,
              comment: "DIB structure length (BITMAPV2INFOHEADER) [not implemented]",
            })
          elsif dib_length == 56
            @memory.insert(address: 0x0e, length: 4, data: {
              type: :uint32_t,
              value: dib_length,
              comment: "DIB structure length (BITMAPV3INFOHEADER) [not implemented]",
            })
          elsif dib_length == 108
            @memory.insert(address: 0x0e, length: 4, data: {
              type: :uint32_t,
              value: dib_length,
              comment: "DIB structure length (BITMAPV4HEADER)",
            })

            # Parse the other DIB fields
            width, height, planes, bits_per_pixel, bi_bitfields, size_raw, print_resolution_h, print_resolution_v, colors_in_pallette, important_colors, red_bitmask, green_bitmask, blue_bitmask, alpha_bitmask, windows_color_space, color_space_endpoints, red_gamma, green_gamma, blue_gamma = raw[0x12, 0x6c].unpack('VVvvVVVVVVVVVVVa36VVV')
            @memory.insert(address: 0x12, length: 4, data: { type: :uint32_t, value: width, comment: "Image width" })
            @memory.insert(address: 0x16, length: 4, data: { type: :uint32_t, value: height, comment: "Image height" })
            @memory.insert(address: 0x1a, length: 2, data: { type: :uint16_t, value: planes, comment: "Number of color planes" })
            @memory.insert(address: 0x1c, length: 2, data: { type: :uint16_t, value: bits_per_pixel, comment: "Bits per pixel" })
            @memory.insert(address: 0x1e, length: 4, data: { type: :uint32_t, value: bi_bitfields, comment: "bi_bitfields" })
            @memory.insert(address: 0x22, length: 4, data: { type: :uint32_t, value: size_raw, comment: "Raw image size" })
            @memory.insert(address: 0x26, length: 4, data: { type: :uint32_t, value: print_resolution_h, comment: "Horizontal print resolution" })
            @memory.insert(address: 0x2a, length: 4, data: { type: :uint32_t, value: print_resolution_v, comment: "Vertical print resolution" })
            @memory.insert(address: 0x2e, length: 4, data: { type: :uint32_t, value: colors_in_pallette, comment: "Number of colors in the pallette" })
            @memory.insert(address: 0x32, length: 4, data: { type: :uint32_t, value: important_colors, comment: "Color importance" })
            @memory.insert(address: 0x36, length: 4, data: { type: :uint32_t, value: red_bitmask, comment: "Red bitmask" })
            @memory.insert(address: 0x3a, length: 4, data: { type: :uint32_t, value: green_bitmask, comment: "Green bitmask" })
            @memory.insert(address: 0x3e, length: 4, data: { type: :uint32_t, value: blue_bitmask, comment: "Blue bitmask" })
            @memory.insert(address: 0x42, length: 4, data: { type: :uint32_t, value: alpha_bitmask, comment: "Alpha bitmask" })
            @memory.insert(address: 0x46, length: 4, data: { type: :uint32_t, value: windows_color_space, comment: "Windows color space" })
            @memory.insert(address: 0x4a, length: 0x24, data: { type: :array, subtype: :uint8_t, value: color_space_endpoints.bytes(), comment: "Color space endpoints" })
            @memory.insert(address: 0x6e, length: 4, data: { type: :uint32_t, value: red_gamma, comment: "Red gamma" })
            @memory.insert(address: 0x72, length: 4, data: { type: :uint32_t, value: green_gamma, comment: "Green gamma" })
            @memory.insert(address: 0x76, length: 4, data: { type: :uint32_t, value: blue_gamma, comment: "Blue gamma" })
          elsif dib_length == 124
            @memory.insert(address: 0x0e, length: 4, data: {
              type: :uint32_t,
              value: dib_length,
              comment: "DIB structure length (BITMAPV5HEADER) [not implemented]",
            })
          else
          end

          # Raw pixels
          if bits_per_pixel == 24
            pixels = raw[data_offset..-1]
            0.step(pixels.length - 1, 3) do |pixel_offset|
              # Images are stored in BGR, so convert to RGB to keep it consistent
              pixel = pixels[pixel_offset, 3].reverse()

              @memory.insert(address: data_offset + pixel_offset, length: 3, data: {
                type: :rgb,
                value: pixel,
              })
            end
          end
        end
      end
    end
  end
end

