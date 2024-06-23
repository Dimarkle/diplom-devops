# Диплом
# Оглавление:

  * [Создание облачной инфраструктуры:](#1)
  * [Подготовка ansible-конфигурации Kubespray:](#2)
  * [Развертывание Kubernetes кластера с помощью Kubespray:](#3)
  * [Kube-prometheus:](#4)
  * [Создание тестового приложения:](#5)
  * [Развертывание kube-prometheus на Kubernetes кластере:](#6)
  * [Подготовка системы мониторинга и деплой приложения:](#7)
  * [Подготовка GitHub для развертывания приложения в Kubernetes кластере:](#8)
  * [Автоматический запуск и применение конфигурации terraform из Github Actions при любом комите в main ветк:](#9)

 **Дипломное  задание доступно по [ссылке.](https://github.com/netology-code/devops-diplom-yandexcloud)**

# Решение:
<a id="1"></a>
# Создание облачной инфраструктуры: 
* Подготовим облачную инфраструктуру в Yandex Cloud при помощи [Terraform](https://github.com/Dimarkle/diplom-devops/tree/main/terraform) без дополнительных ручных действий:
___
![image](https://github.com/Dimarkle/diplom-devops/assets/118626944/1c368806-1d11-4cfc-bfe4-5b450a38ea45)
___
![image](https://github.com/Dimarkle/diplom-devops/assets/118626944/35f08be5-2267-4868-8853-454ad6bdae48)
___
* В файле [baket.tf](https://github.com/Dimarkle/diplom-devops/blob/main/terraform/baket.tf) создаем сервисный аккаунт и S3-bucket. Все работает:
___
![image](https://github.com/Dimarkle/diplom-devops/assets/118626944/68c9e33e-6d97-4792-ad0d-609a5556bcc4)
___
![image](https://github.com/Dimarkle/diplom-devops/assets/118626944/7dc33ee2-34b0-40b8-8ca7-fb685c5a59e0)
___
* В файле [main.tf](https://github.com/Dimarkle/diplom-devops/blob/main/terraform/main.tf) создаем VPC с подсетями, сами виртуальные машинки Compute Cloud в разных зонах доступности. Машинки созданы корректно:
___
![image](https://github.com/Dimarkle/diplom-devops/assets/118626944/f3013c82-cb1d-4d8c-8e9e-4448c1632bc1)
___
<a id="2"></a>
# Подготовка ansible-конфигурации Kubespray:
## Формируем:

*  [ansible-playbook](https://github.com/Dimarkle/diplom-devops/blob/main/ansible/playbook.yml), с его помощью осуществим подготовку узлов для установки Kubernetes методом Kubespray;

* [inventory-файл](https://github.com/Dimarkle/diplom-devops/blob/main/ansible/inventory-preparation) для предварительного ansible-playbook. Формируем его с помощью terraform. В файле [main.tf](https://github.com/Dimarkle/diplom-devops/blob/main/terraform/main.tf) за это отвечает следующий блок:

<details>
<summary>inventory-файл</summary>

``` 
resource "local_file" "inventory-preparation" {
  content = <<EOF1
[kube-cloud]
${yandex_compute_instance.master.network_interface.0.nat_ip_address}
${yandex_compute_instance.worker-1.network_interface.0.nat_ip_address}
${yandex_compute_instance.worker-2.network_interface.0.nat_ip_address}
${yandex_compute_instance.worker-3.network_interface.0.nat_ip_address}
  EOF1
  filename = "../ansible/inventory-preparation"
  depends_on = [yandex_compute_instance.master, yandex_compute_instance.worker-1, yandex_compute_instance.worker-2, yandex_compute_instance.worker-3]
}
```

</details>


* Комплексный [inventory-файл](https://github.com/Dimarkle/diplom-devops/blob/main/ansible/inventory-kubespray) для отработки инструмента Kubespray также формируем с помощью terraform.  В файле [main.tf](https://github.com/Dimarkle/diplom-devops/blob/main/terraform/main.tf) следующий блок:

<details>
<summary>Комплексный inventory-файл</summary>

``` 
resource "local_file" "inventory-kubespray" {
  content = <<EOF2
all:
  hosts:
    ${yandex_compute_instance.master.fqdn}:
      ansible_host: ${yandex_compute_instance.master.network_interface.0.ip_address}
      ip: ${yandex_compute_instance.master.network_interface.0.ip_address}
      access_ip: ${yandex_compute_instance.master.network_interface.0.ip_address}
    ${yandex_compute_instance.worker-1.fqdn}:
      ansible_host: ${yandex_compute_instance.worker-1.network_interface.0.ip_address}
      ip: ${yandex_compute_instance.worker-1.network_interface.0.ip_address}
      access_ip: ${yandex_compute_instance.worker-1.network_interface.0.ip_address}
    ${yandex_compute_instance.worker-2.fqdn}:
      ansible_host: ${yandex_compute_instance.worker-2.network_interface.0.ip_address}
      ip: ${yandex_compute_instance.worker-2.network_interface.0.ip_address}
      access_ip: ${yandex_compute_instance.worker-2.network_interface.0.ip_address}
    ${yandex_compute_instance.worker-3.fqdn}:
      ansible_host: ${yandex_compute_instance.worker-3.network_interface.0.ip_address}
      ip: ${yandex_compute_instance.worker-3.network_interface.0.ip_address}
      access_ip: ${yandex_compute_instance.worker-3.network_interface.0.ip_address}
  children:
    kube_control_plane:
      hosts:
        ${yandex_compute_instance.master.fqdn}:
    kube_node:
      hosts:
        ${yandex_compute_instance.worker-1.fqdn}:
        ${yandex_compute_instance.worker-2.fqdn}:
        ${yandex_compute_instance.worker-3.fqdn}:
    etcd:
      hosts:
        ${yandex_compute_instance.master.fqdn}:
    k8s_cluster:
      children:
        kube_control_plane:
        kube_node:
    calico_rr:
      hosts: {}
  EOF2
  filename = "../ansible/inventory-kubespray"
  depends_on = [yandex_compute_instance.master, yandex_compute_instance.worker-1, yandex_compute_instance.worker-2, yandex_compute_instance.worker-3]  
}

```

</details>


<a id="3"></a>
# Развертывание Kubernetes кластера с помощью Kubespray
*Запустим  [ansible-playbook](https://github.com/Dimarkle/diplom-devops/blob/main/ansible/playbook.yml), выполняющий подготовку узлов для установки Kubernetes методом Kubespray:*
___
![image](https://github.com/Dimarkle/diplom-devops/assets/118626944/5f91963b-f597-4e63-852c-661874bb8028)
___

*Копируем закрытый ключ и сформированный [inventory-kubespray](https://github.com/Dimarkle/diplom-devops/blob/main/ansible/inventory-kubespray) с локальной машины на мастер-ноду:*
___
![image](https://github.com/Dimarkle/diplom-devops/assets/118626944/2d13a2a4-8f4b-4900-8314-662e1a4eca32)
___
*С мастер-ноды запустим развертывание Kubernetes методом Kubespray:*
___
![image](https://github.com/Dimarkle/diplom-devops/assets/118626944/1d772ea2-246b-40e8-8ba9-71349d1b0ab0)


конец вывода:


![image](https://github.com/Dimarkle/diplom-devops/assets/118626944/6e385f30-1306-46d9-9faf-9db2027dfeb3)
___


**Результат работы kubectl:**
___
![image](https://github.com/Dimarkle/diplom-devops/assets/118626944/77acb492-17bb-4dad-b3d8-d4aefad0d31b)
___
*Отредактировал kubectl config,понадобиться нам в будущем, для формирования секрета в Github Actions:*
___
![image](https://github.com/Dimarkle/diplom-devops/assets/118626944/69c4a975-3f7c-418c-8cc2-1f8ac533bdb8)
___
<a id="4"></a>
#  Kube-prometheus:
**Для развертывания будем использовать [kube-prometheus:](https://github.com/prometheus-operator/kube-prometheus)**


<details>
<summary>Установка Kube-prometheus</summary>


```
ubuntu@master:~$ git clone https://github.com/prometheus-operator/kube-prometheus.git
Cloning into 'kube-prometheus'...
remote: Enumerating objects: 19834, done.
remote: Counting objects: 100% (282/282), done.
remote: Compressing objects: 100% (120/120), done.
remote: Total 19834 (delta 203), reused 202 (delta 147), pack-reused 19552
Receiving objects: 100% (19834/19834), 11.22 MiB | 18.20 MiB/s, done.
Resolving deltas: 100% (13517/13517), done.
ubuntu@master:~$ cd kube-prometheus
ubuntu@master:~/kube-prometheus$ kubectl apply --server-side -f manifests/setup
customresourcedefinition.apiextensions.k8s.io/alertmanagerconfigs.monitoring.coreos.com serverside-applied
customresourcedefinition.apiextensions.k8s.io/alertmanagers.monitoring.coreos.com serverside-applied
customresourcedefinition.apiextensions.k8s.io/podmonitors.monitoring.coreos.com serverside-applied
customresourcedefinition.apiextensions.k8s.io/probes.monitoring.coreos.com serverside-applied
customresourcedefinition.apiextensions.k8s.io/prometheuses.monitoring.coreos.com serverside-applied
customresourcedefinition.apiextensions.k8s.io/prometheusagents.monitoring.coreos.com serverside-applied
customresourcedefinition.apiextensions.k8s.io/prometheusrules.monitoring.coreos.com serverside-applied
customresourcedefinition.apiextensions.k8s.io/scrapeconfigs.monitoring.coreos.com serverside-applied
customresourcedefinition.apiextensions.k8s.io/servicemonitors.monitoring.coreos.com serverside-applied
customresourcedefinition.apiextensions.k8s.io/thanosrulers.monitoring.coreos.com serverside-applied
namespace/monitoring serverside-applied
ubuntu@master:~/kube-prometheus$ kubectl wait \
        --for condition=Established \
        --all CustomResourceDefinition \
        --namespace=monitoring
customresourcedefinition.apiextensions.k8s.io/alertmanagerconfigs.monitoring.coreos.com condition met
customresourcedefinition.apiextensions.k8s.io/alertmanagers.monitoring.coreos.com condition met
customresourcedefinition.apiextensions.k8s.io/bgpconfigurations.crd.projectcalico.org condition met
customresourcedefinition.apiextensions.k8s.io/bgpfilters.crd.projectcalico.org condition met
customresourcedefinition.apiextensions.k8s.io/bgppeers.crd.projectcalico.org condition met
customresourcedefinition.apiextensions.k8s.io/blockaffinities.crd.projectcalico.org condition met
customresourcedefinition.apiextensions.k8s.io/caliconodestatuses.crd.projectcalico.org condition met
customresourcedefinition.apiextensions.k8s.io/clusterinformations.crd.projectcalico.org condition met
customresourcedefinition.apiextensions.k8s.io/felixconfigurations.crd.projectcalico.org condition met
customresourcedefinition.apiextensions.k8s.io/globalnetworkpolicies.crd.projectcalico.org condition met
customresourcedefinition.apiextensions.k8s.io/globalnetworksets.crd.projectcalico.org condition met
customresourcedefinition.apiextensions.k8s.io/hostendpoints.crd.projectcalico.org condition met
customresourcedefinition.apiextensions.k8s.io/ipamblocks.crd.projectcalico.org condition met
customresourcedefinition.apiextensions.k8s.io/ipamconfigs.crd.projectcalico.org condition met
customresourcedefinition.apiextensions.k8s.io/ipamhandles.crd.projectcalico.org condition met
customresourcedefinition.apiextensions.k8s.io/ippools.crd.projectcalico.org condition met
customresourcedefinition.apiextensions.k8s.io/ipreservations.crd.projectcalico.org condition met
customresourcedefinition.apiextensions.k8s.io/kubecontrollersconfigurations.crd.projectcalico.org condition met
customresourcedefinition.apiextensions.k8s.io/networkpolicies.crd.projectcalico.org condition met
customresourcedefinition.apiextensions.k8s.io/networksets.crd.projectcalico.org condition met
customresourcedefinition.apiextensions.k8s.io/podmonitors.monitoring.coreos.com condition met
customresourcedefinition.apiextensions.k8s.io/probes.monitoring.coreos.com condition met
customresourcedefinition.apiextensions.k8s.io/prometheusagents.monitoring.coreos.com condition met
customresourcedefinition.apiextensions.k8s.io/prometheuses.monitoring.coreos.com condition met
customresourcedefinition.apiextensions.k8s.io/prometheusrules.monitoring.coreos.com condition met
customresourcedefinition.apiextensions.k8s.io/scrapeconfigs.monitoring.coreos.com condition met
customresourcedefinition.apiextensions.k8s.io/servicemonitors.monitoring.coreos.com condition met
customresourcedefinition.apiextensions.k8s.io/thanosrulers.monitoring.coreos.com condition met
ubuntu@master:~/kube-prometheus$ kubectl apply -f manifests/
alertmanager.monitoring.coreos.com/main created
networkpolicy.networking.k8s.io/alertmanager-main created
poddisruptionbudget.policy/alertmanager-main created
prometheusrule.monitoring.coreos.com/alertmanager-main-rules created
secret/alertmanager-main created
service/alertmanager-main created
serviceaccount/alertmanager-main created
servicemonitor.monitoring.coreos.com/alertmanager-main created
clusterrole.rbac.authorization.k8s.io/blackbox-exporter created
clusterrolebinding.rbac.authorization.k8s.io/blackbox-exporter created
configmap/blackbox-exporter-configuration created
deployment.apps/blackbox-exporter created
networkpolicy.networking.k8s.io/blackbox-exporter created
service/blackbox-exporter created
serviceaccount/blackbox-exporter created
servicemonitor.monitoring.coreos.com/blackbox-exporter created
secret/grafana-config created
secret/grafana-datasources created
configmap/grafana-dashboard-alertmanager-overview created
configmap/grafana-dashboard-apiserver created
configmap/grafana-dashboard-cluster-total created
configmap/grafana-dashboard-controller-manager created
configmap/grafana-dashboard-grafana-overview created
configmap/grafana-dashboard-k8s-resources-cluster created
configmap/grafana-dashboard-k8s-resources-multicluster created
configmap/grafana-dashboard-k8s-resources-namespace created
configmap/grafana-dashboard-k8s-resources-node created
configmap/grafana-dashboard-k8s-resources-pod created
configmap/grafana-dashboard-k8s-resources-workload created
configmap/grafana-dashboard-k8s-resources-workloads-namespace created
configmap/grafana-dashboard-kubelet created
configmap/grafana-dashboard-namespace-by-pod created
configmap/grafana-dashboard-namespace-by-workload created
configmap/grafana-dashboard-node-cluster-rsrc-use created
configmap/grafana-dashboard-node-rsrc-use created
configmap/grafana-dashboard-nodes-darwin created
configmap/grafana-dashboard-nodes created
configmap/grafana-dashboard-persistentvolumesusage created
configmap/grafana-dashboard-pod-total created
configmap/grafana-dashboard-prometheus-remote-write created
configmap/grafana-dashboard-prometheus created
configmap/grafana-dashboard-proxy created
configmap/grafana-dashboard-scheduler created
configmap/grafana-dashboard-workload-total created
configmap/grafana-dashboards created
deployment.apps/grafana created
networkpolicy.networking.k8s.io/grafana created
prometheusrule.monitoring.coreos.com/grafana-rules created
service/grafana created
serviceaccount/grafana created
servicemonitor.monitoring.coreos.com/grafana created
prometheusrule.monitoring.coreos.com/kube-prometheus-rules created
clusterrole.rbac.authorization.k8s.io/kube-state-metrics created
clusterrolebinding.rbac.authorization.k8s.io/kube-state-metrics created
deployment.apps/kube-state-metrics created
networkpolicy.networking.k8s.io/kube-state-metrics created
prometheusrule.monitoring.coreos.com/kube-state-metrics-rules created
service/kube-state-metrics created
serviceaccount/kube-state-metrics created
servicemonitor.monitoring.coreos.com/kube-state-metrics created
prometheusrule.monitoring.coreos.com/kubernetes-monitoring-rules created
servicemonitor.monitoring.coreos.com/kube-apiserver created
servicemonitor.monitoring.coreos.com/coredns created
servicemonitor.monitoring.coreos.com/kube-controller-manager created
servicemonitor.monitoring.coreos.com/kube-scheduler created
servicemonitor.monitoring.coreos.com/kubelet created
clusterrole.rbac.authorization.k8s.io/node-exporter created
clusterrolebinding.rbac.authorization.k8s.io/node-exporter created
daemonset.apps/node-exporter created
networkpolicy.networking.k8s.io/node-exporter created
prometheusrule.monitoring.coreos.com/node-exporter-rules created
service/node-exporter created
serviceaccount/node-exporter created
servicemonitor.monitoring.coreos.com/node-exporter created
clusterrole.rbac.authorization.k8s.io/prometheus-k8s created
clusterrolebinding.rbac.authorization.k8s.io/prometheus-k8s created
networkpolicy.networking.k8s.io/prometheus-k8s created
poddisruptionbudget.policy/prometheus-k8s created
prometheus.monitoring.coreos.com/k8s created
prometheusrule.monitoring.coreos.com/prometheus-k8s-prometheus-rules created
rolebinding.rbac.authorization.k8s.io/prometheus-k8s-config created
rolebinding.rbac.authorization.k8s.io/prometheus-k8s created
rolebinding.rbac.authorization.k8s.io/prometheus-k8s created
rolebinding.rbac.authorization.k8s.io/prometheus-k8s created
role.rbac.authorization.k8s.io/prometheus-k8s-config created
role.rbac.authorization.k8s.io/prometheus-k8s created
role.rbac.authorization.k8s.io/prometheus-k8s created
role.rbac.authorization.k8s.io/prometheus-k8s created
service/prometheus-k8s created
serviceaccount/prometheus-k8s created
servicemonitor.monitoring.coreos.com/prometheus-k8s created
apiservice.apiregistration.k8s.io/v1beta1.metrics.k8s.io created
clusterrole.rbac.authorization.k8s.io/prometheus-adapter created
clusterrole.rbac.authorization.k8s.io/system:aggregated-metrics-reader created
clusterrolebinding.rbac.authorization.k8s.io/prometheus-adapter created
clusterrolebinding.rbac.authorization.k8s.io/resource-metrics:system:auth-delegator created
clusterrole.rbac.authorization.k8s.io/resource-metrics-server-resources created
configmap/adapter-config created
deployment.apps/prometheus-adapter created
networkpolicy.networking.k8s.io/prometheus-adapter created
poddisruptionbudget.policy/prometheus-adapter created
rolebinding.rbac.authorization.k8s.io/resource-metrics-auth-reader created
service/prometheus-adapter created
serviceaccount/prometheus-adapter created
servicemonitor.monitoring.coreos.com/prometheus-adapter created
clusterrole.rbac.authorization.k8s.io/prometheus-operator created
clusterrolebinding.rbac.authorization.k8s.io/prometheus-operator created
deployment.apps/prometheus-operator created
networkpolicy.networking.k8s.io/prometheus-operator created
prometheusrule.monitoring.coreos.com/prometheus-operator-rules created
service/prometheus-operator created
serviceaccount/prometheus-operator created
servicemonitor.monitoring.coreos.com/prometheus-operator created
ubuntu@master:~/kube-prometheus$ 
```

</details>



*Проверка:*
___
![image](https://github.com/Dimarkle/diplom-devops/assets/118626944/489eaaaa-3d9f-40c1-805e-b4f2bc7ac815)
___
Для доступа к интерфейсу изменим сетевую политику, для этого создадим ```grafana-service.yml```:

<details>
<summary>grafana-service.yml</summary>


```


apiVersion: v1
kind: Service
metadata:
  labels:
    app.kubernetes.io/name: grafana-service
  name: grafana
  namespace: monitoring
spec:
  type: NodePort
  ports:
  - name: grafana-port
    port: 3000
    targetPort: 3000
    nodePort: 30001
  selector:
    app.kubernetes.io/component: grafana
    app.kubernetes.io/name: grafana
    app.kubernetes.io/part-of: kube-prometheus

---
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: grafana
spec:
  podSelector:
    matchLabels:
      app: grafana
  ingress:
  - {}
```

</details>


___
![image](https://github.com/Dimarkle/diplom-devops/assets/118626944/acd8fb67-0ffb-45d4-be72-0beb17971121)
___
* [master](http://158.160.37.27:30001/)
* [worker-1](http://51.250.7.161:30001/)
* [worker-2](http://158.160.80.152:30001/)
* [worker-3](http://158.160.144.193:30001/)
___
![image](https://github.com/Dimarkle/diplom-devops/assets/118626944/d34fe40b-deaf-454e-bc45-68977a6d1893)
___
![image](https://github.com/Dimarkle/diplom-devops/assets/118626944/3e7edae0-acb6-45fd-be50-4f98f16f14da)
___
*Пароль и логин по умолчанию*
<a id="5"></a>
# Создание тестового приложения
Создадим [репу](https://github.com/Dimarkle/nginx) в github. Скачаем его на локальную машину и заполним его  файлами, необходимыми для создания  Dockerfile.        Создадим  версию  нашего приложения v1.0 .
___
![image](https://github.com/Dimarkle/diplom-devops/assets/118626944/d69bb3af-0636-4d4f-9c61-4ff70af1725e)
___
Также создадим [репу](https://hub.docker.com/repository/docker/dima2885/diplom/general) в Docker Hub:
___
![image](https://github.com/Dimarkle/diplom-devops/assets/118626944/f124b48b-5e3f-4a5d-8258-94e0b1e024ab)
___
Выполним сборку образа на основе Dockerfile 
___
![image](https://github.com/Dimarkle/diplom-devops/assets/118626944/6eaa6216-6c07-4e74-962b-31950ae239f2)
____

Отправим созданный образ на Docker Hub:
___
![image](https://github.com/Dimarkle/diplom-devops/assets/118626944/92564487-e746-4569-8a8e-9e36749bfc3c)
___
Проверяем:
___
![image](https://github.com/Dimarkle/diplom-devops/assets/118626944/484ce855-2d46-4f95-bc74-2e382b4a1522)
___
<a id="6"></a>
# Развертывание kube-prometheus на Kubernetes кластере: 
Создадим файл ```deployment.yaml```

<details>
<summary>deployment.yaml</summary>


```

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp-diplom
  labels:
    app: webapp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: webapp
  template:
    metadata:
      labels:
        app: webapp
    spec:
      containers:
      - name: webapp-diplom
        image: dima2885/diplom
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: webapp-service
spec:
  type: NodePort
  selector:
    app: webapp
  ports:
  - protocol: TCP
    port: 80
    nodePort: 30002

```

</details>



___
![image](https://github.com/Dimarkle/diplom-devops/assets/118626944/5acc2858-44dd-45a8-861a-5be377b0c961)
___
![image](https://github.com/Dimarkle/diplom-devops/assets/118626944/6c38cfb2-3b5b-414a-a7a5-40ce6d89630e)
___
**Проверка:**
___
![image](https://github.com/Dimarkle/diplom-devops/assets/118626944/6f7ae294-b4a2-45b8-9996-5e4f9fbc05f5)
____

* [master](http://158.160.37.27:30002/)
* [worker-1](http://51.250.7.161:30002/)
* [worker-2](http://158.160.80.152:30002/)
* [worker-3](http://158.160.144.193:30002/)

<a id="7"></a>
# Подготовка системы мониторинга и деплой приложения:

*Создаем секреты Github Actions:*
___
![image](https://github.com/Dimarkle/diplom-devops/assets/118626944/a75187bf-50af-4746-97ed-5e824e56f02d)
___

Создаем файл [Image.yml](https://github.com/Dimarkle/nginx/blob/main/.github/workflows/image.yml). И редактируем [index.html](https://github.com/Dimarkle/nginx/blob/main/index.html)
Версия 1.1:
____
![image](https://github.com/Dimarkle/diplom-devops/assets/118626944/8ca532ec-1eae-419b-8569-769e725a9c88)
___
Ошибок нет:
___
![image](https://github.com/Dimarkle/diplom-devops/assets/118626944/07f84a82-637e-43cb-9fb2-df3501dd5da4)
___
Docker Hub:
___
![image](https://github.com/Dimarkle/diplom-devops/assets/118626944/3cca91a9-224c-42b9-a58d-949bdb5ff76f)
___
**GitHub Actions создает и загружает образ пользовательского web-приложения в Docker Hub при выполнении коммита.**

<a id="8"></a>
# Подготовка GitHub для развертывания приложения в Kubernetes кластере:

*Добавим секрет ```KUBECONFIG_FILE``` в Github Actions:*
___
![image](https://github.com/Dimarkle/diplom-devops/assets/118626944/f579d243-101e-4f89-b721-fd75476648d1)
___
*Создадим файл [deploy.yml.](https://github.com/Dimarkle/nginx/blob/main/.github/workflows/deploy.yml)*

*Изменим файл веб-приложения index.html в репозитории и отправим изменения в GitHub, а также присвоим новый тег:*
___
![image](https://github.com/Dimarkle/diplom-devops/assets/118626944/05aa9110-e340-4ba6-a237-74110abd96f9)
___
Ошибок нет.
___
![image](https://github.com/Dimarkle/diplom-devops/assets/118626944/f93d1c57-81db-4d74-85b2-d24f104673f4)
___
___
![image](https://github.com/Dimarkle/diplom-devops/assets/118626944/f57f9be3-4094-4064-8486-150be48c9fc9)
___

*Я экспериментировал и добрался до версии [v8.8](https://github.com/Dimarkle/nginx/actions)*

___
![image](https://github.com/Dimarkle/diplom-devops/assets/118626944/0f1e1f55-333c-4a32-a828-d0c2eece06d7)
___
<a id="9"></a>
# Автоматический запуск и применение конфигурации terraform из Github Actions при любом комите в main ветку:

Создадим отдельный [репозиторий](https://github.com/Dimarkle/atlantis)

*Создаем секреты Github Actions. Для этого  нам понадобиться создание статических ключей доступа и авторизованный ключ для сервисного аккаунта*

<details>
<summary>deployment.yaml</summary>


```
diman@Diman:~/diplom/terraform$ yc iam key create --service-account-name diman-diplom -o key.json --output key.json --folder-id b1g************
id: *****************
service_account_id:  *****************h
created_at: "2024-06-22T15:27:16.073806810Z"
key_algorithm: RSA_2048
diman@Diman:~/diplom/terraform$ yc config set service-account-key key.json
diman@Diman:~/diplom/terraform$ yc config list
```

</details>


___
![image](https://github.com/Dimarkle/diplom-devops/assets/118626944/bd7cc63c-1806-4772-a2a2-c04b72a6bd0c)
___

Упростим немного [terraform код](https://github.com/Dimarkle/atlantis)  и создадим ```workflows``` [terraform.yml](https://github.com/Dimarkle/atlantis/blob/main/.github/workflows/terraform.yml).


*В terraform.yml я использовал только Terraform Plan, т.к. изначально я создавал конфигурацию terraform в разных зонах доступности (a,b,d(вместо с)). Зона доступности d, требует  platform_id = "standard-v3", с  "standard-v1" (у меня зоны a и b) она не запускается. Я применил конфигурации terraform в  Github Actions когда уже вся инфраструктура была настроена. И для того, чтобы всю инфраструктуру поменять на  "standard-v3", нужно  переустановить всю  созданную мной инфраструктуру, что делать мне бы не хотелось.*

[Actions](https://github.com/Dimarkle/atlantis/actions)
____
![image](https://github.com/Dimarkle/diplom-devops/assets/118626944/7a74d691-dd46-42e9-a5f4-06b583bc19a0)
____

<details>
<summary>Terraform Plan</summary>

```
4s
8s
Sat, 22 Jun 2024 20:59:21 GMT
Run terraform plan
Sat, 22 Jun 2024 20:59:21 GMT
/home/runner/work/_temp/6c9cc6c2-e715-4381-91b4-37e6a39908ff/terraform-bin plan
Sat, 22 Jun 2024 20:59:23 GMT
local_file.backendConf: Refreshing state... [id=d4c60048d3c028b00e1cab40288f633d4f732d21]
Sat, 22 Jun 2024 20:59:23 GMT
yandex_vpc_subnet.subnet-d: Refreshing state... [id=fl8asquatn3nu84e1mb3]
Sat, 22 Jun 2024 20:59:23 GMT
yandex_kms_symmetric_key.key-a: Refreshing state... [id=abjsrl1q6fs6g1angqk0]
Sat, 22 Jun 2024 20:59:23 GMT
yandex_vpc_network.net: Refreshing state... [id=enpkcdt3mcqlr1gmum67]
Sat, 22 Jun 2024 20:59:23 GMT
yandex_vpc_subnet.subnet-b: Refreshing state... [id=e2lupau8bgpa84pspf97]
Sat, 22 Jun 2024 20:59:23 GMT
yandex_iam_service_account.diman-diplom: Refreshing state... [id=ajedsrhv4ua9ld7t22ph]
Sat, 22 Jun 2024 20:59:23 GMT
yandex_vpc_subnet.subnet-a: Refreshing state... [id=e9brv9lccdmvglc35fnc]
Sat, 22 Jun 2024 20:59:26 GMT
yandex_iam_service_account_static_access_key.bucket-static_access_key: Refreshing state... [id=ajepl81chs3qstnmq1jt]
Sat, 22 Jun 2024 20:59:26 GMT
yandex_resourcemanager_folder_iam_binding.storage-admin: Refreshing state... [id=b1gcms0oj5ro6jjsgqdg/storage.admin]
Sat, 22 Jun 2024 20:59:26 GMT
yandex_resourcemanager_folder_iam_binding.encrypterDecrypter: Refreshing state... [id=b1gcms0oj5ro6jjsgqdg/kms.keys.encrypterDecrypter]
Sat, 22 Jun 2024 20:59:26 GMT
yandex_storage_bucket.diman-diplom: Refreshing state... [id=diman-diplom]
Sat, 22 Jun 2024 20:59:29 GMT

Sat, 22 Jun 2024 20:59:29 GMT
Terraform used the selected providers to generate the following execution
Sat, 22 Jun 2024 20:59:29 GMT
plan. Resource actions are indicated with the following symbols:
Sat, 22 Jun 2024 20:59:29 GMT
  + create
Sat, 22 Jun 2024 20:59:29 GMT
  ~ update in-place
Sat, 22 Jun 2024 20:59:29 GMT
  - destroy
Sat, 22 Jun 2024 20:59:29 GMT

Sat, 22 Jun 2024 20:59:29 GMT
Terraform will perform the following actions:
Sat, 22 Jun 2024 20:59:29 GMT

Sat, 22 Jun 2024 20:59:29 GMT
  # local_file.inventory-kubespray will be created
Sat, 22 Jun 2024 20:59:29 GMT
  + resource "local_file" "inventory-kubespray" {
Sat, 22 Jun 2024 20:59:29 GMT
      + content              = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
      + content_base64sha256 = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
      + content_base64sha512 = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
      + content_md5          = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
      + content_sha1         = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
      + content_sha256       = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
      + content_sha512       = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
      + directory_permission = "0777"
Sat, 22 Jun 2024 20:59:29 GMT
      + file_permission      = "0777"
Sat, 22 Jun 2024 20:59:29 GMT
      + filename             = "../ansible/inventory-kubespray"
Sat, 22 Jun 2024 20:59:29 GMT
      + id                   = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
    }
Sat, 22 Jun 2024 20:59:29 GMT

Sat, 22 Jun 2024 20:59:29 GMT
  # local_file.inventory-preparation will be created
Sat, 22 Jun 2024 20:59:29 GMT
  + resource "local_file" "inventory-preparation" {
Sat, 22 Jun 2024 20:59:29 GMT
      + content              = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
      + content_base64sha256 = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
      + content_base64sha512 = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
      + content_md5          = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
      + content_sha1         = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
      + content_sha256       = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
      + content_sha512       = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
      + directory_permission = "0777"
Sat, 22 Jun 2024 20:59:29 GMT
      + file_permission      = "0777"
Sat, 22 Jun 2024 20:59:29 GMT
      + filename             = "../ansible/inventory-preparation"
Sat, 22 Jun 2024 20:59:29 GMT
      + id                   = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
    }
Sat, 22 Jun 2024 20:59:29 GMT

Sat, 22 Jun 2024 20:59:29 GMT
  # yandex_compute_instance.vms["master"] will be created
Sat, 22 Jun 2024 20:59:29 GMT
  + resource "yandex_compute_instance" "vms" {
Sat, 22 Jun 2024 20:59:29 GMT
      + created_at                = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
      + folder_id                 = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
      + fqdn                      = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
      + gpu_cluster_id            = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
      + hostname                  = "master"
Sat, 22 Jun 2024 20:59:29 GMT
      + id                        = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
      + maintenance_grace_period  = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
      + maintenance_policy        = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
      + metadata                  = {
Sat, 22 Jun 2024 20:59:29 GMT
          + "ssh-keys" = <<-EOT
Sat, 22 Jun 2024 20:59:29 GMT
                ubuntu:***
Sat, 22 Jun 2024 20:59:29 GMT
            EOT
Sat, 22 Jun 2024 20:59:29 GMT
        }
Sat, 22 Jun 2024 20:59:29 GMT
      + name                      = "master"
Sat, 22 Jun 2024 20:59:29 GMT
      + network_acceleration_type = "standard"
Sat, 22 Jun 2024 20:59:29 GMT
      + platform_id               = "standard-v3"
Sat, 22 Jun 2024 20:59:29 GMT
      + service_account_id        = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
      + status                    = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
      + zone                      = "ru-central1-a"
Sat, 22 Jun 2024 20:59:29 GMT

Sat, 22 Jun 2024 20:59:29 GMT
      + boot_disk {
Sat, 22 Jun 2024 20:59:29 GMT
          + auto_delete = true
Sat, 22 Jun 2024 20:59:29 GMT
          + device_name = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
          + disk_id     = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
          + mode        = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT

Sat, 22 Jun 2024 20:59:29 GMT
          + initialize_params {
Sat, 22 Jun 2024 20:59:29 GMT
              + block_size  = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
              + description = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
              + image_id    = "fd8di2mid9ojikcm93en"
Sat, 22 Jun 2024 20:59:29 GMT
              + name        = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
              + size        = 30
Sat, 22 Jun 2024 20:59:29 GMT
              + snapshot_id = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
              + type        = "network-hdd"
Sat, 22 Jun 2024 20:59:29 GMT
            }
Sat, 22 Jun 2024 20:59:29 GMT
        }
Sat, 22 Jun 2024 20:59:29 GMT

Sat, 22 Jun 2024 20:59:29 GMT
      + network_interface {
Sat, 22 Jun 2024 20:59:29 GMT
          + index              = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
          + ip_address         = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
          + ipv4               = true
Sat, 22 Jun 2024 20:59:29 GMT
          + ipv6               = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
          + ipv6_address       = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
          + mac_address        = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
          + nat                = true
Sat, 22 Jun 2024 20:59:29 GMT
          + nat_ip_address     = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
          + nat_ip_version     = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
          + security_group_ids = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
          + subnet_id          = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
        }
Sat, 22 Jun 2024 20:59:29 GMT

Sat, 22 Jun 2024 20:59:29 GMT
      + resources {
Sat, 22 Jun 2024 20:59:29 GMT
          + core_fraction = 100
Sat, 22 Jun 2024 20:59:29 GMT
          + cores         = 4
Sat, 22 Jun 2024 20:59:29 GMT
          + memory        = 4
Sat, 22 Jun 2024 20:59:29 GMT
        }
Sat, 22 Jun 2024 20:59:29 GMT
    }
Sat, 22 Jun 2024 20:59:29 GMT

Sat, 22 Jun 2024 20:59:29 GMT
  # yandex_compute_instance.vms["worker-1"] will be created
Sat, 22 Jun 2024 20:59:29 GMT
  + resource "yandex_compute_instance" "vms" {
Sat, 22 Jun 2024 20:59:29 GMT
      + created_at                = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
      + folder_id                 = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
      + fqdn                      = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
      + gpu_cluster_id            = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
      + hostname                  = "worker-1"
Sat, 22 Jun 2024 20:59:29 GMT
      + id                        = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
      + maintenance_grace_period  = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
      + maintenance_policy        = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
      + metadata                  = {
Sat, 22 Jun 2024 20:59:29 GMT
          + "ssh-keys" = <<-EOT
Sat, 22 Jun 2024 20:59:29 GMT
                ubuntu:***
Sat, 22 Jun 2024 20:59:29 GMT
            EOT
Sat, 22 Jun 2024 20:59:29 GMT
        }
Sat, 22 Jun 2024 20:59:29 GMT
      + name                      = "worker-1"
Sat, 22 Jun 2024 20:59:29 GMT
      + network_acceleration_type = "standard"
Sat, 22 Jun 2024 20:59:29 GMT
      + platform_id               = "standard-v3"
Sat, 22 Jun 2024 20:59:29 GMT
      + service_account_id        = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
      + status                    = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
      + zone                      = "ru-central1-a"
Sat, 22 Jun 2024 20:59:29 GMT

Sat, 22 Jun 2024 20:59:29 GMT
      + boot_disk {
Sat, 22 Jun 2024 20:59:29 GMT
          + auto_delete = true
Sat, 22 Jun 2024 20:59:29 GMT
          + device_name = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
          + disk_id     = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
          + mode        = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT

Sat, 22 Jun 2024 20:59:29 GMT
          + initialize_params {
Sat, 22 Jun 2024 20:59:29 GMT
              + block_size  = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
              + description = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
              + image_id    = "fd8di2mid9ojikcm93en"
Sat, 22 Jun 2024 20:59:29 GMT
              + name        = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
              + size        = 30
Sat, 22 Jun 2024 20:59:29 GMT
              + snapshot_id = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
              + type        = "network-hdd"
Sat, 22 Jun 2024 20:59:29 GMT
            }
Sat, 22 Jun 2024 20:59:29 GMT
        }
Sat, 22 Jun 2024 20:59:29 GMT

Sat, 22 Jun 2024 20:59:29 GMT
      + network_interface {
Sat, 22 Jun 2024 20:59:29 GMT
          + index              = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
          + ip_address         = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
          + ipv4               = true
Sat, 22 Jun 2024 20:59:29 GMT
          + ipv6               = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
          + ipv6_address       = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
          + mac_address        = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
          + nat                = true
Sat, 22 Jun 2024 20:59:29 GMT
          + nat_ip_address     = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
          + nat_ip_version     = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
          + security_group_ids = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
          + subnet_id          = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
        }
Sat, 22 Jun 2024 20:59:29 GMT

Sat, 22 Jun 2024 20:59:29 GMT
      + resources {
Sat, 22 Jun 2024 20:59:29 GMT
          + core_fraction = 100
Sat, 22 Jun 2024 20:59:29 GMT
          + cores         = 4
Sat, 22 Jun 2024 20:59:29 GMT
          + memory        = 4
Sat, 22 Jun 2024 20:59:29 GMT
        }
Sat, 22 Jun 2024 20:59:29 GMT
    }
Sat, 22 Jun 2024 20:59:29 GMT

Sat, 22 Jun 2024 20:59:29 GMT
  # yandex_compute_instance.vms["worker-2"] will be created
Sat, 22 Jun 2024 20:59:29 GMT
  + resource "yandex_compute_instance" "vms" {
Sat, 22 Jun 2024 20:59:29 GMT
      + created_at                = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
      + folder_id                 = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
      + fqdn                      = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
      + gpu_cluster_id            = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
      + hostname                  = "worker-2"
Sat, 22 Jun 2024 20:59:29 GMT
      + id                        = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
      + maintenance_grace_period  = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
      + maintenance_policy        = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
      + metadata                  = {
Sat, 22 Jun 2024 20:59:29 GMT
          + "ssh-keys" = <<-EOT
Sat, 22 Jun 2024 20:59:29 GMT
                ubuntu:***
Sat, 22 Jun 2024 20:59:29 GMT
            EOT
Sat, 22 Jun 2024 20:59:29 GMT
        }
Sat, 22 Jun 2024 20:59:29 GMT
      + name                      = "worker-2"
Sat, 22 Jun 2024 20:59:29 GMT
      + network_acceleration_type = "standard"
Sat, 22 Jun 2024 20:59:29 GMT
      + platform_id               = "standard-v3"
Sat, 22 Jun 2024 20:59:29 GMT
      + service_account_id        = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
      + status                    = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
      + zone                      = "ru-central1-b"
Sat, 22 Jun 2024 20:59:29 GMT

Sat, 22 Jun 2024 20:59:29 GMT
      + boot_disk {
Sat, 22 Jun 2024 20:59:29 GMT
          + auto_delete = true
Sat, 22 Jun 2024 20:59:29 GMT
          + device_name = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
          + disk_id     = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
          + mode        = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT

Sat, 22 Jun 2024 20:59:29 GMT
          + initialize_params {
Sat, 22 Jun 2024 20:59:29 GMT
              + block_size  = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
              + description = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
              + image_id    = "fd8di2mid9ojikcm93en"
Sat, 22 Jun 2024 20:59:29 GMT
              + name        = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
              + size        = 30
Sat, 22 Jun 2024 20:59:29 GMT
              + snapshot_id = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
              + type        = "network-hdd"
Sat, 22 Jun 2024 20:59:29 GMT
            }
Sat, 22 Jun 2024 20:59:29 GMT
        }
Sat, 22 Jun 2024 20:59:29 GMT

Sat, 22 Jun 2024 20:59:29 GMT
      + network_interface {
Sat, 22 Jun 2024 20:59:29 GMT
          + index              = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
          + ip_address         = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
          + ipv4               = true
Sat, 22 Jun 2024 20:59:29 GMT
          + ipv6               = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
          + ipv6_address       = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
          + mac_address        = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
          + nat                = true
Sat, 22 Jun 2024 20:59:29 GMT
          + nat_ip_address     = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
          + nat_ip_version     = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
          + security_group_ids = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
          + subnet_id          = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
        }
Sat, 22 Jun 2024 20:59:29 GMT

Sat, 22 Jun 2024 20:59:29 GMT
      + resources {
Sat, 22 Jun 2024 20:59:29 GMT
          + core_fraction = 100
Sat, 22 Jun 2024 20:59:29 GMT
          + cores         = 4
Sat, 22 Jun 2024 20:59:29 GMT
          + memory        = 4
Sat, 22 Jun 2024 20:59:29 GMT
        }
Sat, 22 Jun 2024 20:59:29 GMT
    }
Sat, 22 Jun 2024 20:59:29 GMT

Sat, 22 Jun 2024 20:59:29 GMT
  # yandex_compute_instance.vms["worker-3"] will be created
Sat, 22 Jun 2024 20:59:29 GMT
  + resource "yandex_compute_instance" "vms" {
Sat, 22 Jun 2024 20:59:29 GMT
      + created_at                = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
      + folder_id                 = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
      + fqdn                      = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
      + gpu_cluster_id            = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
      + hostname                  = "worker-3"
Sat, 22 Jun 2024 20:59:29 GMT
      + id                        = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
      + maintenance_grace_period  = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
      + maintenance_policy        = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
      + metadata                  = {
Sat, 22 Jun 2024 20:59:29 GMT
          + "ssh-keys" = <<-EOT
Sat, 22 Jun 2024 20:59:29 GMT
                ubuntu:***
Sat, 22 Jun 2024 20:59:29 GMT
            EOT
Sat, 22 Jun 2024 20:59:29 GMT
        }
Sat, 22 Jun 2024 20:59:29 GMT
      + name                      = "worker-3"
Sat, 22 Jun 2024 20:59:29 GMT
      + network_acceleration_type = "standard"
Sat, 22 Jun 2024 20:59:29 GMT
      + platform_id               = "standard-v3"
Sat, 22 Jun 2024 20:59:29 GMT
      + service_account_id        = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
      + status                    = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
      + zone                      = "ru-central1-d"
Sat, 22 Jun 2024 20:59:29 GMT

Sat, 22 Jun 2024 20:59:29 GMT
      + boot_disk {
Sat, 22 Jun 2024 20:59:29 GMT
          + auto_delete = true
Sat, 22 Jun 2024 20:59:29 GMT
          + device_name = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
          + disk_id     = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
          + mode        = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT

Sat, 22 Jun 2024 20:59:29 GMT
          + initialize_params {
Sat, 22 Jun 2024 20:59:29 GMT
              + block_size  = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
              + description = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
              + image_id    = "fd8di2mid9ojikcm93en"
Sat, 22 Jun 2024 20:59:29 GMT
              + name        = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
              + size        = 30
Sat, 22 Jun 2024 20:59:29 GMT
              + snapshot_id = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
              + type        = "network-hdd"
Sat, 22 Jun 2024 20:59:29 GMT
            }
Sat, 22 Jun 2024 20:59:29 GMT
        }
Sat, 22 Jun 2024 20:59:29 GMT

Sat, 22 Jun 2024 20:59:29 GMT
      + network_interface {
Sat, 22 Jun 2024 20:59:29 GMT
          + index              = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
          + ip_address         = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
          + ipv4               = true
Sat, 22 Jun 2024 20:59:29 GMT
          + ipv6               = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
          + ipv6_address       = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
          + mac_address        = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
          + nat                = true
Sat, 22 Jun 2024 20:59:29 GMT
          + nat_ip_address     = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
          + nat_ip_version     = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
          + security_group_ids = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
          + subnet_id          = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
        }
Sat, 22 Jun 2024 20:59:29 GMT

Sat, 22 Jun 2024 20:59:29 GMT
      + resources {
Sat, 22 Jun 2024 20:59:29 GMT
          + core_fraction = 100
Sat, 22 Jun 2024 20:59:29 GMT
          + cores         = 4
Sat, 22 Jun 2024 20:59:29 GMT
          + memory        = 4
Sat, 22 Jun 2024 20:59:29 GMT
        }
Sat, 22 Jun 2024 20:59:29 GMT
    }
Sat, 22 Jun 2024 20:59:29 GMT

Sat, 22 Jun 2024 20:59:29 GMT
  # yandex_iam_service_account_static_access_key.bucket-static_access_key will be updated in-place
Sat, 22 Jun 2024 20:59:29 GMT
  ~ resource "yandex_iam_service_account_static_access_key" "bucket-static_access_key" {
Sat, 22 Jun 2024 20:59:29 GMT
        id                 = "ajepl81chs3qstnmq1jt"
Sat, 22 Jun 2024 20:59:29 GMT
        # (5 unchanged attributes hidden)
Sat, 22 Jun 2024 20:59:29 GMT
    }
Sat, 22 Jun 2024 20:59:29 GMT

Sat, 22 Jun 2024 20:59:29 GMT
  # yandex_resourcemanager_folder_iam_binding.editor will be created
Sat, 22 Jun 2024 20:59:29 GMT
  + resource "yandex_resourcemanager_folder_iam_binding" "editor" {
Sat, 22 Jun 2024 20:59:29 GMT
      + folder_id = "b1gcms0oj5ro6jjsgqdg"
Sat, 22 Jun 2024 20:59:29 GMT
      + id        = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
      + members   = [
Sat, 22 Jun 2024 20:59:29 GMT
          + "serviceAccount:ajedsrhv4ua9ld7t22ph",
Sat, 22 Jun 2024 20:59:29 GMT
        ]
Sat, 22 Jun 2024 20:59:29 GMT
      + role      = "editor"
Sat, 22 Jun 2024 20:59:29 GMT
    }
Sat, 22 Jun 2024 20:59:29 GMT

Sat, 22 Jun 2024 20:59:29 GMT
  # yandex_vpc_subnet.subnet-a will be destroyed
Sat, 22 Jun 2024 20:59:29 GMT
  # (because yandex_vpc_subnet.subnet-a is not in configuration)
Sat, 22 Jun 2024 20:59:29 GMT
  - resource "yandex_vpc_subnet" "subnet-a" {
Sat, 22 Jun 2024 20:59:29 GMT
      - created_at     = "2024-06-22T15:20:12Z" -> null
Sat, 22 Jun 2024 20:59:29 GMT
      - folder_id      = "b1gcms0oj5ro6jjsgqdg" -> null
Sat, 22 Jun 2024 20:59:29 GMT
      - id             = "e9brv9lccdmvglc35fnc" -> null
Sat, 22 Jun 2024 20:59:29 GMT
      - labels         = {} -> null
Sat, 22 Jun 2024 20:59:29 GMT
      - name           = "subnet-a" -> null
Sat, 22 Jun 2024 20:59:29 GMT
      - network_id     = "enpkcdt3mcqlr1gmum67" -> null
Sat, 22 Jun 2024 20:59:29 GMT
      - v4_cidr_blocks = [
Sat, 22 Jun 2024 20:59:29 GMT
          - "192.168.10.0/24",
Sat, 22 Jun 2024 20:59:29 GMT
        ] -> null
Sat, 22 Jun 2024 20:59:29 GMT
      - v6_cidr_blocks = [] -> null
Sat, 22 Jun 2024 20:59:29 GMT
      - zone           = "ru-central1-a" -> null
Sat, 22 Jun 2024 20:59:29 GMT
    }
Sat, 22 Jun 2024 20:59:29 GMT

Sat, 22 Jun 2024 20:59:29 GMT
  # yandex_vpc_subnet.subnet-b will be destroyed
Sat, 22 Jun 2024 20:59:29 GMT
  # (because yandex_vpc_subnet.subnet-b is not in configuration)
Sat, 22 Jun 2024 20:59:29 GMT
  - resource "yandex_vpc_subnet" "subnet-b" {
Sat, 22 Jun 2024 20:59:29 GMT
      - created_at     = "2024-06-22T15:20:13Z" -> null
Sat, 22 Jun 2024 20:59:29 GMT
      - folder_id      = "b1gcms0oj5ro6jjsgqdg" -> null
Sat, 22 Jun 2024 20:59:29 GMT
      - id             = "e2lupau8bgpa84pspf97" -> null
Sat, 22 Jun 2024 20:59:29 GMT
      - labels         = {} -> null
Sat, 22 Jun 2024 20:59:29 GMT
      - name           = "subnet-b" -> null
Sat, 22 Jun 2024 20:59:29 GMT
      - network_id     = "enpkcdt3mcqlr1gmum67" -> null
Sat, 22 Jun 2024 20:59:29 GMT
      - v4_cidr_blocks = [
Sat, 22 Jun 2024 20:59:29 GMT
          - "192.168.20.0/24",
Sat, 22 Jun 2024 20:59:29 GMT
        ] -> null
Sat, 22 Jun 2024 20:59:29 GMT
      - v6_cidr_blocks = [] -> null
Sat, 22 Jun 2024 20:59:29 GMT
      - zone           = "ru-central1-b" -> null
Sat, 22 Jun 2024 20:59:29 GMT
    }
Sat, 22 Jun 2024 20:59:29 GMT

Sat, 22 Jun 2024 20:59:29 GMT
  # yandex_vpc_subnet.subnet-d will be destroyed
Sat, 22 Jun 2024 20:59:29 GMT
  # (because yandex_vpc_subnet.subnet-d is not in configuration)
Sat, 22 Jun 2024 20:59:29 GMT
  - resource "yandex_vpc_subnet" "subnet-d" {
Sat, 22 Jun 2024 20:59:29 GMT
      - created_at     = "2024-06-22T15:20:12Z" -> null
Sat, 22 Jun 2024 20:59:29 GMT
      - folder_id      = "b1gcms0oj5ro6jjsgqdg" -> null
Sat, 22 Jun 2024 20:59:29 GMT
      - id             = "fl8asquatn3nu84e1mb3" -> null
Sat, 22 Jun 2024 20:59:29 GMT
      - labels         = {} -> null
Sat, 22 Jun 2024 20:59:29 GMT
      - name           = "subnet-d" -> null
Sat, 22 Jun 2024 20:59:29 GMT
      - network_id     = "enpkcdt3mcqlr1gmum67" -> null
Sat, 22 Jun 2024 20:59:29 GMT
      - v4_cidr_blocks = [
Sat, 22 Jun 2024 20:59:29 GMT
          - "192.168.30.0/24",
Sat, 22 Jun 2024 20:59:29 GMT
        ] -> null
Sat, 22 Jun 2024 20:59:29 GMT
      - v6_cidr_blocks = [] -> null
Sat, 22 Jun 2024 20:59:29 GMT
      - zone           = "ru-central1-d" -> null
Sat, 22 Jun 2024 20:59:29 GMT
    }
Sat, 22 Jun 2024 20:59:29 GMT

Sat, 22 Jun 2024 20:59:29 GMT
  # yandex_vpc_subnet.subnets[0] will be created
Sat, 22 Jun 2024 20:59:29 GMT
  + resource "yandex_vpc_subnet" "subnets" {
Sat, 22 Jun 2024 20:59:29 GMT
      + created_at     = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
      + folder_id      = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
      + id             = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
      + labels         = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
      + name           = "subnet-a"
Sat, 22 Jun 2024 20:59:29 GMT
      + network_id     = "enpkcdt3mcqlr1gmum67"
Sat, 22 Jun 2024 20:59:29 GMT
      + v4_cidr_blocks = [
Sat, 22 Jun 2024 20:59:29 GMT
          + "192.168.10.0/24",
Sat, 22 Jun 2024 20:59:29 GMT
        ]
Sat, 22 Jun 2024 20:59:29 GMT
      + v6_cidr_blocks = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
      + zone           = "ru-central1-a"
Sat, 22 Jun 2024 20:59:29 GMT
    }
Sat, 22 Jun 2024 20:59:29 GMT

Sat, 22 Jun 2024 20:59:29 GMT
  # yandex_vpc_subnet.subnets[1] will be created
Sat, 22 Jun 2024 20:59:29 GMT
  + resource "yandex_vpc_subnet" "subnets" {
Sat, 22 Jun 2024 20:59:29 GMT
      + created_at     = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
      + folder_id      = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
      + id             = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
      + labels         = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
      + name           = "subnet-b"
Sat, 22 Jun 2024 20:59:29 GMT
      + network_id     = "enpkcdt3mcqlr1gmum67"
Sat, 22 Jun 2024 20:59:29 GMT
      + v4_cidr_blocks = [
Sat, 22 Jun 2024 20:59:29 GMT
          + "192.168.20.0/24",
Sat, 22 Jun 2024 20:59:29 GMT
        ]
Sat, 22 Jun 2024 20:59:29 GMT
      + v6_cidr_blocks = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
      + zone           = "ru-central1-b"
Sat, 22 Jun 2024 20:59:29 GMT
    }
Sat, 22 Jun 2024 20:59:29 GMT

Sat, 22 Jun 2024 20:59:29 GMT
  # yandex_vpc_subnet.subnets[2] will be created
Sat, 22 Jun 2024 20:59:29 GMT
  + resource "yandex_vpc_subnet" "subnets" {
Sat, 22 Jun 2024 20:59:29 GMT
      + created_at     = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
      + folder_id      = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
      + id             = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
      + labels         = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
      + name           = "subnet-d"
Sat, 22 Jun 2024 20:59:29 GMT
      + network_id     = "enpkcdt3mcqlr1gmum67"
Sat, 22 Jun 2024 20:59:29 GMT
      + v4_cidr_blocks = [
Sat, 22 Jun 2024 20:59:29 GMT
          + "192.168.30.0/24",
Sat, 22 Jun 2024 20:59:29 GMT
        ]
Sat, 22 Jun 2024 20:59:29 GMT
      + v6_cidr_blocks = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
      + zone           = "ru-central1-d"
Sat, 22 Jun 2024 20:59:29 GMT
    }
Sat, 22 Jun 2024 20:59:29 GMT

Sat, 22 Jun 2024 20:59:29 GMT
Plan: 10 to add, 1 to change, 3 to destroy.
Sat, 22 Jun 2024 20:59:29 GMT

Sat, 22 Jun 2024 20:59:29 GMT
Changes to Outputs:
Sat, 22 Jun 2024 20:59:29 GMT
  + internal-ip-address_worker-1   = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
  + internal-ip-address_worker-2   = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
  + internal-ip-address_worker-3   = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
  + internal_ip_address_master     = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
  + master_ip_address_nat-master   = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
  + master_ip_address_nat-worker-1 = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
  + master_ip_address_nat-worker-2 = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT
  + master_ip_address_nat-worker-3 = (known after apply)
Sat, 22 Jun 2024 20:59:29 GMT

Sat, 22 Jun 2024 20:59:29 GMT
─────────────────────────────────────────────────────────────────────────────
Sat, 22 Jun 2024 20:59:29 GMT

Sat, 22 Jun 2024 20:59:29 GMT
Note: You didn't use the -out option to save this plan, so Terraform can't
Sat, 22 Jun 2024 20:59:29 GMT
guarantee to take exactly these actions if you run "terraform apply" now.
Sat, 22 Jun 2024 20:59:29 GMT



```

</details>
