# CloudCart 🚀  
**Deploying a Scalable Web Application on AWS using Docker, Terraform, and GitHub Actions**

## 📦 Project Overview
This project demonstrates how to containerize a Node.js application, push it to Docker Hub using GitHub Actions CI/CD, and deploy it to AWS with Terraform using an Application Load Balancer (ALB), Auto Scaling Group (ASG), and EC2 instances.

---

## 🐳 1. Docker Setup
- App is located in `app/` folder.
- `Dockerfile` builds the image and exposes port `3000`.
- Run locally:
```bash
docker build -t cloudcart:dev ./app
docker run -p 8080:3000 cloudcart:dev
