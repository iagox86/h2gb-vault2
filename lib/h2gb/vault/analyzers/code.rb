# encoding: ASCII-8BIT
##
# code.rb
# Created May, 2017
# By Ron Bowes
#
# See: LICENSE.md
#
# Define sections as 'code'.
##

require 'crabstone'

require 'h2gb/vault/error'
require 'h2gb/vault/workspace'

module H2gb
  module Vault
    class CodeAnalyzer # TODO: Should rename this to x86
      IN = :raw
      OUT = :code

      def initialize(workspace:)
        @workspace = workspace
        @updater = Updater.new(workspace: @workspace)
      end

      def analyze()
        cs = Crabstone::Disassembler.new(Crabstone::ARCH_X86, Crabstone::MODE_32)

        updates = []
        cs.disasm(@workspace.raw(block_name: 'data'), 0x0000).each do |instruction|
          updates << { action: :define_custom_type, block_name: 'data', address: instruction.address, type: :code, length: instruction.bytes.length, value: '%s %s' % [instruction.mnemonic.to_s, instruction.op_str.to_s] }
        end

        @updater.do(updates)
      end
    end
  end
end
