# frozen_string_literal: true

#
# Copyright (c) 2018-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

require 'date'
require 'yaml'

require 'simplecov'
require 'simplecov-console'

SimpleCov.formatter = SimpleCov::Formatter::Console
SimpleCov.start

require './lib/tree_branch'

def fixture_path(filename)
  File.join('spec', 'fixtures', filename)
end

def fixture(filename)
  YAML.load_file(fixture_path(filename))
end
