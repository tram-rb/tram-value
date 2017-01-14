module Tram::Value::Constructors
  # Guards selected value by returning another one
  class Either < Base
    def new(value)
      flag = @source.is_a?(Proc) ? @source[value] : @source == value
      flag ? @target : super
    end

    def inspect
      output = " as #{@target.inspect}" unless @target == @source
      "<Either #{__getobj__.inspect} | #{@source.inspect}#{output}>"
    end

    private

    def initialize(klass, source, target = source)
      super(klass)
      @source = source
      @target = target
    end
  end
end
