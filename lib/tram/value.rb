require "dry-initializer"
require "dry-memoizer"
require "tram-examiner"

module Tram
  # Base class for value objects
  class Value
    extend  Dry::Memoizer # adds `let` syntax
    include Tram::Examiner

    require_relative "value/constructors"
    require_relative "value/plain"
    require_relative "value/string"
    require_relative "value/struct"

    class << self
      def self.included
        include Constructors
      end

      # Makes any class or a proc to quack like value object (same API)
      def [](klass)
        Constructors::Base.new(klass)
      end

      # Converts object containing <nested> values to a storable data format
      def dump(value)
        return                     if value.nil?
        return dump_hash(value)    if value.is_a? Hash
        return dump_list(value)    if value.is_a? Array
        return dump(value.call)    if value.respond_to? :call
        return dump(value.to_h)    if value.respond_to? :to_h
        return dump(value.to_hash) if value.respond_to? :to_hash
        return dump_list(value)    if value.is_a? Enumerable
        value
      end

      private

      def dump_list(value)
        value.map { |item| dump(item) }
      end

      def dump_hash(value)
        value.each_with_object({}) { |(k, v), obj| obj[k] = dump(v) }
      end
    end

    # @abstract Converts value object to a storable data format
    def call; end

    def inspect
      "#{self.class}[#{call.inspect}]"
    end

    private

    def method_missing(*args)
      respond_to_missing?(*args) ? call.send(*args) : super
    end

    def respond_to_missing?(name, *)
      call.respond_to? name
    end
  end
end
