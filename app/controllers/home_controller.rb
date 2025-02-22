class HomeController < ApplicationController
  require "open3"
  require "fileutils"
  require "securerandom"
  require "zip"

  def index
    logger.info("HomeController Loaded")
  end

  def convert
    youtube_urls = params[:youtube_urls]

    if youtube_urls.blank?
      render json: { error: "No URLs provided" }, status: :unprocessable_entity and return
    end

    # Clean up URLs (remove extra query parameters)
    youtube_urls.map! { |url| sanitize_youtube_url(url) }.compact

    converted_files = []
    errors = []

    # Process videos in parallel using threads
    threads = youtube_urls.map do |url|
      Thread.new do
        begin
          converted_files << convert_youtube_to_mp3(url)
        rescue => e
          errors << "Error processing #{url}: #{e.message}"
        end
      end
    end

    threads.each(&:join)

    if errors.any?
      cleanup_files(converted_files)
      render json: { error: errors.join(", ") }, status: :unprocessable_entity and return
    end

    if converted_files.size == 1
      send_file converted_files.first, filename: "video.mp3", type: "audio/mp3"
    else
      zip_path = create_zip(converted_files)
      send_file zip_path, filename: "videos.zip", type: "application/zip"
    end
  end

  private

  def sanitize_youtube_url(url)
    uri = URI.parse(url)
    "#{uri.scheme}://#{uri.host}#{uri.path}" # Removes unnecessary query parameters
  rescue URI::InvalidURIError
    nil
  end

  def convert_youtube_to_mp3(youtube_url)
    temp_dir = Rails.root.join("tmp", "downloads")
    FileUtils.mkdir_p(temp_dir) unless Dir.exist?(temp_dir)
    unique_id = SecureRandom.hex(8)
    output_template = temp_dir.join("video_#{unique_id}.%(ext)s").to_s

    retries = 3
    begin
      command = [
        "/app/venv/bin/yt-dlp",
        "--cookies", "/app/cookies.txt",  # Use YouTube cookies
        "--user-agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
        "--extractor-args", "youtube:player_client=android",  # Bypass bot detection
        "-x",
        "--audio-format", "mp3",
        "-o", output_template,
        youtube_url
      ]

      stdout, stderr, status = Open3.capture3(*command)

      Rails.logger.info "yt-dlp STDOUT: #{stdout}"
      Rails.logger.error "yt-dlp STDERR: #{stderr}" unless status.success?

      unless status.success?
        raise "Failed to convert video: #{stderr}"
      end

      # Look for the generated MP3 file
      mp3_file_path = Dir.glob("#{temp_dir}/video_#{unique_id}.*").find { |f| f.end_with?(".mp3") }

      unless mp3_file_path
        Rails.logger.error "MP3 file was not created. Available files: #{Dir.glob("#{temp_dir}/video_#{unique_id}.*")}"
        raise "MP3 file was not created."
      end

      Rails.logger.info "MP3 file created: #{mp3_file_path}"
      mp3_file_path

    rescue => e
      retries -= 1
      if retries > 0
        Rails.logger.warn "Retrying due to error: #{e.message}"
        sleep(3)
        retry
      else
        raise "Failed after multiple attempts: #{e.message}"
      end
    end
  end

  def create_zip(file_paths)
    temp_dir = Rails.root.join("tmp", "downloads")
    zip_path = temp_dir.join("videos_#{Time.now.to_i}.zip")
    Zip::File.open(zip_path, Zip::File::CREATE) do |zipfile|
      file_paths.each_with_index do |file, index|
        zipfile.add("video#{index+1}.mp3", file)
      end
    end
    zip_path
  end

  def cleanup_files(file_paths)
    file_paths.each do |file|
      File.delete(file) if File.exist?(file)
    end
  end
end
