# YoutubeConverter - Automated Deployment with Docker & GitHub Actions

## 📌 Project Overview
This repository contains a **Ruby on Rails 8** web application using **SQLite** as its database. The project is containerized with **Docker** and deployed automatically to an **AWS EC2 instance** using **GitHub Actions**.

---

## 🚀 Setup & Installation

### 1️⃣ **Clone the Repository**
```sh
git clone https://github.com/YOUR_GITHUB_USERNAME/youtubeconverter.git
cd youtubeconverter
```

### 2️⃣ **Set Up Environment Variables** (Optional)
If your application requires environment variables, create a `.env` file:
```sh
touch .env
```
And add your required variables.

### 3️⃣ **Build & Run with Docker (Local)**
```sh
docker build -t youtubeconverter .
docker run -p 3000:3000 youtubeconverter
```
Your app should now be accessible at `http://localhost:3000`.

---

## 🛠 Docker Deployment to AWS EC2

### 1️⃣ **Connect to EC2 via SSH**
```sh
ssh -i tienditapp.pem ubuntu@YOUR_EC2_PUBLIC_IP
```

### 2️⃣ **Pull the Latest Docker Image & Restart**
```sh
docker pull YOUR_DOCKER_HUB_USERNAME/youtubeconverter:latest
docker stop youtubeconvert-web-1 || true
docker rm youtubeconvert-web-1 || true
docker run -d -p 80:3000 --name youtubeconvert-web-1 --restart always YOUR_DOCKER_HUB_USERNAME/youtubeconverter:latest
```
Your app should now be accessible at `http://YOUR_EC2_PUBLIC_IP`.

---

## 🤖 CI/CD: GitHub Actions Workflow
The project includes **automatic deployment** using **GitHub Actions**.

### 1️⃣ **Store the `.pem` Key in GitHub Secrets**
1. Open `tienditapp.pem` and **copy the entire content**.
2. Go to **GitHub → Repository → Settings → Secrets**.
3. Create a new secret: `EC2_SSH_PEM`.
4. Paste the full `.pem` key and save it.

### 2️⃣ **GitHub Actions Workflow (`.github/workflows/deploy.yml`)**
Every push to `main` triggers an **automated build and deployment**:
```yaml
name: Deploy to EC2
on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Save Private Key to File
        run: |
          echo "${{ secrets.EC2_SSH_PEM }}" > ~/tienditapp.pem
          chmod 600 ~/tienditapp.pem

      - name: Test SSH Connection
        run: |
          ssh -i ~/tienditapp.pem -o StrictHostKeyChecking=no ubuntu@${{ secrets.EC2_HOST }} "echo '✅ Connected successfully'"

      - name: Log in to Docker Hub
        run: |
          echo "${{ secrets.DOCKER_PASSWORD }}" | docker login -u "${{ secrets.DOCKER_USERNAME }}" --password-stdin

      - name: Build & Push Docker Image
        run: |
          docker buildx build --platform linux/amd64 -t ${{ secrets.DOCKER_USERNAME }}/youtubeconverter:latest .
          docker push ${{ secrets.DOCKER_USERNAME }}/youtubeconverter:latest

      - name: Deploy to EC2
        uses: appleboy/ssh-action@master
        with:
          host: ${{ secrets.EC2_HOST }}
          username: ubuntu
          key: ${{ secrets.EC2_SSH_PEM }}
          script: |
            docker stop youtubeconvert-web-1 || true
            docker rm youtubeconvert-web-1 || true
            docker pull ${{ secrets.DOCKER_USERNAME }}/youtubeconverter:latest
            docker run -d -p 80:3000 --name youtubeconvert-web-1 --restart always ${{ secrets.DOCKER_USERNAME }}/youtubeconverter:latest
```
---

## 🔥 How to Trigger a New Deployment
To trigger an automatic deployment, **push any new changes** to the `main` branch:
```sh
git add .
git commit -m "New changes"
git push origin main
```
GitHub Actions will build, push, and deploy your Docker image automatically! 🚀

---

## 🛠 Debugging & Troubleshooting

### 1️⃣ **Check Running Docker Containers on EC2**
```sh
docker ps
```

### 2️⃣ **View Deployment Logs**
```sh
docker logs youtubeconvert-web-1 --tail=50
```

### 3️⃣ **Restart Deployment Manually**
```sh
docker stop youtubeconvert-web-1 || true
docker rm youtubeconvert-web-1 || true
docker pull YOUR_DOCKER_HUB_USERNAME/youtubeconverter:latest
docker run -d -p 80:3000 --name youtubeconvert-web-1 --restart always YOUR_DOCKER_HUB_USERNAME/youtubeconverter:latest
```

---

## 🎯 Final Notes
✅ **Dockerized Ruby on Rails 8 App with SQLite**  
✅ **Automated CI/CD Pipeline with GitHub Actions**  
✅ **Deployed to AWS EC2 with Docker**  
✅ **Zero-Downtime Deployments**  

🚀 **Happy coding & deploying!** 🎉

