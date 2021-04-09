# frozen_string_literal: true

RSpec::Matchers.define_negated_matcher :not_include, :include

RSpec.describe "Title spec:" do
  let(:leader) { "1234567890" }

  before(:all) do
    c = "./lib/traject/psulib_config.rb"
    @indexer = Traject::Indexer.new
    @indexer.load_config_file(c)
  end

  describe "Record with a vernacular title" do
    let(:field) { "title_display_ssm" }
    let(:subfield) { "title_latin_display_ssm" }
    let(:title_245) do
      {"245" => {"ind1" => "1", "ind2" => "0", "subfields" => [{"6" => "880-02"},
        {"a" => "Shōsetsu wandafuru raifu /"},
        {"c" => "Koreeda Hirokazu"}]}}
    end
    let(:title_vern_245) do
      {"880" => {"ind1" => "1", "ind2" => "0", "subfields" => [{"6" => "245-02"},
        {"a" => "小說ワンダフルライフ /"},
        {"c" => "是枝裕和."}]}}
    end
    let(:result) { @indexer.map_record(MARC::Record.new_from_hash("fields" => [title_245, title_vern_245], "leader" => leader)) }

    it "has the vernacular title as the title statement" do
      expect(result[field]).to eq ["小說ワンダフルライフ / 是枝裕和"]
      expect(result[field].length).to eq 1
    end

    it "has a latin title as the sub-title" do
      expect(result[subfield]).to eq ["Shōsetsu wandafuru raifu / Koreeda Hirokazu"]
      expect(result[subfield].length).to eq 1
    end

    it "has empty vern title field" do
      expect(result).not_to include("title_vern")
    end
  end

  describe "Record with no vernacular title" do
    let(:field) { "title_display_ssm" }
    let(:subfield) { "title_latin_display_ssm" }
    let(:title_245) do
      {"245" => {"ind1" => "1", "ind2" => "3", "subfields" => [{"a" => "La ressemblance :"},
        {"b" => "suivi de la feintise, Jeff Edmunds /"},
        {"c" => "Jean Lahougue, Jeff Edmunds"}]}}
    end
    let(:result) { @indexer.map_record(MARC::Record.new_from_hash("fields" => [title_245], "leader" => leader)) }

    it "has the latin title as the title statement" do
      expect(result[field]).to eq ["La ressemblance : suivi de la feintise, Jeff Edmunds / Jean Lahougue, Jeff Edmunds"]
      expect(result[field].length).to eq 1
    end

    it "has no latin title as the sub-title" do
      expect(result).not_to include(subfield)
    end

    it "has empty vern title field" do
      expect(result).not_to include("title_vern")
    end
  end

  describe "Related titles from 505t" do
    let(:field) { "title_related_tsim" }
    let(:fields) do
      {"505" => {"ind1" => 0, "ind2" => 0, "subfields" => [{"t" => "US, EU and global competition law development --"},
        {"t" => "International organizations and competition law : diverging rationale? --"},
        {"t" => "Market governance in China --"}]}}
    end
    let(:result) { @indexer.map_record(MARC::Record.new_from_hash("fields" => [fields], "leader" => leader)) }

    it "returns with trailing -- chomped" do
      expect(result[field]).not_to eq nil
      expect(result[field]).to(all(not_include(" --")))
    end
  end
end
