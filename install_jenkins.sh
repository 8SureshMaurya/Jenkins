#! /bin/bash
#Debian package repository of Jenkins to automate installation and upgrade
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
    https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key

#Then add a Jenkins apt repository
 echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc]" \
    https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
    /etc/apt/sources.list.d/jenkins.list > /dev/null

 #Update your local package index, then finally install Jenkins
  sudo apt-get update
  sudo apt-get install fontconfig openjdk-17-jre -y
  sudo apt-get install jenkins -y 
  
  sudo cat /var/lib/jenkins/secrets/initialAdminPassword

#Install terraform  
#wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
#echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
#sudo apt update && sudo apt install terraform 
 
