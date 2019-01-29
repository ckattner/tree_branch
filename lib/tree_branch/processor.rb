# frozen_string_literal: true

#
# Copyright (c) 2018-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

module TreeBranch
  # This class understands how to take a tree, digest it given a context, set of comparators, and a
  # block, then returns a new tree structure.
  class Processor
    def process(node, context: nil, comparators: [], &block)
      return nil if at_least_one_comparator_returns_false?(node.data, context, comparators)

      valid_children = process_children(node.children, context, comparators, &block)

      if block_given?
        yield(node.data, valid_children, context)
      else
        ::TreeBranch::Node.new(node.data)
                          .add(valid_children)
      end
    end

    private

    def at_least_one_comparator_returns_false?(data, context, comparators)
      Array(comparators).any? { |c| execute_comparator(c, data, context) == false }
    end

    def process_children(children, context, comparators, &block)
      children.map do |node|
        process(node, context: context, comparators: comparators, &block)
      end.compact
    end

    def execute_comparator(comparator, data, context)
      if comparator.is_a?(Proc)
        comparator.call(OpenStruct.new(data), OpenStruct.new(context))
      else
        comparator.new(data: data, context: context).valid?
      end
    end
  end
end
