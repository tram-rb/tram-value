module Tram::Value::Constructors
  # The constructor raises when resulting object is invalid
  #
  # It doesn't try to validate invalidabe objects like nils and arrays,
  # so that it can be safely applied to embellished value objects as well.
  #
  class Valid < Base
    def new(*args)
      super.tap { |obj| obj.validate! if obj.respond_to? :validate! }
    end
  end
end
