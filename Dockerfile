# Use an Ubuntu-based Ruby image
FROM ruby:3.3.5

# Install system dependencies
RUN apt-get update -qq && apt-get install -y \
  sudo \
  build-essential \
  nodejs \
  yarn \
  sqlite3 \
  libsqlite3-dev \
  ffmpeg \
  python3 \
  python3-pip \
  python3-venv \
  && rm -rf /var/lib/apt/lists/*

# Set up a Python virtual environment for yt-dlp
RUN python3 -m venv /app/venv && \
    /app/venv/bin/pip install -U pip yt-dlp && \
    ln -s /app/venv/bin/yt-dlp /usr/local/bin/yt-dlp

# Set working directory
WORKDIR /app

# Copy Gemfile and Gemfile.lock
COPY Gemfile Gemfile.lock ./

# Install gems
RUN bundle install --jobs 4 --retry 5

# Copy the entire app
COPY . .

# Ensure the SQLite database exists
RUN mkdir -p tmp/db && touch tmp/db/development.sqlite3

# Precompile assets (if necessary)
RUN bundle exec rake assets:precompile

# Expose port
EXPOSE 3000

# Command to start the app
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
