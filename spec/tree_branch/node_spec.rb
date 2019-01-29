# frozen_string_literal: true

#
# Copyright (c) 2018-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

require './spec/spec_helper'

describe ::TreeBranch::Node do
  let(:node_hash) { fixture('node.yml') }

  let(:node) { ::TreeBranch::SimpleNode.make(node_hash) }

  it 'should initialize and equality compare correctly' do
    expected_data     = OpenStruct.new(node_hash[:data])
    expected_children = ::TreeBranch::SimpleNode.array(node_hash[:children])

    expect(node.data).to      eq(expected_data)
    expect(node.children).to  eq(expected_children)
  end
end
