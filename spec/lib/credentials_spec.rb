# frozen_string_literal: true

RSpec.describe Komtet::Credentials do

  subject{
    described_class.new(
      shop_id: "soMeShOp",
      signature_key: "verySecrEt",
      queue_id: 1234,
    )
  }


  describe "Serialization" do
    let(:key_pass){
      '12345678' * 4 # need 32 bytes
    }

    it "to_hash and back" do
      restored = described_class.from_hash(
        subject.to_hash(key_pass:key_pass),
        key_pass:key_pass
      )

      expect(restored.shop_id).to eq(subject.shop_id)
      expect(restored.queue_id).to eq(subject.queue_id)
      expect(restored.signature_key).to eq(subject.signature_key)
    end

    context "wrong key_pass" do
      it "raises" do
        encoded = subject.to_hash(key_pass:key_pass)

        # simulate the 1/256 chanse:
        expect_any_instance_of(OpenSSL::Cipher).to receive(:final){"invalid_data_here"}

        expect{
          described_class.from_hash(encoded, key_pass: "wrong123"*4)
        }.to raise_error(/bad decrypt/)
      end
    end
  end

  describe "signature" do
    it "works" do
      expect(subject.signature_key).to eq "verySecrEt" # just in case
      expect(subject.signature("POST", "http://example.org/some/url", "body_here")).to eq '78dcc39222e66ad97eee2fd30a39c14d'
    end
  end

end