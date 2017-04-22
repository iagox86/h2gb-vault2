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
              comment: "Unknown bitmap header: 0x%02x" % header,
              type: :uint16_t,
              value: header,
            })
            return
          end
          @memory.insert(address: 0x00, length: 2, data: {
            comment: "Bitmap header",
            type: :uint16_t,
            value: header,
          })

          # Bitmap size
          if size != raw.length()
            @memory.insert(address: 0x02, length: 4, data: {
              warning: true,
              comment: "File size (invalid)",
              type: :uint32_t,
              value: size,
            })
          else
            @memory.insert(address: 0x02, length: 4, data: {
              comment: "File size (valid)",
              type: :uint32_t,
              value: size,
            })
          end

          # Two reserved fields
          @memory.insert(address: 0x06, length: 2, data: {
            comment: "Reserved",
            type: :uint16_t,
            value: reserved1,
          })
          @memory.insert(address: 0x08, length: 2, data: {
            comment: "Reserved",
            type: :uint16_t,
            value: reserved2,
          })

          # Offset to data
          @memory.insert(address: 0x0a, length: 4, refs: [data_offset], data: {
            comment: "Offset to pixel data",
            type: :offset,
            value: data_offset,
          })

          # Raw pixels
          pixels = raw[data_offset..-1]
          0.step(pixels.length - 1, 3) do |pixel_offset|
            pixel = pixels[pixel_offset, 3]

            @memory.insert(address: data_offset + pixel_offset, length: 3, data: {
              type: :bgr,
              value: pixel,
            })
          end
        end
      end
    end
  end
end

