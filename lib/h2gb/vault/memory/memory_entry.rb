##
# memory_entry.rb
# Created April, 2017
# By Ron Bowes
#
# See: LICENSE.md
#
# A single entry, used in the memory class. A simple class, but abstracting it
# out cleaned it up.
##

require 'h2gb/vault/error'

module H2gb
  module Vault
    module Memory
      class MemoryEntry
        attr_reader :address, :type, :value, :length, :user_defined, :comment

        def initialize(address:, type:, value:, length:, user_defined:, comment:)
          if !address.is_a?(Integer)
            raise(Error, "address must be an integer!")
          end
          if address < 0
            raise(Error, "address must not be negative!")
          end

          if type.is_a?(String)
            type = type.to_sym()
          end
          if !type.is_a?(Symbol)
            raise(Error, "type must be a string or symbol!")
          end

          if !length.is_a?(Integer)
            raise(Error, "length must be an integer!")
          end
          if length < 1
            raise(Error, "length must be at least zero!")
          end

          if !user_defined.is_a?(Hash)
            raise(Error, "user_defined must be a hash!")
          end

          @address = address
          @type = type
          @value = value
          @length = length

          # Use the helper functions when they exist
          self.comment = comment
          self.user_defined = user_defined
        end

        def self.default(address:, raw:)
          return MemoryEntry.new(
            address: address,
            type: :uint8_t,
            value: raw,
            length: 1,
            user_defined: {},
            comment: nil,
          )
        end

        def user_defined=(new_user_defined)
          if !new_user_defined.is_a?(Hash)
            raise(Error, "user_defined must be a hash!")
          end
          @user_defined = new_user_defined
        end

        def comment=(new_comment)
          if !new_comment.is_a?(String) && !new_comment.nil?
            raise(Error, "user_defined must be a string or nil!")
          end
          @comment = new_comment
        end

        def each_address()
          @address.upto(@address + @length - 1) do |i|
            yield(i)
          end
        end

        def value_to_s()
          if @type == :uint8_t
            return "0x%02x" % @value
          elsif @type == :uint16_t
            return "0x%04x" % @value
          elsif @type == :uint32_t
            return "0x%08x" % @value
          elsif @type == :offset
            return "0x%08x" % @value
          elsif @type == :rgb
            return "#" + @value.bytes.map() { |b| '%02x' % b }.join()
          else
            return "Unknown type: %s" % @type
          end
        end

        def to_s()
          if @data
            return value_to_s()
          else
            return "n/a"
          end
        end

        def ==(other)
          return (
            self.class == other.class &&
            @address == other.address &&
            @type == other.type &&
            @value == other.value &&
            @length == other.length &&
            @user_defined == other.user_defined
          )
        end
      end
    end
  end
end
