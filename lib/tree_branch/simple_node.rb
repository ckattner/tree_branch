# frozen_string_literal: true

#
# Copyright (c) 2018-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

module TreeBranch
  # A basic subclass of Node that makes the data element a deterministic and comparable OpenStruct
  # object.
  class SimpleNode < Node
    acts_as_hashable

    def initialize(data: {}, children: [])
      @data     = OpenStruct.new(data)
      @children = self.class.array(children)
    end
  end
end
