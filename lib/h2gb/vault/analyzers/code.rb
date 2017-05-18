##
# code.rb
# Created May, 2017
# By Ron Bowes
#
# See: LICENSE.md
#
# Define sections as 'code'.
##

require 'h2gb/vault/error'
require 'h2gb/vault/memory/memory'

require 'metasm'

module H2gb
  module Vault
    class CodeAnalyzer # TODO: Should rename this to x86
      IN = :raw
      OUT = :code

      def initialize(memory) # TODO: Make this a named parameter to match the style elsewhere
        @memory = memory
        @updater = Updater.new(memory: @memory)
      end

      def analyze()
        cpu = Metasm::X86.new()
        decoder = Metasm::EncodedData.new(@memory.raw)
        decoder.ptr = 0
        updates = []

        i = 0
        while i < @memory.raw.length
          instruction = cpu.decode_instruction(decoder, decoder.ptr)

          if(instruction.nil?)
            i += 1
            next
          end

          value = instruction.instruction.to_s()
          updates << { action: :define_custom_type,  address: i, type: :code, length:instruction.bin_length , value: value }
          i += instruction.bin_length
        end

        @updater.do(updates)

        # This is old code that I will likely use to fill in user_defined or something
#          instruction.instruction.args.each do |arg|
#            value = arg.to_s
#            if(arg.is_a?(Metasm::Expression))
#              operands << {
#                :type => 'immediate',
#                :value => ("%s%s%s" % [arg.lexpr || '', arg.op || '', arg.rexpr || '']).to_i()
#              }
#            elsif(arg.is_a?(Metasm::Ia32::Reg))
#              operands << {
#                :type => 'register',
#                :value => arg.to_s,
#                :regsize => arg.sz,
#                :regnum => arg.val,
#              }
#            elsif(arg.is_a?(Metasm::Ia32::ModRM))
#              operands << {
#                :type => 'memory',
#                :value => arg.symbolic.to_s(),
#
#                :segment         => arg.seg,
#                :memsize         => arg.sz,
#                :base_register   => arg.i.to_s(),
#                :multiplier      => arg.s || 1,
#                :offset          => arg.b.to_s(),
#                :immediate       => arg.imm.nil? ? 0 : arg.imm.rexpr,
#              }
#            elsif(arg.is_a?(Metasm::Ia32::SegReg))
#              operands << {
#                :type => 'register',
#                :value => arg.to_s()
#              }
#            elsif(arg.is_a?(Metasm::Ia32::FpReg))
#              operands << {
#                :type => "unknown[1]",
#                :value => arg.to_s()
#              }
#            elsif(arg.is_a?(Metasm::Ia32::SimdReg))
#              operands << {
#                :type => 'register',
#                :value => arg.to_s()
#              }
#            elsif(arg.is_a?(Metasm::Ia32::Farptr))
#              operands << {
#                :type => "farptr",
#                :value => arg.to_s()
#              }
#            else
#              puts("Unknown argument type:")
#              puts(arg.class)
#              puts(arg)
#
#              raise(NotImplementedError)
#            end
#          end
#
#          return {
#            :address    => address,
#            :type       => "instruction",
#            :length     => instruction.bin_length,
#            :value      => instruction.instruction.to_s,
#            :details    => {
#      #        :stack_delta => (get_stack_change(instruction.instruction) || 0)
#            },
#            :references => do_refs(address, instruction.bin_length, instruction.instruction.opname, operands),
#          }
      end
    end
  end
end
