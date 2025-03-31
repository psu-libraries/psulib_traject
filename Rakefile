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

desc 'Download MARC records from codes in a text file to solr/sample_data/'
task :download_marc_files, [:file_path] do |_t, args|
  file_path = args[:file_path]
  
  unless file_path && File.exist?(file_path)
    puts "Error: Please provide a valid file path containing codes"
    puts "Usage: rake download_marc_files[path/to/codes.txt]"
    exit 1
  end
  
  # Ensure the target directory exists
  target_dir = 'solr/sample_data'
  FileUtils.mkdir_p(target_dir)
  
  puts "Downloading MARC records from codes in #{file_path}..."
  
  File.readlines(file_path).each_with_index do |code, index|
    code = code.strip
    next if code.empty? || code.start_with?('#')
    
    begin
      puts "Downloading #{code}..."
      
      filename = "#{code}.marc"
      
      # Download the file
      URI.open("https://catalog.libraries.psu.edu/catalog/#{code}.marc") do |remote_file|
        File.open(File.join(target_dir, filename), 'wb') do |local_file|
          local_file.write(remote_file.read)
        end
      end
      
      puts "Successfully downloaded to #{target_dir}/#{filename}"
    rescue StandardError => e
      puts "Error downloading #{code}: #{e.message}"
    end
  end
  
  puts "Download process completed."
end

desc 'Import downloaded MARC records from codes in a text file using traject'
task :import_marc_files, [:file_path] do |_t, args|
  file_path = args[:file_path]
  
  unless file_path && File.exist?(file_path)
    puts "Error: Please provide a valid file path containing codes"
    puts "Usage: rake import_marc_files[path/to/codes.txt]"
    exit 1
  end
  
  target_dir = 'solr/sample_data'
  
  puts "Importing MARC records from codes in #{file_path}..."
  
  File.readlines(file_path).each do |code|
    code = code.strip
    next if code.empty? || code.start_with?('#')
    
    begin
      filename = "#{code}.marc"
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
      puts "Error importing #{code}: #{e.message}"
    end
  end
  
  puts "Import process completed."
end
