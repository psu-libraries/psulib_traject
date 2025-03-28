# frozen_string_literal: true

require 'open-uri'
require 'fileutils'

$LOAD_PATH.prepend(Pathname.pwd.join('lib').to_s)
ENV['RUBY_ENVIRONMENT'] ||= 'dev'
require 'psulib_traject'

Dir.glob('lib/tasks/*.rake').each { |r| load r }

require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task default: :spec

desc 'Import MARC records from URLs in a text file to solr/sample_data/'
task :import_marc_files, [:file_path] do |_t, args|
  file_path = args[:file_path]
  
  unless file_path && File.exist?(file_path)
    puts "Error: Please provide a valid file path containing URLs"
    puts "Usage: rake download_marc_records[path/to/urls.txt]"
    exit 1
  end
  
  # Ensure the target directory exists
  target_dir = 'solr/sample_data'
  FileUtils.mkdir_p(target_dir)
  
  puts "Downloading MARC records from URLs in #{file_path}..."
  
  File.readlines(file_path).each_with_index do |url, index|
    url = url.strip
    next if url.empty? || url.start_with?('#')
    
    begin
      puts "Downloading #{url}..."
      
      # Extract filename from URL or use a default with index
      filename = File.basename(url)
      filename = "marc_record_#{index + 1}.marc" if filename.empty? || filename == url
      
      # Download the file
      URI.open("https://catalog.libraries.psu.edu/catalog/#{url}.marc") do |remote_file|
        File.open(File.join(target_dir, filename), 'wb') do |local_file|
          local_file.write(remote_file.read)
        end
      end
      
      puts "Successfully downloaded to #{target_dir}/#{filename}"

      # Process the downloaded file with traject
      marc_file_path = File.join(target_dir, filename)
      if File.exist?(marc_file_path)
        puts "Processing #{marc_file_path} with traject..."
        traject_command = "bundle exec traject -c config/traject.rb #{marc_file_path}"
        
        traject_result = system(traject_command)
        if traject_result
          puts "Successfully processed #{filename} with traject"
        else
          puts "Error processing #{filename} with traject (exit code: #{$?.exitstatus})"
        end
      else
        puts "Cannot process with traject: File #{marc_file_path} not found"
      end
    rescue StandardError => e
      puts "Error downloading #{url}: #{e.message}"
    end
  end
  
  puts "Download process completed."
end
