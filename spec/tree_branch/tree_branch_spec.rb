# frozen_string_literal: true

#
# Copyright (c) 2018-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

require './spec/spec_helper'

require 'pry'

class MenuItem
  acts_as_hashable

  attr_reader :menu_items, :name

  def initialize(name: '', menu_items: [])
    @name       = name
    @menu_items = self.class.array(menu_items)
  end

  def eql?(other)
    name == other.name && menu_items == other.menu_items
  end

  def ==(other)
    eql?(other)
  end
end

class BornAfter1915 < ::TreeBranch::Comparator
  def valid?
    Date.parse(data.dob).year > 1915
  end
end

class NameStartsWith < ::TreeBranch::Comparator
  def valid?
    context[:letters].include?(data.name.to_s[0])
  end
end

class StateComparator < ::TreeBranch::Comparator
  STATE_OPS = {
    none: %i[open],
    passive: %i[open save close print],
    active: %i[open save close print cut copy paste]
  }.freeze

  def valid?
    data.command.nil? || Array(STATE_OPS[context[:state]]).include?(data.command)
  end
end

class AuthorizationComparator < ::TreeBranch::Comparator
  def valid?
    data.right.nil? || Array(context[:rights]).include?(data.right)
  end
end

describe ::TreeBranch do
  # We will use this spec to also test ::TreeBranch::Node#process since ::TreeBranch#process
  # fully delegates to that method.
  describe '#process' do
    let(:node_hash) { fixture('node.yml') }

    let(:node_hash_with_injected) { fixture('node_with_injected.yml') }

    let(:node) { ::TreeBranch::SimpleNode.make(node_hash) }

    let(:node_with_injected) { ::TreeBranch::SimpleNode.make(node_hash_with_injected) }

    let(:born_after1915_hash) { fixture('born_after1915.yml') }

    let(:born_after1915) { ::TreeBranch::SimpleNode.make(born_after1915_hash) }

    let(:born_after1915_starts_with_m_or_s_hash) do
      fixture('born_after1915_with_m_or_s.yml')
    end

    let(:born_after1915_starts_with_m_or_s) do
      ::TreeBranch::SimpleNode.make(born_after1915_starts_with_m_or_s_hash)
    end

    let(:name_starts_with_lambda) do
      lambda do |data, context|
        context.letters.include?(data.name.to_s[0])
      end
    end

    it 'should return everything when no comparators are given' do
      expect(::TreeBranch.process(node: node_hash)).to eq(node)
    end

    it 'should return nil when no comparators pass for top level node' do
      # The base comparator class returns false by default
      expect(::TreeBranch.process(node: node_hash, comparators: ::TreeBranch::Comparator)).to be nil
    end

    it 'should return valid nodes with one comparator' do
      actual = ::TreeBranch.process(node: node_hash, comparators: BornAfter1915)

      expect(actual).to eq(born_after1915)
    end

    it 'should return valid nodes with two class comparators' do
      input = {
        node: node_hash,
        context: { letters: %w[M S] },
        comparators: [BornAfter1915, NameStartsWith]
      }

      expect(::TreeBranch.process(input)).to eq(born_after1915_starts_with_m_or_s)
    end

    it 'should return valid nodes with one class comparator and one lambda comparator' do
      input = {
        node: node_hash,
        context: { letters: %w[M S] },
        comparators: [BornAfter1915, name_starts_with_lambda]
      }

      expect(::TreeBranch.process(input)).to eq(born_after1915_starts_with_m_or_s)
    end

    it 'should execute the block after node processing' do
      outside_variable = '!!'

      input = {
        node: node,
        context: OpenStruct.new(suffix: 'cakes')
      }

      processed = ::TreeBranch.process(input) do |data, children, context|
        local_node = ::TreeBranch::SimpleNode.new(data: data, children: children)

        local_node.data.injected = "#{local_node.data.name}#{context.suffix}#{outside_variable}"

        local_node
      end

      expect(processed).to eq(node_with_injected)
    end
  end

  describe 'README Examples' do
    let(:menu) do
      {
        data: { name: 'Menu' },
        children: [
          {
            data: { name: 'File' },
            children: [
              { data: { name: 'Open', command: :open } },
              { data: { name: 'Save', command: :save, right: :write } },
              { data: { name: 'Close', command: :close } },
              {
                data: { name: 'Print', command: :print },
                children: [
                  { data: { name: 'Print' } },
                  { data: { name: 'Print Preview' } }
                ]
              }
            ]
          },
          {
            data: { name: 'Edit' },
            children: [
              { data: { name: 'Cut', command: :cut } },
              { data: { name: 'Copy', command: :copy } },
              { data: { name: 'Paste', command: :paste } }
            ]
          }
        ]
      }
    end

    it 'should compute state: none' do
      no_file_menu = ::TreeBranch.process(
        node: menu,
        comparators: StateComparator,
        context: { state: :none }
      ) do |data, children, _context|
        ::TreeBranch::SimpleNode.new(data: data, children: children)
      end

      expected = ::TreeBranch::SimpleNode.new(
        data: { name: 'Menu' },
        children: [
          {
            data: { name: 'File' },
            children: [
              { data: { name: 'Open', command: :open } }
            ]
          },
          {
            data: { name: 'Edit' }
          }
        ]
      )

      expect(no_file_menu).to eq(expected)
    end

    it 'should compute state: passive' do
      no_file_menu = ::TreeBranch.process(
        node: menu,
        comparators: StateComparator,
        context: { state: :passive }
      ) do |data, children, _context|
        ::TreeBranch::SimpleNode.new(data: data, children: children)
      end

      expected = ::TreeBranch::SimpleNode.new(
        data: { name: 'Menu' },
        children: [
          {
            data: { name: 'File' },
            children: [
              { data: { name: 'Open', command: :open } },
              { data: { name: 'Save', command: :save, right: :write } },
              { data: { name: 'Close', command: :close } },
              {
                data: { name: 'Print', command: :print },
                children: [
                  { data: { name: 'Print' } },
                  { data: { name: 'Print Preview' } }
                ]
              }
            ]
          },
          {
            data: { name: 'Edit' }
          }
        ]
      )

      expect(no_file_menu).to eq(expected)
    end

    it 'should compute state: active' do
      no_file_menu = ::TreeBranch.process(
        node: menu,
        comparators: StateComparator,
        context: { state: :active }
      ) do |data, children, _context|
        ::TreeBranch::SimpleNode.new(data: data, children: children)
      end

      expected = ::TreeBranch::SimpleNode.new(
        data: { name: 'Menu' },
        children: [
          {
            data: { name: 'File' },
            children: [
              { data: { name: 'Open', command: :open } },
              { data: { name: 'Save', command: :save, right: :write } },
              { data: { name: 'Close', command: :close } },
              {
                data: { name: 'Print', command: :print },
                children: [
                  { data: { name: 'Print' } },
                  { data: { name: 'Print Preview' } }
                ]
              }
            ]
          },
          {
            data: { name: 'Edit' },
            children: [
              { data: { name: 'Cut', command: :cut } },
              { data: { name: 'Copy', command: :copy } },
              { data: { name: 'Paste', command: :paste } }
            ]
          }
        ]
      )

      expect(no_file_menu).to eq(expected)
    end

    it 'should compute state: passive for read-only authorization' do
      no_file_menu = ::TreeBranch.process(
        node: menu,
        comparators: [StateComparator, AuthorizationComparator],
        context: { state: :passive }
      ) do |data, children, _context|
        ::TreeBranch::SimpleNode.new(data: data, children: children)
      end

      expected = ::TreeBranch::SimpleNode.new(
        data: { name: 'Menu' },
        children: [
          {
            data: { name: 'File' },
            children: [
              { data: { name: 'Open', command: :open } },
              { data: { name: 'Close', command: :close } },
              {
                data: { name: 'Print', command: :print },
                children: [
                  { data: { name: 'Print' } },
                  { data: { name: 'Print Preview' } }
                ]
              }
            ]
          },
          {
            data: { name: 'Edit' }
          }
        ]
      )

      expect(no_file_menu).to eq(expected)
    end

    it 'should compute state: passive for read/write authorization' do
      no_file_menu = ::TreeBranch.process(
        node: menu,
        comparators: [StateComparator, AuthorizationComparator],
        context: { state: :passive, rights: :write }
      ) do |data, children, _context|
        ::TreeBranch::SimpleNode.new(data: data, children: children)
      end

      expected = ::TreeBranch::SimpleNode.new(
        data: { name: 'Menu' },
        children: [
          {
            data: { name: 'File' },
            children: [
              { data: { name: 'Open', command: :open } },
              { data: { name: 'Save', command: :save, right: :write } },
              { data: { name: 'Close', command: :close } },
              {
                data: { name: 'Print', command: :print },
                children: [
                  { data: { name: 'Print' } },
                  { data: { name: 'Print Preview' } }
                ]
              }
            ]
          },
          {
            data: { name: 'Edit' }
          }
        ]
      )

      expect(no_file_menu).to eq(expected)
    end

    let(:auth_comparator) do
      lambda do |data, context|
        data.right.nil? || Array(context.rights).include?(data.right)
      end
    end

    it 'should compute state: passive for read/write authorization and return MenuItem(s)' do
      passive_read_write_menu =
        ::TreeBranch.process(
          node: menu,
          comparators: [StateComparator, auth_comparator],
          context: { state: :passive, rights: :write }
        ) { |data, children, _context| MenuItem.new(name: data.name, menu_items: children) }

      expected = MenuItem.new(
        name: 'Menu',
        menu_items: [
          {
            name: 'File',
            menu_items: [
              { name: 'Open' },
              { name: 'Save' },
              { name: 'Close' },
              {
                name: 'Print',
                menu_items: [
                  { name: 'Print' },
                  { name: 'Print Preview' }
                ]
              }
            ]
          },
          {
            name: 'Edit'
          }
        ]
      )

      expect(passive_read_write_menu).to eq(expected)
    end
  end
end
