RSpec.describe Tram::Value, ".[]" do
  describe ".new" do
    context "with a class:" do
      subject { described_class[Hash] }

      it "is transparent" do
        obj = subject.new("foo")

        expect(obj).to be_kind_of Hash
        expect(obj[:bar]).to eq "foo"
      end
    end

    context "with a proc:" do
      subject { described_class[proc(&:to_i)] }

      it "is an alias for .call" do
        expect(subject.new("12")).to eq 12
      end
    end
  end

  describe ".call" do
    context "with a class:" do
      subject { described_class[Hash] }

      it "is an alias for .new" do
        obj = subject.call("foo")

        expect(obj).to be_kind_of Hash
        expect(obj[:bar]).to eq "foo"
      end
    end

    context "with a proc:" do
      subject { described_class[proc(&:to_i)] }

      it "is transparent" do
        expect(subject.call("12")).to eq 12
      end
    end
  end

  describe ".list" do
    context "with a class:" do
      subject { described_class[Hash].list }

      it "wraps source items" do
        data = subject.new %w(foo bar)

        expect(data).to be_kind_of Array
        expect(data.first[:qux]).to eq "foo"
        expect(data.last[:qux]).to eq "bar"
      end
    end

    context "with a proc:" do
      subject { described_class[proc(&:to_i)].list }

      it "wraps source items" do
        data = subject.new %w(11 21)

        expect(data).to be_kind_of Array
        expect(data.first).to eq 11
        expect(data.last).to eq 21
      end
    end
  end

  describe ".maybe" do
    context "with a class:" do
      subject { described_class[Hash].maybe }

      it "is transient when value not nil" do
        data = subject.new "foo"

        expect(data).to be_a Hash
        expect(data[:x]).to eq "foo"
      end

      it "converts nil to nil" do
        expect(subject.new(nil)).to be_nil
      end
    end

    context "with a proc:" do
      subject { described_class[proc(&:to_i)].maybe }

      it "is transient when value not nil" do
        expect(subject.new "42").to eq 42
      end

      it "converts nil to nil" do
        expect(subject.new(nil)).to be_nil
      end
    end
  end

  describe ".either_present_or" do
    context "with a class:" do
      subject { described_class[Hash].either_present_or :baz }

      it "is transient when value not empty" do
        data = subject.new "foo"

        expect(data).to be_a Hash
        expect(data[:x]).to eq "foo"
      end

      it "converts empty value to guard object" do
        expect(subject.new(nil)).to eq :baz
      end
    end

    context "with a proc:" do
      subject { described_class[proc(&:to_i)].either_present_or :baz }

      it "is transient when value not empty" do
        expect(subject.new "42").to eq 42
      end

      it "converts empty value to guard object" do
        expect(subject.new(nil)).to eq :baz
      end
    end
  end

  describe ".either_present_or" do
    context "with a class:" do
      subject { described_class[Hash].either_present_or_undefined }

      it "is transient when value not empty" do
        data = subject.new "foo"

        expect(data).to be_a Hash
        expect(data[:x]).to eq "foo"
      end

      it "converts empty value to Dry::Initializer::UNDEFINED" do
        expect(subject.new(nil)).to eq Dry::Initializer::UNDEFINED
      end
    end

    context "with a proc:" do
      subject { described_class[proc(&:to_i)].either_present_or_undefined }

      it "is transient when value not empty" do
        expect(subject.new "42").to eq 42
      end

      it "converts empty value to Dry::Initializer::UNDEFINED" do
        expect(subject.new(nil)).to eq Dry::Initializer::UNDEFINED
      end
    end
  end

  describe ".guard value" do
    context "with a class:" do
      subject { described_class[Hash].guard(:foo, as: :bar) }

      it "is transient when value not guarded" do
        data = subject.new "foo"

        expect(data).to be_a Hash
        expect(data[:x]).to eq "foo"
      end

      it "converts guarded value" do
        expect(subject.new(:foo)).to eq :bar
      end
    end

    context "with a proc:" do
      subject { described_class[proc(&:to_i)].guard(:foo, as: :bar) }

      it "is transient when value not guarded" do
        expect(subject.new "42").to eq 42
      end

      it "converts guarded value" do
        expect(subject.new(:foo)).to eq :bar
      end
    end
  end

  describe ".guard proc" do
    context "with a class:" do
      subject { described_class[Hash].guard(->(v) { v.to_s == "x" }, as: :bar) }

      it "is transient when value not guarded" do
        data = subject.new "foo"

        expect(data).to be_a Hash
        expect(data[:x]).to eq "foo"
      end

      it "converts guarded value" do
        expect(subject.new(:x)).to eq :bar
      end
    end

    context "with a proc:" do
      subject do
        described_class[proc(&:to_i)].guard(->(v) { v.to_s == "x" }, as: :bar)
      end

      it "is transient when value not guarded" do
        expect(subject.new "42").to eq 42
      end

      it "converts guarded value" do
        expect(subject.new(:x)).to eq :bar
      end
    end
  end
end
