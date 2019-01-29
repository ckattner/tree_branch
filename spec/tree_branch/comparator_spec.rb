# frozen_string_literal: true

#
# Copyright (c) 2018-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

require './spec/spec_helper'

describe ::TreeBranch::Comparator do
  let(:data_hash) do
    {
      'name': 'Matt',
      dob: '1920-01-04',
      'state' => 'IL'
    }
  end

  let(:context_hash) do
    {
      letters: %w[M S]
    }
  end

  it 'should initialize from hashes correctly' do
    comparator = ::TreeBranch::Comparator.new(data: data_hash, context: context_hash)

    expect(comparator.data['name']).to      eq(data_hash['name'])
    expect(comparator.data[:dob]).to        eq(data_hash[:dob])
    expect(comparator.data['state']).to     eq(data_hash['state'])
    expect(comparator.context[:letters]).to eq(context_hash[:letters])
  end

  it 'should initialize from OpenStruct objects correctly' do
    data = OpenStruct.new(data_hash)
    context = OpenStruct.new(context_hash)

    comparator = ::TreeBranch::Comparator.new(data: data, context: context)

    expect(comparator.data.name).to       eq(data.name)
    expect(comparator.data.dob).to        eq(data.dob)
    expect(comparator.data.state).to      eq(data.state)
    expect(comparator.context.letters).to eq(context.letters)
  end
end
