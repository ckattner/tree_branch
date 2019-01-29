# frozen_string_literal: true

#
# Copyright (c) 2018-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

module TreeBranch
  # This is the base class for all plug in comparators.  Derive subclasses from this class
  # and declare them when calling ::TreeBranch::Node#process or ::TreeBranch#process.
  class Comparator
    attr_reader :data, :context

    def initialize(data: {}, context: {})
      @data     = data    || {}
      @context  = context || {}
    end

    def valid?
      false
    end
  end
end
