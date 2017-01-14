class Tram::Value
  class String < Plain
    let(:call) { source.to_s }

    def to_s
      call
    end

    def to_str
      call
    end

    private

    def <=>(other)
      return to_s <=> other.to_s   if other.respond_to? :to_s
      return to_s <=> other.to_str if other.respond_to? :to_str
    end
  end
end
