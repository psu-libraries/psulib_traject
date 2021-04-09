# frozen_string_literal: true

RSpec.describe "Formats spec:" do
  before(:all) do
    c = "./lib/traject/psulib_config.rb"
    @indexer = Traject::Indexer.new
    @indexer.load_config_file(c)
  end

  describe "process_formats" do
    let(:fixture_path) { "./spec/fixtures" }

    it "works with empty record, returns format as Other" do
      @empty_record = MARC::Record.new
      @empty_record.append(MARC::ControlField.new("001", "000000000"))
      result = @indexer.map_record(@empty_record)
      expect(result["format"]).to contain_exactly "Other"
    end

    it "correctly sets formats when record has no 008" do
      result = @indexer.map_record(MARC::Reader.new(File.join(fixture_path, "format_no_008.mrc")).to_a.first)
      expect(result["format"]).to contain_exactly "Book"
    end

    it "correctly sets format for multiple 949s" do
      result = @indexer.map_record(MARC::Reader.new(File.join(fixture_path, "format_949t_juvenile_book.mrc")).to_a.first)
      expect(result["format"]).to contain_exactly "Instructional Material", "Juvenile Book"
    end

    it "prefers format as Statute by checking 949t over Government Document" do
      result = @indexer.map_record(MARC::Reader.new(File.join(fixture_path, "format_949t_statute.mrc")).to_a.first)
      expect(result["format"]).to contain_exactly "Statute"
    end

    it "correctly sets format as Instructional Material from 006" do
      result = @indexer.map_record(MARC::Reader.new(File.join(fixture_path, "format_006_instructional_material.mrc")).to_a.first)
      expect(result["format"]).to contain_exactly "Instructional Material"
    end

    it "correctly sets format as Government Document" do
      result = @indexer.map_record(MARC::Reader.new(File.join(fixture_path, "format_gov_doc.mrc")).to_a.first)
      expect(result["format"]).to contain_exactly "Government Document"
    end

    it 'correctly sets format as Book if 260b or 264b contain variations of "University Press"' do
      result = @indexer.map_record(MARC::Reader.new(File.join(fixture_path, "format_university_press.mrc")).to_a.first)
      expect(result["format"]).to contain_exactly "Book"
    end

    it "correctly sets formats checking leader byte 6 and byte 7" do
      result = @indexer.map_record(MARC::Reader.new(File.join(fixture_path, "format_article.mrc")).to_a.first)
      expect(result["format"]).to contain_exactly "Article"

      result = @indexer.map_record(MARC::Reader.new(File.join(fixture_path, "format_leader6_book.mrc")).to_a.first)
      expect(result["format"]).to contain_exactly "Book"

      result = @indexer.map_record(MARC::Reader.new(File.join(fixture_path, "format_leader6_book_override.mrc")).to_a.first)
      expect(result["format"]).to contain_exactly "Book"

      result = @indexer.map_record(MARC::Reader.new(File.join(fixture_path, "format_leader6_video.mrc")).to_a.first)
      expect(result["format"]).to contain_exactly "Video"

      result = @indexer.map_record(MARC::Reader.new(File.join(fixture_path, "format_leader6_thesis.mrc")).to_a.first)
      expect(result["format"]).to contain_exactly "Thesis/Dissertation"

      result = @indexer.map_record(MARC::Reader.new(File.join(fixture_path, "format_leader6_archives.mrc")).to_a.first)
      expect(result["format"]).to contain_exactly "Archives/Manuscripts"
    end

    it "correctly sets 007 formats" do
      result = @indexer.map_record(MARC::Reader.new(File.join(fixture_path, "format_007_maps.mrc")).to_a.first)
      expect(result["format"]).to contain_exactly "Maps, Atlases, Globes", "Musical Score"
    end

    it "correctly sets format as Thesis/Dissertation if the record has a 502" do
      result = @indexer.map_record(MARC::Reader.new(File.join(fixture_path, "format_502_thesis.mrc")).to_a.first)
      expect(result["format"]).to contain_exactly "Thesis/Dissertation"
    end

    it "correctly sets format as Newspaper" do
      result = @indexer.map_record(MARC::Reader.new(File.join(fixture_path, "format_newspaper.mrc")).to_a.first)
      expect(result["format"]).to contain_exactly "Newspaper"
    end

    it "correctly sets format as Games/Toys from 006" do
      result = @indexer.map_record(MARC::Reader.new(File.join(fixture_path, "format_006_games.mrc")).to_a.first)
      expect(result["format"]).to contain_exactly "Games/Toys"
    end

    it "correctly sets format as Games/Toys from 008" do
      result = @indexer.map_record(MARC::Reader.new(File.join(fixture_path, "format_games.mrc")).to_a.first)
      expect(result["format"]).to contain_exactly "Games/Toys"
    end

    it "correctly sets format as Proceeding/Congress" do
      result = @indexer.map_record(MARC::Reader.new(File.join(fixture_path, "format_proceeding.mrc")).to_a.first)
      expect(result["format"]).to contain_exactly "Proceeding/Congress"
    end

    it "correctly sets format as Proceeding/Congress from $6xx" do
      result = @indexer.map_record(MARC::Reader.new(File.join(fixture_path, "format_congress.mrc")).to_a.first)
      expect(result["format"]).to contain_exactly "Proceeding/Congress"
    end

    it "correctly sets format as Other when no other format found" do
      result = @indexer.map_record(MARC::Reader.new(File.join(fixture_path, "format_other.mrc")).to_a.first)
      expect(result["format"]).to contain_exactly "Other"
    end
  end
end
