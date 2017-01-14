class Tram::Value
  class Plain < Tram::Value
    include Comparable
    attr_reader :source

    let(:call) { source }

    def self.new(source)
      return source if source.is_a? self.class
      super
    end

    def ==(other)
      send(:'<=>', other)&.zero?
    end

    private

    def initialize(source)
      @source = source
    end

    def <=>(other)
      call <=> other.call if other.kind_of? self.class
    end
  end
end
