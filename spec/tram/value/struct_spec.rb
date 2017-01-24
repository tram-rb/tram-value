RSpec.describe Tram::Value::Struct do
  before do
    class Test::User < Tram::Value::Struct
      attribute :first_name
      attribute :second_name
      attribute :email
      attribute :phone

      examiner do
        validates :first_name, :second_name, presence: true
      end
    end
  end

  let(:source) do
    {
      first_name:  "Joe",
      second_name: "Doe",
      email:       "joe@example.com",
      phone:       "12345678"
    }
  end

  describe ".attributes" do
    subject { Test::User.attributes }

    it { is_expected.to eq %i(first_name second_name email phone) }
  end

  describe ".load" do
    subject { Test::User.load source }

    it { is_expected.to eq Test::User[source] }
  end

  describe ".dump" do
    subject { Test::User.dump Test::User[source] }

    it { is_expected.to eql source }
  end

  describe ".list" do
    subject { Test::User.list[[source]] }

    it { is_expected.to contain_exactly Test::User[source] }
  end

  describe ".maybe" do
    subject { Test::User.maybe[source] }

    context "with non-nil argument" do
      it { is_expected.to eq Test::User[source] }
      it { is_expected.not_to be_nil }
    end

    context "with nil argument" do
      let(:source) { nil }

      it { is_expected.to be_nil }
    end
  end

  describe ".either_present_or" do
    subject { Test::User.either_present_or("xxx")[source] }

    context "with present argument" do
      it { is_expected.to eq Test::User[source] }
    end

    context "with blank argument" do
      let(:source) { "" }
      it { is_expected.to eq "xxx" }
    end
  end

  describe ".guard" do
    subject { Test::User.guard("xxx", as: "zzz")[source] }

    context "with non-guarded argument" do
      it { is_expected.to eq Test::User[source] }
    end

    context "with guarded argument" do
      let(:source) { "xxx" }
      it { is_expected.to eq "zzz" }
    end
  end

  describe ".valid" do
    subject { Test::User.valid[source] }

    context "with valid data" do
      it { is_expected.to eq Test::User[source] }
    end

    context "with invalid data" do
      before { source.delete :first_name }

      it "raises" do
        expect { subject }.to raise_error ActiveModel::ValidationError, /blank/
      end
    end
  end

  describe "#==" do
    subject { Test::User[source] }

    it { is_expected.to eq source }
  end

  describe "#eql?" do
    subject { Test::User[source] }

    it { is_expected.to be_eql Test::User[source] }
    it { is_expected.not_to be_eql source }
  end

  describe "dumpers" do
    subject { Test::User[source] }

    its(:call)    { is_expected.to eq source }
    its(:to_h)    { is_expected.to eq source }
    its(:to_hash) { is_expected.to eq source }

    context "when some attributes not defined" do
      before { source.delete :phone }

      its(:call) { is_expected.to eq source }
    end

    context "when some attributes are set to nil" do
      before { source[:phone] = nil }

      its(:call) { is_expected.to eq source }
    end
  end

  describe "attributes" do
    subject { Test::User[source] }

    its(:first_name) { is_expected.to eq "Joe" }
    its(:second_name) { is_expected.to eq "Doe" }
    its(:email) { is_expected.to eq "joe@example.com" }
    its(:phone) { is_expected.to eq "12345678" }
  end

  describe "#[]" do
    subject { Test::User[source] }

    it "extrcats attributes" do
      expect(subject[:first_name]).to eq "Joe"
      expect(subject[:second_name]).to eq "Doe"
      expect(subject[:email]).to eq "joe@example.com"
      expect(subject[:phone]).to eq "12345678"
    end
  end

  describe "validator" do
    subject { Test::User[source] }

    it { is_expected.to be_valid }
    its(:errors) { is_expected.to be_empty }

    context "when validation fails" do
      before { source[:second_name] = "" }

      it { is_expected.not_to be_valid }
      its(:errors) { is_expected.not_to be_empty }
    end
  end
end
