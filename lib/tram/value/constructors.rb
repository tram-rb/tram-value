# Defines a bunch of constructors shared by specific wrappers
module Tram::Value::Constructors
  # Aliases for the constructor
  def new(*args)
    super
  end

  def call(*args)
    new(*args)
  end

  def [](*args)
    new(*args)
  end

  def load(*args)
    new(*args)
  end

  # Side effects to embellish a constructor with
  require_relative "constructors/base"
  require_relative "constructors/list"
  require_relative "constructors/either"
  require_relative "constructors/valid"

  def list
    List.new(self)
  end

  def maybe
    Either.new(self, nil)
  end

  def either_present_or(target)
    Either.new(self, proc(&:blank?), target)
  end

  def either_present_or_undefined
    either_present_or Dry::Initializer::UNDEFINED
  end

  def guard(source, as: source)
    Either.new(self, source, as)
  end

  def valid
    Valid.new(self)
  end
end
