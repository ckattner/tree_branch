# frozen_string_literal: true

#
# Copyright (c) 2018-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

module TreeBranch
  # Main class the outlines the basic operations and structure of a node in the tree.
  class Node
    attr_reader :data, :children

    def initialize(data)
      @data     = data
      @children = []
    end

    def add(*children_to_add)
      children_to_add.flatten.each do |child|
        raise ArgumentError, "Improper class: #{child.class.name}" unless child.is_a?(self.class)

        @children << child
      end

      self
    end

    def eql?(other)
      data == other.data && children == other.children
    end

    def ==(other)
      eql?(other)
    end

    def to_s
      "[#{self.class.name}] Data: #{data}, Child Count: #{children.length}"
    end
  end
end
