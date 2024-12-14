class HomeController < ApplicationController
    require 'open3'

    def index
      # This is for the form
    end
  
    def convert
      youtube_url = params[:youtube_url]
  
      if youtube_url.present?
        mp3_file_path = convert_youtube_to_mp3(youtube_url)
  
        send_file(mp3_file_path, filename: 'video.mp3', type: 'audio/mp3')
      else
        flash[:error] = "Please provide a valid YouTube URL."
        redirect_to action: :index
      end
    end
  
    private
  
    def convert_youtube_to_mp3(youtube_url)
        # Define a directory for saving the MP3 file
        temp_dir = Rails.root.join('tmp', 'downloads')
        FileUtils.mkdir_p(temp_dir) unless Dir.exist?(temp_dir)
      
        # Path for the MP3 file
        mp3_file_path = temp_dir.join('video.mp3')
      
        # Run yt-dlp to download and convert to MP3
        command = "yt-dlp -x --audio-format mp3 -o '#{mp3_file_path}' #{youtube_url}"
      
        stdout, stderr, status = Open3.capture3(command)
      
        if status.success?
          return mp3_file_path
        else
          raise "Failed to convert video: #{stderr}"
        end
    end
end
