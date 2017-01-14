module Tram::Value::Constructors
  # Lifts the constructor into array
  class List < Base
    def new(items)
      items&.map { |item| super(item) }
    end
  end
end
