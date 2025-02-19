class HomeController < ApplicationController
  require 'open3'
  require 'fileutils'

  def index
    # This action renders the form for entering a YouTube URL
  end

  def convert
    youtube_url = params[:youtube_url]

    if youtube_url.present?
      begin
        mp3_file_path = convert_youtube_to_mp3(youtube_url)
        send_file(mp3_file_path, filename: 'video.mp3', type: 'audio/mp3')
      rescue => e
        flash[:error] = "Conversion error: #{e.message}"
        redirect_to action: :index
      end
    else
      flash[:error] = "Please provide a valid YouTube URL."
      redirect_to action: :index
    end
  end

  private

  def convert_youtube_to_mp3(youtube_url)
    # Define the temporary directory for downloads and ensure it exists
    temp_dir = Rails.root.join('tmp', 'downloads')
    FileUtils.mkdir_p(temp_dir) unless Dir.exist?(temp_dir)

    # Use a template so that yt-dlp substitutes the extension correctly.
    # The final file should be named "video.mp3".
    output_template = temp_dir.join('video.%(ext)s').to_s

    # Build the yt-dlp command as an array to avoid shell issues.
    command = [
      "yt-dlp",
      "-x",
      "--audio-format", "mp3",
      "-o", output_template,
      youtube_url
    ]

    stdout, stderr, status = Open3.capture3(*command)

    unless status.success?
      raise "Failed to convert video: #{stderr}"
    end

    # Find the generated MP3 file. It should be named "video.mp3" if yt-dlp
    # replaced %(ext)s with "mp3". If not, try to locate the file manually.
    mp3_file_path = temp_dir.join('video.mp3')
    unless File.exist?(mp3_file_path)
      files = Dir.glob(temp_dir.join("video.*")).select { |f| f.end_with?(".mp3") }
      if files.any?
        mp3_file_path = files.first
      else
        raise "MP3 file was not created."
      end
    end

    mp3_file_path
  end
end
