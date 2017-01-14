class Tram::Value
  # Values convertible to hashes
  class Struct < Tram::Value
    extend  Dry::Initializer::Mixin # adds `proc` and `option`

    class << self
      def attribute(name, *args, **opts)
        @attributes = attributes | [name.to_sym]

        # FIXME: remove this hack after dry-initializer v0.12.0
        opts[:optional] = true
        option(name, *args, **opts)

        attributes.each do |key|
          class_eval <<-RUBY
            def #{key}
              @#{key} unless @#{key} == Dry::Initializer::UNDEFINED
            end
          RUBY
        end
      end

      def attributes
        @attributes ||= []
      end

      def new(params)
        data = Hash(params).each_with_object({}) do |(key, val), obj|
          obj[key.to_sym] = val
        end

        super data
      end

      def inherited(klass)
        super
        klass.instance_variable_set :@attributes, attributes
      end
    end

    def call
      @call ||= self.class.attributes.each_with_object({}) do |key, obj|
        value = instance_variable_get :"@#{key}"
        next if value == Dry::Initializer::UNDEFINED
        obj[key] = self.class.dump(value)
      end
    end

    def to_h
      call
    end

    def to_hash
      call
    end

    def [](value)
      send value.to_sym
    end

    def eql?(other)
      self.class === other && self == other
    end

    def ==(other)
      return false                 if other.nil?
      return to_h == other.to_h    if other.respond_to? :to_h
      return to_h == other.to_hash if other.respond_to? :to_hash

      false
    end
  end
end
