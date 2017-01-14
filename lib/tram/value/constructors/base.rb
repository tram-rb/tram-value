module Tram::Value::Constructors
  # Base class for side effects added to a value object constructor
  # It can wrap value object constructors, PORO classes, or procs
  class Base < SimpleDelegator
    include Tram::Value::Constructors

    def new(source)
      return super                   if __getobj__.respond_to? :new
      return __getobj__.call(source) if __getobj__.respond_to? :call
      raise  "#{source} responds to neither :call nor :new"
    end

    def inspect
      short_name = self.class.name.sub("Tram::Value::Constructors::", "")
      "<#{short_name} #{__getobj__.inspect}>"
    end
  end
end
