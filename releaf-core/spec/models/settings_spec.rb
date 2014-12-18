require "spec_helper"

describe Releaf::Settings do
  describe "#to_text" do
    it "returns var value" do
      subject.var = "x"
      expect(subject.to_text).to eq("x")
    end
  end

  describe ".store_defaults" do
    before do
      described_class.destroy_all
    end

    it "merge given values to model @@defaults hash" do
      old_defaults = Releaf::Settings.defaults
      Releaf::Settings.defaults = {}

      allow(described_class).to receive(:table_exists?).and_return(false)
      expect{ described_class.store_defaults("key.a" => "1", "key.b" => 2) }
        .to change{ described_class.defaults  }.to("key.a" => "1", "key.b" => 2)
      expect{ described_class.store_defaults("key.b" => "3", "key.c" => 2) }
        .to change{ described_class.defaults  }.to("key.a" => "1", "key.b" => "3", "key.c" => 2)

      Releaf::Settings.defaults = old_defaults
    end

    it "creates default values to database for unexisting records" do
      expect{ described_class.store_defaults("key.a" => "1", "key.b" => 2) }.to change{ described_class.count  }.by(2)
      expect(described_class["key.a"]).to eq("1")
      expect(described_class["key.b"]).to eq(2)
    end

    it "does not change existing values" do
      described_class["key.b"] = 3

      expect{ described_class.store_defaults("key.a" => "1", "key.b" => 2) }.to change{ described_class.count  }.by(1)
      expect(described_class["key.a"]).to eq("1")
      expect(described_class["key.b"]).to eq(3)
    end

    context "when database table does not exists" do
      it "does nothing" do
        allow(described_class).to receive(:table_exists?).and_return(false)
        expect{ described_class.store_defaults("key.a" => "1", "key.b" => 2) }.to_not change{ described_class.count  }
      end
    end
  end
end
