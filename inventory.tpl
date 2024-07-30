
[bastion]
bastion ansible_host=${bastion_public_ip} ansible_user=ubuntu ansible_ssh_private_key_file= /home/suresh/Downloads/NVir.pem

[jenkins]
jenkins ansible_host=${jenkins_private_ip} ansible_user=ubuntu ansible_ssh_private_key_file= /home/suresh/Downloads/NVir.pem ansible_ssh_common_args='-o ProxyCommand="ssh -i  /home/suresh/Downloads/NVir.pem -W %h:%p ubuntu@${bastion_public_ip}"'
