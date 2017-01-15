RSpec.describe Tram::Value::String do
  before do
    class Test::Foo < Tram::Value::String
      let(:call) { source.to_s.reverse }

      def palindrome?
        source == call
      end

      examiner do
        validates :palindrome, acceptance: true
      end
    end
  end

  describe ".load" do
    subject { Test::Foo.load "bar" }

    it { is_expected.to eq Test::Foo["bar"] }
  end

  describe ".dump" do
    subject { Test::Foo.dump Test::Foo["rab"] }

    it { is_expected.to eql "bar" }
  end

  describe ".list" do
    subject { Test::Foo.list[%w(bar)] }

    it { is_expected.to contain_exactly Test::Foo["bar"] }
  end

  describe ".maybe" do
    subject { Test::Foo.maybe[source] }

    context "with non-nil argument" do
      let(:source) { :foo }

      it { is_expected.to eq Test::Foo[:foo] }
      it { is_expected.not_to be_nil }
    end

    context "with nil argument" do
      let(:source) { nil }

      it { is_expected.to be_nil }
    end
  end

  describe ".either_present_or" do
    subject { Test::Foo.either_present_or("xxx")[source] }

    context "with present argument" do
      let(:source) { "yyy" }
      it { is_expected.to eq Test::Foo["yyy"] }
    end

    context "with blank argument" do
      let(:source) { "" }
      it { is_expected.to eq "xxx" }
    end
  end

  describe ".guard" do
    subject { Test::Foo.guard("xxx", as: "zzz")[source] }

    context "with non-guarded argument" do
      let(:source) { "yyy" }
      it { is_expected.to eq Test::Foo["yyy"] }
    end

    context "with guarded argument" do
      let(:source) { "xxx" }
      it { is_expected.to eq "zzz" }
    end
  end

  describe "#==" do
    subject { Test::Foo[:barbaz] }

    it { is_expected.to eq "zabrab" }
    it { is_expected.to eq :zabrab }
    it { is_expected.not_to eq "rabzab" }
  end

  it "is comparable" do
    expect(Test::Foo[:barbaz] > double(to_s: "zabraa")).to eq true
    expect(Test::Foo[:barbaz] < double(to_s: "zabrac")).to eq true
  end

  describe "custom instance method" do
    subject { Test::Foo[:barbaz] }

    it { is_expected.not_to be_palindrome }
  end

  describe "source" do
    subject { Test::Foo[:barbaz] }

    its(:source) { is_expected.to eq :barbaz }
  end

  describe "dumpers" do
    subject { Test::Foo[:barbaz] }

    its(:call)   { is_expected.to eq "zabrab" }
    its(:to_s)   { is_expected.to eq "zabrab" }
    its(:to_str) { is_expected.to eq "zabrab" }
  end

  describe "validator" do
    subject { Test::Foo[:barbaz] }

    it { is_expected.to be_valid }
  end
end
