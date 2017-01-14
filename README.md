# Tram::Value

Base classes for value objects in Rails projects.

This is a part of collection of patterns extracted from Rails projects with a special focus on separation and composability of data validators.

[![Gem Version][gem-badger]][gem]
[![Build Status][travis-badger]][travis]
[![Dependency Status][gemnasium-badger]][gemnasium]
[![Code Climate][codeclimate-badger]][codeclimate]

<a href="https://evilmartians.com/">
<img src="https://evilmartians.com/badges/sponsored-by-evil-martians.svg" alt="Sponsored by Evil Martians" width="236" height="54"></a>

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'tram-value'
```

And then execute:

```shell
$ bundle
```

Or install it yourself as:

```shell
$ gem install tram-value
```

## Usage

Value object is a domain-specific data structure written in pure Ruby which support several simple interfaces:

- Constructors - method `new` with its aliases `call`, `[]` and `load` takes raw object (like strings, hashes etc.) and wrap it to a value object
- Attributes (params and options) defined via DSL of [dry-initializer][dry-initializer]
- Wrappers - class-level helpers to add side effects to raw constructor. For example, method `maybe` wraps raw constructor in a container, that returns `nil` if argument is `nil`
- Validators - using class helper `examiner` (see [tram-examiner][tram-examiner]) you can add a standalone validator to value objects
- Dumpers - class method `.dump` along with an instance method `#call` convert value object back to raw data, storable in the database columns. All undefined methods are delegated to the `#call`
- Memoizer `let` to simplify memoization in a one line of code

### Synopsis

```ruby
class Email < Tram::Value
  param :source # dry-initializer DSL to define one parameter for the object

  examiner do # define validation rules via tram-examiner / ActiveModel::Validations
    validates :domain, presence: true
    validates :domain, format: { in: /(\w+\.)*\w+\@(\w+\.)+\w{2,3}/ } if "source.present?"
  end

  # Add memoized methods
  let(:address) { call.split("@").last }
  let(:domain)  { call.split("@").first }

  # Define (memoized) dumper and its aliases
  let(:call) { source.to_s.downcase }
  alias_method :to_s,   :call
  alias_method :to_str, :call
end
```

Lets check instance methods

```ruby
email = Email["Foo@baR.baz"] # => #<Email["foo@bar.baz"]>
email.source  # => "Foo@baR.baz"
email.address # => "foo"
email.domain  # => "bar.baz"
email.to_str  # => "foo@bar.baz"
email.call    # => "foo@bar.baz"
email[1]      # => "o" (because of authomatic deletagion to the #call)
email.valid?  # => true
```

Then explore wrappers DSL

```ruby
email = Email[nil]                             # => #<Email[""]>
email = Email.maybe[nil]                       # => nil
email = Email.guard(nil, as: "undefined")[nil] # => "undefined"
```

With this DSL you can use `Email` as a [Rails serializer][rails-serializers] to add domain-specificity to you models:

```ruby
Email.load "FOO@bar.BAZ"        # => #<Email["foo@bar.baz"]>
Email.dump Email["Foo@Bar.Baz"] # => "foo@bar.baz"

class User < ActiveRecord::Base
  serialize :email, Email.maybe
end

user = User.new email: "FOO@bar.BAZ"
user.email # => #<Email["foo@bar.baz"]>
```

### Subclasses

For convenience we provide three subclasses to simplify building value objects of your own:

#### Tram::Value::Plain

Value object, whose constructor takes one argument `source` and assigns it to `#call` (you can reload it later). It also defines comparison of value objects to other ones by their `#call`.

Let's rewrite previous definition for `Email` via new subclass.

```ruby
class Email < Tram::Value::Plain
  let(:call) { source.to_s.downcase }
  alias_method :to_s,   :call
  alias_method :to_str, :call

  examiner do # define validation rules via tram-examiner / ActiveModel::Validations
    validates :domain, presence: true
    validates :domain, format: { in: /(\w+\.)*\w+\@(\w+\.)+\w{2,3}/ } if "source.present?"
  end

  # Add memoized methods
  let(:address) { call.split("@").last }
  let(:domain)  { call.split("@").first }
end
```

Not much of simplification (except we have `source` predefined). But now we have comparison out of the box:

```ruby
Email["foo@bar.baz"] == Email["FOO@BAR.BAZ"] # => true
Email["foo@bar.baz"] < Email["bar@foo.baz"]  # => true
```

Last but not least, you can send value object as an argument several times. Every time the source object will be returned back without re-instantiation. This time you don't care whether you use value, or raw data:

```ruby
email = Email["foo@bar.baz"]
Email[email].eql? email # => true
```

#### Tram::Value::String

This class inherited from `Tram::Value::Plain` adds specifics for pretty common case, when a value based on some string. Let's try it out:

```ruby
class Email < Tram::Value::String
  examiner do # define validation rules via tram-examiner / ActiveModel::Validations
    validates :domain, presence: true
    validates :domain, format: { in: /(\w+\.)*\w+\@(\w+\.)+\w{2,3}/ } if "source.present?"
  end

  # Add memoized methods
  let(:address) { call.split("@").last }
  let(:domain)  { call.split("@").first }
end
```

Now you shouldn't care about `to_s` and `to_str` - they are predefined. Another sugar is that string values are comparable not only to other values of the same type (like plain values does), but to any object that is convertable to the same string via `to_s` or `to_str`:

```ruby
Email["foo@bar.baz"] == "foo@bar.baz"  # => true
Email["foo@bar.baz"] == :"foo@bar.baz" # => true
```

#### Tram::Value::Struct

This is another class of common objects, built from hashes.

```ruby
class Address < Tram::Value::Struct
  # attribute is an alias for dry-initializer `option`
  attribute :city,   proc(&:to_s)
  attribute :street, proc(&:to_s)
  attribute :house,  proc(&:to_s)
  attribute :flat,   proc(&:to_s)

  examiner do
    validates :city, :street, :house, presence: true
  end
end
```

This time `call` aliased as `to_h` or `to_hash`:

```ruby
address = Address[city: :Moscow, street: "Chaplygina St.", house: 6, flat: nil]
# => #<Address[{ city: "Moscow", street: "Chaplygina St.", house: "6", flat: "" }]>
address.call   # => { city: "Moscow", street: "Chaplygina St.", house: "6", flat: "" }
address.to_h   # => { city: "Moscow", street: "Chaplygina St.", house: "6", flat: "" }
address.valid? # => true
```

Undefined values are ignored (look at the absence of flat and compare it with the example above):

```ruby
address = Address[city: :Moscow, street: "Chaplygina St.", house: 6]
# => #<Address[{ city: "Moscow", street: "Chaplygina St.", house: "6" }]>
```

Validation is available as well:

```ruby
address = Address[] # => #<Address[{}]>
address.errors # => { city: ["shouldn't be blank", street: ["shouldn't be blank"], house: "shouldn't be blank"] }
address.valid? # => false
```

Struct may be nested. When struct value is dumped (hashified), it goes through all nested arrays, hashes, and value objects and dumps them as well:

```ruby
require "tram-validators"

class User < Tram::Value::Struct
  attribute :name,    proc(&:to_s)
  attribute :address, Address
  attribute :email,   Email

  examiner do
    validates :name, presence: true
    # ValidityValidator is defined in `tram-validators` collection
    # and checks that given attribute is valid per se, then collects
    # errors under corresponding keys
    validates :address, :email, validity: { nested_keys: true }
  end
end

user = User.new name: "Andy", address: { city: :Moscow, street: "Tverskaya St.", house: 34 }, email: "Andy@example.com"
# => #<User[name: "Andy", address: { city: Moscow, street: "Tverskaya St.", house: "34" }, email: "andy@example.com"]>
user.address # => #<Address[{ city: Moscow, street: "Tverskaya St.", house: "34" }]>
user.email   # => #<Email["andy@example.com"]>

# It dumps all the nested structures at once:
user.to_h # => { name: "Andy", address: { city: Moscow, street: "Tverskaya St.", house: "34" }, email: "andy@example.com" }
```

### Constructor Wrappers (Decorators)

Every value object class supports several decorators to add some side effects:

```ruby
class User < Tram::Value::Struct
  attribute :address, Address.maybe # => sets address to `nil` if `nil` is provided
  attribute :email,   Email.either_present_or(nil) # => sets email to `nil` if any blank value provided
  attribute :name,    HumanName.either_present_or_undefined # => treats name as undefined if blank value provided
  attribute :gender,  Gender.guard(proc(&:blank?), as: "alien") # => substitutes blank values by "alien" string

  examiner do
    validates :address, :name, :email, validity: true, allow_nil: true
    validates :gender, validity: true, unless: -> { gender == "alien" }
  end
end

user = User[{ address: nil, email: "", name: "", gender: "" }]
# => #<User[{ address: nil, email: nil, gender: "alien" }]>
user.valid? # => true
```

Another important wrapper is `valid`. This wrapper applies `validate!` to resulting value object and raises if it isn't valid. You should use this technics to prevent instantiation of invalid objects (or parts).

```ruby
user = User.valid[address: {}]
# => BOOM! (address should have city, street and house)
```

The last thing to mention is sometimes you need decorate an arbitrary Ruby class, or even a proc, with methods like `maybe`, `guard` etc. You can do this in by wrapping any object that responds to either `new` or `call` to `Tram::Value[]`:

```ruby
class User < Tram::Value::Struct
  attribute :name,   Tram::Value[String].guard(nil, as: "Unknown")
  attribute :age,    Tram::Value[proc(&:to_i)].maybe
  attribute :gender, Tram::Value[proc(&:to_h)].either_present_or_undefined
end

User[name: :Andy, age: "22", gender: :male]
# => #<User[{ name: "Andy", age: 22, gender: "male" }]

User[name: nil, age: nil, gender: nil]
# => User[{ name: "Unknown", age: nil }] (there is no gender because it is treated undefined)
```

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

[codeclimate-badger]: https://img.shields.io/codeclimate/github/tram-rb/tram-value.svg?style=flat
[codeclimate]: https://codeclimate.com/github/tram-rb/tram-value
[gem-badger]: https://img.shields.io/gem/v/tram-value.svg?style=flat
[gem]: https://rubygems.org/gems/tram-value
[gemnasium-badger]: https://img.shields.io/gemnasium/tram-rb/tram-value.svg?style=flat
[gemnasium]: https://gemnasium.com/tram-rb/tram-value
[travis-badger]: https://img.shields.io/travis/tram-rb/tram-value/master.svg?style=flat
[travis]: https://travis-ci.org/tram-rb/tram-value
[tram-examiner]: https://github.com/tram-rb/tram-examiner
[dry-initializer]: https://github.com/dry-rb/dry-initializer
[rails-serializer]: http://api.rubyonrails.org/classes/ActiveRecord/AttributeMethods/Serialization/ClassMethods.html
