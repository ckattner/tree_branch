# TreeBranch

[![Gem Version](https://badge.fury.io/rb/tree_branch.svg)](https://badge.fury.io/rb/tree_branch) [![Build Status](https://travis-ci.org/bluemarblepayroll/tree_branch.svg?branch=master)](https://travis-ci.org/bluemarblepayroll/tree_branch) [![Maintainability](https://api.codeclimate.com/v1/badges/9875bbc4672509465601/maintainability)](https://codeclimate.com/github/bluemarblepayroll/tree_branch/maintainability) [![Test Coverage](https://api.codeclimate.com/v1/badges/9875bbc4672509465601/test_coverage)](https://codeclimate.com/github/bluemarblepayroll/tree_branch/test_coverage) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

This library allows you to traverse an entire tree structure, compare all nodes, and choose a tree structure to return.  The basic input is defined as:

1. Initial Tree structure root node (required)
2. Comparison classes or functions (optional)
3. Block to convert each matching node (optional)

And the output is defined as:

1. Compared and/or converted tree structure (root node)

The specific use-case this was designed for was a dynamic web application menu. In this specific example, we wanted either a static file or a database to store and define all possible menus. Then we wanted to input a request's lifecycle context (user, URL, parameters, authorization, etc.) and return the menu that matched the current spot in the application.

## Installation

To install through Rubygems:

````
gem install install tree_branch
````

You can also add this to your Gemfile:

````
bundle add tree_branch
````

## Examples

### Word Processor Application Menu Example

Take the following application menu structure:

````ruby
menu = {
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
            { data: { name: 'Print Preview' } },
          ]
        },
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
}.freeze
````

There are three application states:

1. No file open (user has no file currently editing): NONE
2. Passive file open: PASSIVE
3. Active file open: ACTIVE

The user is allowed only access to specific menu items depending on their state:

1. NONE: open
2. PASSIVE: open, save, close, print
3. ACTIVE: open, save, close, print, cut, copy, paste

We can implement this as a comparator class:

````ruby
class StateComparator < ::TreeBranch::Comparator
  STATE_OPS = {
    none: %i[open],
    passive: %i[open save close print],
    active: %i[open save close print cut copy paste]
  }.freeze
  private_constant :STATE_OPS

  def valid?
    data.command.nil? || Array(STATE_OPS[context[:state]]).include?(data.command)
  end
end
````

Finally, we can process this for all three states:

````ruby
no_file_menu =
  TreeBranch.process(
    node: menu,
    comparators: StateComparator,
    context: { state: :none }
  )

passive_file_menu =
  TreeBranch.process(
    node: menu,
    comparators: StateComparator,
    context: { state: :passive }
  )

active_file_menu =
  TreeBranch.process(
    node: menu,
    comparators: StateComparator,
    context: { state: :active }
  )
````

We would get the following structure back (in the form of a root Node object but expressed as a hash below):

##### No File Menu Result

````ruby
{
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
}
````

##### Passive File Menu Result

````ruby
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
      data: { name: 'Edit' }
    }
  ]
}
````

##### Active File Menu Result

````ruby
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
            { data: { name: 'Print Preview' } },
          ]
        },
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
````

### Stacking Comparators

You can also choose to input multiple comparators (technically 0 to N).  For example, let's stack authorization into our application menu example using this comparator:

````ruby
class AuthorizationComparator < ::TreeBranch::Comparator
  def valid?
    data.right.nil? || Array(context.rights).include?(data.right)
  end
end
````

Now, we can pass in our current user's rights and use them when appropriate:

````ruby
passive_read_only_menu =
  ::TreeBranch.process(
    node: menu,
    comparators: [StateComparator, AuthorizationComparator],
    context: { state: :passive }
  )

passive_read_write_menu =
  ::TreeBranch.process(
    node: menu,
    comparators: [StateComparator, AuthorizationComparator],
    context: { state: :passive, rights: :write }
  )
````

##### Read-Only User Passively Editing Result

````ruby
{
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
}
````

##### Read/Write User Passively Editing Result

````ruby
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
      data: { name: 'Edit' }
    }
  ]
}
````

Notice now our read-only menu is missing the 'save' item.

### Comparator Creation

There are two ways to create comparators:

1. Subclass ::TreeBranch::Comparator and implement the ```valid?``` method to return true/false.
2. Create lambda/proc that accepts two arguments: data and context and returns true/false.

Option one is shown in the above example, while option two can be illustrated as:

````ruby
auth_comparator = lambda do |data, context|
  data.right.nil? || Array(context.rights).include?(data.right)
end

passive_read_only_menu =
  TreeBranch.process(
    node: menu,
    comparators: [StateComparator, auth_comparator],
    context: { state: :passive }
  )
````

### Node Post-Processing / Conversion

After a node has been compared and is deemed to be valid, it will either return one of two things:

1. A `TreeBranch::Node` instance.
2. The return value of the block passed into the process method. *Note: If the block returns `nil` then it will be ignored as if it was invalid.*

In our above example, we did not pass in a block so they would all return Node instances.  The passed in block is your chance to return instances of another class, or even do some other post-processing routines.  For example, lets return an instance of a new type: MenuItem as shown below:

````ruby
class MenuItem
  acts_as_hashable # Provided by https://github.com/bluemarblepayroll/acts_as_hashable

  attr_reader :menu_items, :name

  def initialize(name: '', menu_items: [])
    @name       = name
    @menu_items = self.class.array(menu_items)
  end

  def eql?(other)
    name == other.name && menu_items == other.menu_items
  end

  alias == eql?
end
````

We can now convert this in the block:

````ruby
passive_read_write_menu =
  TreeBranch.process(
    node: menu,
    comparators: [StateComparator, auth_comparator],
    context: { state: :passive, rights: :write }
  ) { |data, children, context| MenuItem.new(data.name, children) }
````

Our resulting data set (visualized as a hash):

````ruby
{
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
}
````

## Contributing

### Development Environment Configuration

Basic steps to take to get this repository compiling:

1. Install [Ruby](https://www.ruby-lang.org/en/documentation/installation/) (check tree_branch.gemspec for versions supported)
2. Install bundler (`gem install bundler`)
3. Clone the repository (`git clone git@github.com:bluemarblepayroll/tree_branch.git`)
4. Navigate to the root folder (`cd tree_branch`)
5. Install dependencies (`bundle`)

### Running Tests

To execute the test suite run:

````
bundle exec rspec spec --format documentation
````

Alternatively, you can have Guard watch for changes:

````
bundle exec guard
````

Also, do not forget to run Rubocop:

````
bundle exec rubocop
````

Note that the default Rake tasks runs both test and Rubocop:

```
bundle exec rake
```

### Publishing

Note: ensure you have proper authorization before trying to publish new versions.

After code changes have successfully gone through the Pull Request review process then the following steps should be followed for publishing new versions:

1. Merge Pull Request into master
2. Update `lib/proforma/version.rb` using [semantic versioning](https://semver.org/)
3. Install dependencies: `bundle`
4. Update `CHANGELOG.md` with release notes
5. Commit & push master to remote and ensure CI builds master successfully
6. Run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

Note: ensure you have proper authorization before trying to publish new versions.

## License

This project is MIT Licensed.
