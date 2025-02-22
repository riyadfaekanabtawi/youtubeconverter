class HomeController < ApplicationController
  require "open3"
  require "fileutils"
  require "securerandom"
  require "zip"  # Ensure the rubyzip gem is installed

  def index
    logger.info("aaaaaa")
  end

  def convert
    youtube_urls = params[:youtube_urls]
    if youtube_urls.blank?
      render json: { error: "No URLs provided" }, status: :unprocessable_entity and return
    end

    converted_files = []
    youtube_urls.each do |url|
      begin
        converted_files << convert_youtube_to_mp3(url)
      rescue => e
        cleanup_files(converted_files)
        render json: { error: "Conversion error: #{e.message}" }, status: :unprocessable_entity and return
      end
    end

    if converted_files.size == 1
      send_file converted_files.first, filename: "video.mp3", type: "audio/mp3"
    else
      zip_path = create_zip(converted_files)
      send_file zip_path, filename: "videos.zip", type: "application/zip"
    end
  end

  private

  def convert_youtube_to_mp3(youtube_url)
    temp_dir = Rails.root.join("tmp", "downloads")
    FileUtils.mkdir_p(temp_dir) unless Dir.exist?(temp_dir)
    unique_id = SecureRandom.hex(8)
  
    # Get the direct audio URL without downloading
    command = [
      "yt-dlp",
      "--get-url",   # This extracts the direct media URL
      "-f", "bestaudio",  # Fetch the best available audio format
      youtube_url
    ]
  
    stdout, stderr, status = Open3.capture3(*command)
  
    if status.success?
      audio_url = stdout.strip
      Rails.logger.info "Extracted Audio URL: #{audio_url}"
  
      # Redirect user to the direct YouTube media URL (avoiding download)
      return redirect_to audio_url
    else
      raise "Failed to extract media URL: #{stderr}"
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
