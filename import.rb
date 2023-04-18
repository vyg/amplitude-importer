require 'rubygems'
require 'bundler/setup'
require 'logger'
require 'json'
require 'zlib'
require 'httparty'

unless ENV['API_KEY']
  abort 'Must set API_KEY'
end

class AmplitudeImporter
  API_KEY = ENV['API_KEY'].freeze
  ENDPOINT = 'https://api2.amplitude.com/batch'.freeze
  PROGRESS_FILE_PATH = 'progress.txt'.freeze
  RATE_LIMIT = 1000

  def read_and_merge_events(file_path)
      logger.info "Processing #{file_path}"

      # Create an array to hold the events
      events = []

      # Read the gzipped file
      json_data = Zlib::GzipReader.open(file_path)
      
      # Parse each line of the file as JSON and add it to the events array
      json_data.each_line do |line|
        begin
          events << JSON.parse(line)
        rescue JSON::ParserError => e
          logger.error "Error parsing JSON: #{e}"
        end
      end

      events
  end

  def send_events_to_amplitude(events)
      # Divide the events into batches of 100
      batches = events.each_slice(1000).to_a

      start_time = Time.now

      batches.each do |event_batch|
        # Wait if needed to comply with Amplitude's rate limit
        elapsed_time = Time.now - start_time
        if elapsed_time < 1
          sleep(1 - elapsed_time)
        end

        # Bulk upload the events object to Amplitude's endpoint
        body = {
            api_key: API_KEY,
            events: event_batch,
            options: {
              min_id_length: 0,
            }
          }.to_json

        response = HTTParty.post(
          ENDPOINT, 
          headers: {
            'Content-Type' => 'application/json'
          },
          body: body
        )

        # Check the response status and handle accordingly
        if response.code.to_i == 200
          logger.info "Submitted batch of #{event_batch.length} events (#{events.length} total) successfully"
        else
          logger.info "Failed to upload events: #{response.code} - #{response.message}"

          # Log error details
          puts "Error Body: #{response.body}"
        end

        # Update start time for next rate limit check
        start_time = Time.now
      end
  end

  def run(directory)
    submitted_count = 0
    failed_count = 0

    # Load progress from progress file
    processed_files = File.read(PROGRESS_FILE_PATH).split("\n").map(&:strip).select { |line| line != "" }.map { |line| line.split("\t")[1] }

    files = Dir.glob("#{directory}/**/*.gz")

    logger.info "Processing #{files.length} files"

    files.each do |file_path|
      next if processed_files.include?(file_path) # Skip files that were already processed

      # Read the events from the file
      events = read_and_merge_events(file_path)
      success = send_events_to_amplitude(events)

      if success
        processed_files << file_path
        File.write(PROGRESS_FILE_PATH, "#{File.size(file_path)}\t#{file_path}\n", mode: 'a')
        submitted_count += events.length
      else
        failed_count += events.length
        # If upload fails, stop processing files to avoid duplicate events
        break
      end
    end

    logger.info "Submitted #{submitted_count} events"
    logger.info "Failed to submit #{failed_count} events"
    logger.info "Check the log for more details"
  end

  private

  def logger
    @logger ||= Logger.new(STDERR)
  end
end

AmplitudeImporter.new.run(ARGV[0])