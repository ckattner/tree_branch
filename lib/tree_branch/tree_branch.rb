# frozen_string_literal: true

#
# Copyright (c) 2018-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

require 'acts_as_hashable'
require 'ostruct'

require_relative 'comparator'
require_relative 'node'
require_relative 'simple_node'
require_relative 'processor'

# Top-level namespace of the library.  The methods contained here should be considered the
# main public API.
module TreeBranch
  class << self
    def process(node: {}, context: {}, comparators: [], &block)
      ::TreeBranch::Processor.new
                             .process(
                               normalize_node(node),
                               context: context,
                               comparators: comparators,
                               &block
                             )
    end

    private

    def normalize_node(node)
      node.is_a?(::TreeBranch::Node) ? node : ::TreeBranch::SimpleNode.make(node, nullable: false)
    end
  end
end
