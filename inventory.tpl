
[bastion]
bastion ansible_host=${bastion_public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=/var/lib/jenkins/NVir.pem

[jenkins]
jenkins ansible_host=${jenkins_private_ip} ansible_user=ubuntu ansible_ssh_private_key_file=/var/lib/jenkins/NVir.pem ansible_ssh_common_args='-o ProxyCommand="ssh -i /var/lib/jenkins/NVir.pem -W %h:%p ubuntu@${bastion_public_ip}"'
