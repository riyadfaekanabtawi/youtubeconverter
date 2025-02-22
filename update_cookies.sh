#!/bin/bash

# Export new cookies from your browser
yt-dlp --cookies-from-browser chrome --dump-user-agent --cookies cookies.txt

# Copy cookies to the server
scp cookies.txt ubuntu@your-server-ip:/home/ubuntu/

# SSH into the server and update cookies inside Docker
ssh ubuntu@your-server-ip << EOF
  docker cp /home/ubuntu/cookies.txt youtubeconvert-web-1:/app/cookies.txt
EOF

echo "✅ YouTube cookies updated successfully!"
