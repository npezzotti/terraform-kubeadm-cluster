# Terraform kubeadm

1. Initialize kubeadm on the master node
    ```
    ssh ubuntu@$(terraform output -raw master_ip_address)
    sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-cert-extra-sans=<PUBLIC_IP>
    ```
2. Run commands printed in output to copy kubeconfig to `ubuntu` user's home directory. 
3. Install Flannel
    ```
    kubectl apply -f https://github.com/coreos/flannel/raw/master/Documentation/kube-flannel.yml
    ```
4. SSH onto worker nodes and join worker them using join command printed in step 1.
    ```
    ssh ubuntu@$(terraform output -json worker_ips | jq -r '.[0]')
    ssh ubuntu@$(terraform output -json worker_ips | jq -r '.[1]')
    ```
5. Copy admin config
    ```
    scp ubuntu@$(terraform output -raw master_ip_address):.kube/config admin.conf
    ```
6. Set `KUBECONFIG` to `admin.conf`
    ```
    export KUBECONFIG=admin.conf
    ```
7. Modify IP to public IP
    ```
    kubectl config set clusters.kubernetes.server https://$(terraform output -raw master_ip_address):6443
    ```
