# Preqs

- Install
  - minikube
  - terraform
  




# terraform-k8s

- Deploy namespace, secrets, persistent volume, persistent volume claim, postgres db, service to access db.

```bash
terraform init
terraform plan
terraform apply -auto-approve
```

# Minikube dashboard

- get pod name

```bash
kubectl get pods --namespace=kubernetes-dashboard
```

    NAME                                        READY   STATUS    RESTARTS   AGE
    dashboard-metrics-scraper-5c6664855-htrcz   1/1     Running   0          3d1h
    kubernetes-dashboard-55c4cbbc7c-6tntm       1/1     Running   0          3d1h

- setup a proxy so you can access the pod from another node

```bash
kubectl proxy --address 0.0.0.0 kubernetes-dashboard-55c4cbbc7c-6tntm 8001:80 --namespace=kubernetes-dashboard --disable-filter=true
```

- from another computer go to the webaddress

```bash
http://hostsIP:8001/api/v1/namespaces/kubernetes-dashboard/services/http:kubernetes-dashboard:/proxy/
```


# Access postgres db externally

- get pod name

```bash
kubectl get pods
```

- get the service to find out the port that the service is listening on:

```bash
kubectl get service 
NAME                          TYPE       CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
postgres-service-pnjetl-dev   NodePort   10.107.157.104   <none>        5432:30926/TCP   7m21s


```

- get db pod/deployment name and do port forwarding of the nodeport () to the db servers internal listening port

```bash
kubectl port-forward postgres-pnjetl-dev --address 0.0.0.0 30926:5432
```

- If there are problems confirm the config is correct:

```bash
kubectl exec -it etl-db -- grep listen_addresses /var/lib/postgresql/data/postgresql.conf
listen_addresses = '*'

kubectl exec -it jpa-db -- tail /var/lib/postgresql/data/pg_hba.conf
host    all             all             127.0.0.1/32            trust
# IPv6 local connections:
host    all             all             ::1/128                 trust
# Allow replication connections from localhost, by a user with the
# replication privilege.
local   replication     all                                     trust
host    replication     all             127.0.0.1/32            trust
host    replication     all             ::1/128                 trust

host all all all scram-sha-256

