# Диплом
# Оглавление:

  * [Цели:](#цели)
  * [Этапы выполнения:](#этапы-выполнения)
     * [Создание облачной инфраструктуры](#создание-облачной-инфраструктуры)
     * [Создание Kubernetes кластера](#создание-kubernetes-кластера)
     * [Создание тестового приложения](#создание-тестового-приложения)
     * [Подготовка cистемы мониторинга и деплой приложения](#подготовка-cистемы-мониторинга-и-деплой-приложения)
     * [Установка и настройка CI/CD](#установка-и-настройка-cicd)
  * [Что необходимо для сдачи задания?](#что-необходимо-для-сдачи-задания)
  * [Как правильно задавать вопросы дипломному руководителю?](#как-правильно-задавать-вопросы-дипломному-руководителю)


**Дипломное  задание доступно по [ссылке.](https://github.com/netology-code/devops-diplom-yandexcloud)**

# Решение:
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
<summary>Лог последнего коммита</summary>

```
2024-06-22T20:59:10.4050315Z Current runner version: '2.317.0'
2024-06-22T20:59:10.4073594Z ##[group]Operating System
2024-06-22T20:59:10.4074337Z Ubuntu
2024-06-22T20:59:10.4074694Z 22.04.4
2024-06-22T20:59:10.4075071Z LTS
2024-06-22T20:59:10.4075490Z ##[endgroup]
2024-06-22T20:59:10.4075900Z ##[group]Runner Image
2024-06-22T20:59:10.4076341Z Image: ubuntu-22.04
2024-06-22T20:59:10.4076818Z Version: 20240616.1.0
2024-06-22T20:59:10.4077826Z Included Software: https://github.com/actions/runner-images/blob/ubuntu22/20240616.1/images/ubuntu/Ubuntu2204-Readme.md
2024-06-22T20:59:10.4079339Z Image Release: https://github.com/actions/runner-images/releases/tag/ubuntu22%2F20240616.1
2024-06-22T20:59:10.4080227Z ##[endgroup]
2024-06-22T20:59:10.4080638Z ##[group]Runner Image Provisioner
2024-06-22T20:59:10.4081207Z 2.0.370.1
2024-06-22T20:59:10.4081576Z ##[endgroup]
2024-06-22T20:59:10.4082627Z ##[group]GITHUB_TOKEN Permissions
2024-06-22T20:59:10.4084178Z Contents: read
2024-06-22T20:59:10.4084605Z Metadata: read
2024-06-22T20:59:10.4085333Z Packages: read
2024-06-22T20:59:10.4085898Z ##[endgroup]
2024-06-22T20:59:10.4088870Z Secret source: Actions
2024-06-22T20:59:10.4089458Z Prepare workflow directory
2024-06-22T20:59:10.5045529Z Prepare all required actions
2024-06-22T20:59:10.5202753Z Getting action download info
2024-06-22T20:59:10.6594681Z Download action repository 'actions/checkout@v2' (SHA:ee0669bd1cc54295c223e0bb666b733df41de1c5)
2024-06-22T20:59:10.7701338Z Download action repository 'hashicorp/setup-terraform@v1' (SHA:ed3a0531877aca392eb870f440d9ae7aba83a6bd)
2024-06-22T20:59:11.2578418Z Complete job name: Terraform
2024-06-22T20:59:11.3415211Z ##[group]Run actions/checkout@v2
2024-06-22T20:59:11.3415915Z with:
2024-06-22T20:59:11.3416294Z   repository: Dimarkle/atlantis
2024-06-22T20:59:11.3417022Z   token: ***
2024-06-22T20:59:11.3417509Z   ssh-strict: true
2024-06-22T20:59:11.3417960Z   persist-credentials: true
2024-06-22T20:59:11.3418459Z   clean: true
2024-06-22T20:59:11.3418913Z   fetch-depth: 1
2024-06-22T20:59:11.3419324Z   lfs: false
2024-06-22T20:59:11.3419719Z   submodules: false
2024-06-22T20:59:11.3420215Z   set-safe-directory: true
2024-06-22T20:59:11.3420691Z env:
2024-06-22T20:59:11.3421223Z   AWS_ACCESS_KEY_ID: ***
2024-06-22T20:59:11.3421915Z   AWS_SECRET_ACCESS_KEY: ***
2024-06-22T20:59:11.3422657Z   YC_TOKEN: ***
2024-06-22T20:59:11.3428605Z   ID_RSA: ***
2024-06-22T20:59:11.3429025Z   working-directory: .
2024-06-22T20:59:11.3429466Z ##[endgroup]
2024-06-22T20:59:11.5408422Z Syncing repository: Dimarkle/atlantis
2024-06-22T20:59:11.5411337Z ##[group]Getting Git version info
2024-06-22T20:59:11.5413083Z Working directory is '/home/runner/work/atlantis/atlantis'
2024-06-22T20:59:11.5415035Z [command]/usr/bin/git version
2024-06-22T20:59:11.5415916Z git version 2.45.2
2024-06-22T20:59:11.5440690Z ##[endgroup]
2024-06-22T20:59:11.5460190Z Temporarily overriding HOME='/home/runner/work/_temp/3d6aea8a-5a07-4172-bb24-8c8eb9b8b1a8' before making global git config changes
2024-06-22T20:59:11.5462709Z Adding repository directory to the temporary git global config as a safe directory
2024-06-22T20:59:11.5464987Z [command]/usr/bin/git config --global --add safe.directory /home/runner/work/atlantis/atlantis
2024-06-22T20:59:11.5509983Z Deleting the contents of '/home/runner/work/atlantis/atlantis'
2024-06-22T20:59:11.5514884Z ##[group]Initializing the repository
2024-06-22T20:59:11.5518917Z [command]/usr/bin/git init /home/runner/work/atlantis/atlantis
2024-06-22T20:59:11.5611328Z hint: Using 'master' as the name for the initial branch. This default branch name
2024-06-22T20:59:11.5612913Z hint: is subject to change. To configure the initial branch name to use in all
2024-06-22T20:59:11.5614723Z hint: of your new repositories, which will suppress this warning, call:
2024-06-22T20:59:11.5615618Z hint:
2024-06-22T20:59:11.5616664Z hint: 	git config --global init.defaultBranch <name>
2024-06-22T20:59:11.5617770Z hint:
2024-06-22T20:59:11.5618996Z hint: Names commonly chosen instead of 'master' are 'main', 'trunk' and
2024-06-22T20:59:11.5621424Z hint: 'development'. The just-created branch can be renamed via this command:
2024-06-22T20:59:11.5622743Z hint:
2024-06-22T20:59:11.5623448Z hint: 	git branch -m <name>
2024-06-22T20:59:11.5624969Z Initialized empty Git repository in /home/runner/work/atlantis/atlantis/.git/
2024-06-22T20:59:11.5626843Z [command]/usr/bin/git remote add origin https://github.com/Dimarkle/atlantis
2024-06-22T20:59:11.5672542Z ##[endgroup]
2024-06-22T20:59:11.5674301Z ##[group]Disabling automatic garbage collection
2024-06-22T20:59:11.5677080Z [command]/usr/bin/git config --local gc.auto 0
2024-06-22T20:59:11.5717799Z ##[endgroup]
2024-06-22T20:59:11.5719359Z ##[group]Setting up auth
2024-06-22T20:59:11.5731934Z [command]/usr/bin/git config --local --name-only --get-regexp core\.sshCommand
2024-06-22T20:59:11.5774378Z [command]/usr/bin/git submodule foreach --recursive sh -c "git config --local --name-only --get-regexp 'core\.sshCommand' && git config --local --unset-all 'core.sshCommand' || :"
2024-06-22T20:59:11.6105402Z [command]/usr/bin/git config --local --name-only --get-regexp http\.https\:\/\/github\.com\/\.extraheader
2024-06-22T20:59:11.6143188Z [command]/usr/bin/git submodule foreach --recursive sh -c "git config --local --name-only --get-regexp 'http\.https\:\/\/github\.com\/\.extraheader' && git config --local --unset-all 'http.https://github.com/.extraheader' || :"
2024-06-22T20:59:11.6399195Z [command]/usr/bin/git config --local http.https://github.com/.extraheader AUTHORIZATION: basic ***
2024-06-22T20:59:11.6454113Z ##[endgroup]
2024-06-22T20:59:11.6455492Z ##[group]Fetching the repository
2024-06-22T20:59:11.6464761Z [command]/usr/bin/git -c protocol.version=2 fetch --no-tags --prune --progress --no-recurse-submodules --depth=1 origin +42e3263c785475dc66752ad3d241015e1075492a:refs/remotes/origin/main
2024-06-22T20:59:11.8948453Z remote: Enumerating objects: 37, done.        
2024-06-22T20:59:11.8950037Z remote: Counting objects:   2% (1/37)        
2024-06-22T20:59:11.8951101Z remote: Counting objects:   5% (2/37)        
2024-06-22T20:59:11.8952109Z remote: Counting objects:   8% (3/37)        
2024-06-22T20:59:11.8952723Z remote: Counting objects:  10% (4/37)        
2024-06-22T20:59:11.8953375Z remote: Counting objects:  13% (5/37)        
2024-06-22T20:59:11.8953881Z remote: Counting objects:  16% (6/37)        
2024-06-22T20:59:11.8954376Z remote: Counting objects:  18% (7/37)        
2024-06-22T20:59:11.8954971Z remote: Counting objects:  21% (8/37)        
2024-06-22T20:59:11.8955476Z remote: Counting objects:  24% (9/37)        
2024-06-22T20:59:11.8956079Z remote: Counting objects:  27% (10/37)        
2024-06-22T20:59:11.8956589Z remote: Counting objects:  29% (11/37)        
2024-06-22T20:59:11.8957086Z remote: Counting objects:  32% (12/37)        
2024-06-22T20:59:11.8957786Z remote: Counting objects:  35% (13/37)        
2024-06-22T20:59:11.8958312Z remote: Counting objects:  37% (14/37)        
2024-06-22T20:59:11.8958843Z remote: Counting objects:  40% (15/37)        
2024-06-22T20:59:11.8959401Z remote: Counting objects:  43% (16/37)        
2024-06-22T20:59:11.8959882Z remote: Counting objects:  45% (17/37)        
2024-06-22T20:59:11.8960445Z remote: Counting objects:  48% (18/37)        
2024-06-22T20:59:11.8960940Z remote: Counting objects:  51% (19/37)        
2024-06-22T20:59:11.8961386Z remote: Counting objects:  54% (20/37)        
2024-06-22T20:59:11.8961962Z remote: Counting objects:  56% (21/37)        
2024-06-22T20:59:11.8962464Z remote: Counting objects:  59% (22/37)        
2024-06-22T20:59:11.8962973Z remote: Counting objects:  62% (23/37)        
2024-06-22T20:59:11.8963551Z remote: Counting objects:  64% (24/37)        
2024-06-22T20:59:11.8964048Z remote: Counting objects:  67% (25/37)        
2024-06-22T20:59:11.8964569Z remote: Counting objects:  70% (26/37)        
2024-06-22T20:59:11.8965126Z remote: Counting objects:  72% (27/37)        
2024-06-22T20:59:11.8965675Z remote: Counting objects:  75% (28/37)        
2024-06-22T20:59:11.8966338Z remote: Counting objects:  78% (29/37)        
2024-06-22T20:59:11.8967206Z remote: Counting objects:  81% (30/37)        
2024-06-22T20:59:11.8967694Z remote: Counting objects:  83% (31/37)        
2024-06-22T20:59:11.8968259Z remote: Counting objects:  86% (32/37)        
2024-06-22T20:59:11.8968851Z remote: Counting objects:  89% (33/37)        
2024-06-22T20:59:11.8969342Z remote: Counting objects:  91% (34/37)        
2024-06-22T20:59:11.8969924Z remote: Counting objects:  94% (35/37)        
2024-06-22T20:59:11.8970405Z remote: Counting objects:  97% (36/37)        
2024-06-22T20:59:11.8970960Z remote: Counting objects: 100% (37/37)        
2024-06-22T20:59:11.8971549Z remote: Counting objects: 100% (37/37), done.        
2024-06-22T20:59:11.8972098Z remote: Compressing objects:   4% (1/22)        
2024-06-22T20:59:11.8972917Z remote: Compressing objects:   9% (2/22)        
2024-06-22T20:59:11.8973443Z remote: Compressing objects:  13% (3/22)        
2024-06-22T20:59:11.8973970Z remote: Compressing objects:  18% (4/22)        
2024-06-22T20:59:11.8974598Z remote: Compressing objects:  22% (5/22)        
2024-06-22T20:59:11.8975118Z remote: Compressing objects:  27% (6/22)        
2024-06-22T20:59:11.8975635Z remote: Compressing objects:  31% (7/22)        
2024-06-22T20:59:11.8976240Z remote: Compressing objects:  36% (8/22)        
2024-06-22T20:59:11.8976751Z remote: Compressing objects:  40% (9/22)        
2024-06-22T20:59:11.8977351Z remote: Compressing objects:  45% (10/22)        
2024-06-22T20:59:11.8977878Z remote: Compressing objects:  50% (11/22)        
2024-06-22T20:59:11.8978624Z remote: Compressing objects:  54% (12/22)        
2024-06-22T20:59:11.8979235Z remote: Compressing objects:  59% (13/22)        
2024-06-22T20:59:11.8979737Z remote: Compressing objects:  63% (14/22)        
2024-06-22T20:59:11.8980254Z remote: Compressing objects:  68% (15/22)        
2024-06-22T20:59:11.8980834Z remote: Compressing objects:  72% (16/22)        
2024-06-22T20:59:11.8981354Z remote: Compressing objects:  77% (17/22)        
2024-06-22T20:59:11.8981938Z remote: Compressing objects:  81% (18/22)        
2024-06-22T20:59:11.8982444Z remote: Compressing objects:  86% (19/22)        
2024-06-22T20:59:11.8982958Z remote: Compressing objects:  90% (20/22)        
2024-06-22T20:59:11.8983534Z remote: Compressing objects:  95% (21/22)        
2024-06-22T20:59:11.8984051Z remote: Compressing objects: 100% (22/22)        
2024-06-22T20:59:11.8984564Z remote: Compressing objects: 100% (22/22), done.        
2024-06-22T20:59:14.3193214Z remote: Total 37 (delta 3), reused 25 (delta 3), pack-reused 0        
2024-06-22T20:59:15.5946871Z From https://github.com/Dimarkle/atlantis
2024-06-22T20:59:15.5948272Z  * [new ref]         42e3263c785475dc66752ad3d241015e1075492a -> origin/main
2024-06-22T20:59:15.5973143Z ##[endgroup]
2024-06-22T20:59:15.5973921Z ##[group]Determining the checkout info
2024-06-22T20:59:15.5975261Z ##[endgroup]
2024-06-22T20:59:15.5976176Z ##[group]Checking out the ref
2024-06-22T20:59:15.5981050Z [command]/usr/bin/git checkout --progress --force -B main refs/remotes/origin/main
2024-06-22T20:59:16.3211132Z Switched to a new branch 'main'
2024-06-22T20:59:16.3212179Z branch 'main' set up to track 'origin/main'.
2024-06-22T20:59:16.3218618Z ##[endgroup]
2024-06-22T20:59:16.3272315Z [command]/usr/bin/git log -1 --format='%H'
2024-06-22T20:59:16.3306488Z '42e3263c785475dc66752ad3d241015e1075492a'
2024-06-22T20:59:16.3616319Z ##[group]Run echo $ID_RSA > id_rsa.pub
2024-06-22T20:59:16.3616882Z [36;1mecho $ID_RSA > id_rsa.pub[0m
2024-06-22T20:59:16.3739687Z shell: /usr/bin/bash -e {0}
2024-06-22T20:59:16.3740132Z env:
2024-06-22T20:59:16.3740846Z   AWS_ACCESS_KEY_ID: ***
2024-06-22T20:59:16.3741489Z   AWS_SECRET_ACCESS_KEY: ***
2024-06-22T20:59:16.3742071Z   YC_TOKEN: ***
2024-06-22T20:59:16.3745870Z   ID_RSA: ***
2024-06-22T20:59:16.3746221Z   working-directory: .
2024-06-22T20:59:16.3746670Z ##[endgroup]
2024-06-22T20:59:16.3965841Z ##[group]Run hashicorp/setup-terraform@v1
2024-06-22T20:59:16.3966324Z with:
2024-06-22T20:59:16.3966663Z   terraform_version: 1.5.2
2024-06-22T20:59:16.3967430Z   cli_config_credentials_hostname: app.terraform.io
2024-06-22T20:59:16.3967926Z   terraform_wrapper: true
2024-06-22T20:59:16.3968273Z env:
2024-06-22T20:59:16.3968797Z   AWS_ACCESS_KEY_ID: ***
2024-06-22T20:59:16.3969372Z   AWS_SECRET_ACCESS_KEY: ***
2024-06-22T20:59:16.3970018Z   YC_TOKEN: ***
2024-06-22T20:59:16.3973808Z   ID_RSA: ***
2024-06-22T20:59:16.3974183Z   working-directory: .
2024-06-22T20:59:16.3974655Z ##[endgroup]
2024-06-22T20:59:16.5907931Z (node:1716) [DEP0005] DeprecationWarning: Buffer() is deprecated due to security and usability issues. Please use the Buffer.alloc(), Buffer.allocUnsafe(), or Buffer.from() methods instead.
2024-06-22T20:59:16.5909491Z (Use `node --trace-deprecation ...` to show where the warning was created)
2024-06-22T20:59:16.8261551Z [command]/usr/bin/unzip -o -q /home/runner/work/_temp/f03a70bd-9c2d-4021-a59f-94ad64109108
2024-06-22T20:59:17.3992826Z ##[group]Run terraform init
2024-06-22T20:59:17.3993388Z [36;1mterraform init[0m
2024-06-22T20:59:17.4055950Z shell: /usr/bin/bash -e {0}
2024-06-22T20:59:17.4056375Z env:
2024-06-22T20:59:17.4056863Z   AWS_ACCESS_KEY_ID: ***
2024-06-22T20:59:17.4057483Z   AWS_SECRET_ACCESS_KEY: ***
2024-06-22T20:59:17.4058073Z   YC_TOKEN: ***
2024-06-22T20:59:17.4061649Z   ID_RSA: ***
2024-06-22T20:59:17.4062016Z   working-directory: .
2024-06-22T20:59:17.4062570Z   TERRAFORM_CLI_PATH: /home/runner/work/_temp/6c9cc6c2-e715-4381-91b4-37e6a39908ff
2024-06-22T20:59:17.4063226Z ##[endgroup]
2024-06-22T20:59:17.5790979Z [command]/home/runner/work/_temp/6c9cc6c2-e715-4381-91b4-37e6a39908ff/terraform-bin init
2024-06-22T20:59:17.6086453Z 
2024-06-22T20:59:17.6087503Z [0m[1mInitializing the backend...[0m
2024-06-22T20:59:18.4829025Z [0m[32m
2024-06-22T20:59:18.4830004Z Successfully configured the backend "s3"! Terraform will automatically
2024-06-22T20:59:18.4831723Z use this backend unless the backend configuration changes.[0m
2024-06-22T20:59:19.6881183Z 
2024-06-22T20:59:19.6882748Z [0m[1mInitializing provider plugins...[0m
2024-06-22T20:59:19.6884596Z - Finding latest version of hashicorp/local...
2024-06-22T20:59:19.8229279Z - Finding latest version of yandex-cloud/yandex...
2024-06-22T20:59:19.9608575Z - Installing hashicorp/local v2.5.1...
2024-06-22T20:59:20.1550799Z - Installed hashicorp/local v2.5.1 (signed by HashiCorp)
2024-06-22T20:59:20.5966799Z - Installing yandex-cloud/yandex v0.122.0...
2024-06-22T20:59:21.4221615Z - Installed yandex-cloud/yandex v0.122.0 (self-signed, key ID [0m[1mE40F590B50BB8E40[0m[0m)
2024-06-22T20:59:21.4223206Z 
2024-06-22T20:59:21.4223884Z Partner and community providers are signed by their developers.
2024-06-22T20:59:21.4225491Z If you'd like to know more about provider signing, you can read about it here:
2024-06-22T20:59:21.4226686Z https://www.terraform.io/docs/cli/plugins/signing.html
2024-06-22T20:59:21.4227299Z 
2024-06-22T20:59:21.4228093Z Terraform has created a lock file [1m.terraform.lock.hcl[0m to record the provider
2024-06-22T20:59:21.4229470Z selections it made above. Include this file in your version control repository
2024-06-22T20:59:21.4230736Z so that Terraform can guarantee to make the same selections by default when
2024-06-22T20:59:21.4231932Z you run "terraform init" in the future.[0m
2024-06-22T20:59:21.4232492Z 
2024-06-22T20:59:21.4233059Z [0m[1m[32mTerraform has been successfully initialized![0m[32m[0m
2024-06-22T20:59:21.4233958Z [0m[32m
2024-06-22T20:59:21.4234881Z You may now begin working with Terraform. Try running "terraform plan" to see
2024-06-22T20:59:21.4236159Z any changes that are required for your infrastructure. All Terraform commands
2024-06-22T20:59:21.4237210Z should now work.
2024-06-22T20:59:21.4237501Z 
2024-06-22T20:59:21.4238041Z If you ever set or change modules or backend configuration for Terraform,
2024-06-22T20:59:21.4239316Z rerun this command to reinitialize your working directory. If you forget, other
2024-06-22T20:59:21.4240821Z commands will detect it and remind you to do so if necessary.[0m
2024-06-22T20:59:21.4275682Z 
2024-06-22T20:59:21.4290320Z ##[warning]The `set-output` command is deprecated and will be disabled soon. Please upgrade to using Environment Files. For more information see: https://github.blog/changelog/2022-10-11-github-actions-deprecating-save-state-and-set-output-commands/
2024-06-22T20:59:21.4315389Z 
2024-06-22T20:59:21.4320550Z ##[warning]The `set-output` command is deprecated and will be disabled soon. Please upgrade to using Environment Files. For more information see: https://github.blog/changelog/2022-10-11-github-actions-deprecating-save-state-and-set-output-commands/
2024-06-22T20:59:21.4323767Z 
2024-06-22T20:59:21.4328757Z ##[warning]The `set-output` command is deprecated and will be disabled soon. Please upgrade to using Environment Files. For more information see: https://github.blog/changelog/2022-10-11-github-actions-deprecating-save-state-and-set-output-commands/
2024-06-22T20:59:21.4380946Z ##[group]Run terraform plan
2024-06-22T20:59:21.4381514Z [36;1mterraform plan[0m
2024-06-22T20:59:21.4443297Z shell: /usr/bin/bash -e {0}
2024-06-22T20:59:21.4443766Z env:
2024-06-22T20:59:21.4444279Z   AWS_ACCESS_KEY_ID: ***
2024-06-22T20:59:21.4444932Z   AWS_SECRET_ACCESS_KEY: ***
2024-06-22T20:59:21.4445540Z   YC_TOKEN: ***
2024-06-22T20:59:21.4449016Z   ID_RSA: ***
2024-06-22T20:59:21.4449456Z   working-directory: .
2024-06-22T20:59:21.4450016Z   TERRAFORM_CLI_PATH: /home/runner/work/_temp/6c9cc6c2-e715-4381-91b4-37e6a39908ff
2024-06-22T20:59:21.4450614Z ##[endgroup]
2024-06-22T20:59:21.4973228Z [command]/home/runner/work/_temp/6c9cc6c2-e715-4381-91b4-37e6a39908ff/terraform-bin plan
2024-06-22T20:59:23.3891720Z [0m[1mlocal_file.backendConf: Refreshing state... [id=d4c60048d3c028b00e1cab40288f633d4f732d21][0m
2024-06-22T20:59:23.4333645Z [0m[1myandex_vpc_subnet.subnet-d: Refreshing state... [id=fl8asquatn3nu84e1mb3][0m
2024-06-22T20:59:23.4342403Z [0m[1myandex_kms_symmetric_key.key-a: Refreshing state... [id=abjsrl1q6fs6g1angqk0][0m
2024-06-22T20:59:23.4345722Z [0m[1myandex_vpc_network.net: Refreshing state... [id=enpkcdt3mcqlr1gmum67][0m
2024-06-22T20:59:23.4350736Z [0m[1myandex_vpc_subnet.subnet-b: Refreshing state... [id=e2lupau8bgpa84pspf97][0m
2024-06-22T20:59:23.4352652Z [0m[1myandex_iam_service_account.diman-diplom: Refreshing state... [id=ajedsrhv4ua9ld7t22ph][0m
2024-06-22T20:59:23.4368271Z [0m[1myandex_vpc_subnet.subnet-a: Refreshing state... [id=e9brv9lccdmvglc35fnc][0m
2024-06-22T20:59:26.0668736Z [0m[1myandex_iam_service_account_static_access_key.bucket-static_access_key: Refreshing state... [id=ajepl81chs3qstnmq1jt][0m
2024-06-22T20:59:26.0672003Z [0m[1myandex_resourcemanager_folder_iam_binding.storage-admin: Refreshing state... [id=b1gcms0oj5ro6jjsgqdg/storage.admin][0m
2024-06-22T20:59:26.0674963Z [0m[1myandex_resourcemanager_folder_iam_binding.encrypterDecrypter: Refreshing state... [id=b1gcms0oj5ro6jjsgqdg/kms.keys.encrypterDecrypter][0m
2024-06-22T20:59:26.2852047Z [0m[1myandex_storage_bucket.diman-diplom: Refreshing state... [id=diman-diplom][0m
2024-06-22T20:59:29.5513379Z 
2024-06-22T20:59:29.5514525Z Terraform used the selected providers to generate the following execution
2024-06-22T20:59:29.5516065Z plan. Resource actions are indicated with the following symbols:
2024-06-22T20:59:29.5519192Z   [32m+[0m create[0m
2024-06-22T20:59:29.5520378Z   [33m~[0m update in-place[0m
2024-06-22T20:59:29.5521594Z   [31m-[0m destroy[0m
2024-06-22T20:59:29.5522256Z 
2024-06-22T20:59:29.5522745Z Terraform will perform the following actions:
2024-06-22T20:59:29.5523576Z 
2024-06-22T20:59:29.5524565Z [1m  # local_file.inventory-kubespray[0m will be created
2024-06-22T20:59:29.5525940Z [0m  [32m+[0m[0m resource "local_file" "inventory-kubespray" {
2024-06-22T20:59:29.5527424Z       [32m+[0m[0m content              = (known after apply)
2024-06-22T20:59:29.5529008Z       [32m+[0m[0m content_base64sha256 = (known after apply)
2024-06-22T20:59:29.5530591Z       [32m+[0m[0m content_base64sha512 = (known after apply)
2024-06-22T20:59:29.5532413Z       [32m+[0m[0m content_md5          = (known after apply)
2024-06-22T20:59:29.5533664Z       [32m+[0m[0m content_sha1         = (known after apply)
2024-06-22T20:59:29.5534325Z       [32m+[0m[0m content_sha256       = (known after apply)
2024-06-22T20:59:29.5534946Z       [32m+[0m[0m content_sha512       = (known after apply)
2024-06-22T20:59:29.5535615Z       [32m+[0m[0m directory_permission = "0777"
2024-06-22T20:59:29.5536210Z       [32m+[0m[0m file_permission      = "0777"
2024-06-22T20:59:29.5536855Z       [32m+[0m[0m filename             = "../ansible/inventory-kubespray"
2024-06-22T20:59:29.5562973Z       [32m+[0m[0m id                   = (known after apply)
2024-06-22T20:59:29.5564029Z     }
2024-06-22T20:59:29.5564434Z 
2024-06-22T20:59:29.5565123Z [1m  # local_file.inventory-preparation[0m will be created
2024-06-22T20:59:29.5567415Z [0m  [32m+[0m[0m resource "local_file" "inventory-preparation" {
2024-06-22T20:59:29.5568900Z       [32m+[0m[0m content              = (known after apply)
2024-06-22T20:59:29.5570324Z       [32m+[0m[0m content_base64sha256 = (known after apply)
2024-06-22T20:59:29.5571523Z       [32m+[0m[0m content_base64sha512 = (known after apply)
2024-06-22T20:59:29.5573242Z       [32m+[0m[0m content_md5          = (known after apply)
2024-06-22T20:59:29.5574635Z       [32m+[0m[0m content_sha1         = (known after apply)
2024-06-22T20:59:29.5575792Z       [32m+[0m[0m content_sha256       = (known after apply)
2024-06-22T20:59:29.5576943Z       [32m+[0m[0m content_sha512       = (known after apply)
2024-06-22T20:59:29.5578199Z       [32m+[0m[0m directory_permission = "0777"
2024-06-22T20:59:29.5579208Z       [32m+[0m[0m file_permission      = "0777"
2024-06-22T20:59:29.5580574Z       [32m+[0m[0m filename             = "../ansible/inventory-preparation"
2024-06-22T20:59:29.5581838Z       [32m+[0m[0m id                   = (known after apply)
2024-06-22T20:59:29.5582720Z     }
2024-06-22T20:59:29.5583011Z 
2024-06-22T20:59:29.5583776Z [1m  # yandex_compute_instance.vms["master"][0m will be created
2024-06-22T20:59:29.5585032Z [0m  [32m+[0m[0m resource "yandex_compute_instance" "vms" {
2024-06-22T20:59:29.5586280Z       [32m+[0m[0m created_at                = (known after apply)
2024-06-22T20:59:29.5587706Z       [32m+[0m[0m folder_id                 = (known after apply)
2024-06-22T20:59:29.5588958Z       [32m+[0m[0m fqdn                      = (known after apply)
2024-06-22T20:59:29.5590347Z       [32m+[0m[0m gpu_cluster_id            = (known after apply)
2024-06-22T20:59:29.5591515Z       [32m+[0m[0m hostname                  = "master"
2024-06-22T20:59:29.5592527Z       [32m+[0m[0m id                        = (known after apply)
2024-06-22T20:59:29.5593733Z       [32m+[0m[0m maintenance_grace_period  = (known after apply)
2024-06-22T20:59:29.5594890Z       [32m+[0m[0m maintenance_policy        = (known after apply)
2024-06-22T20:59:29.5595997Z       [32m+[0m[0m metadata                  = {
2024-06-22T20:59:29.5597043Z           [32m+[0m[0m "ssh-keys" = <<-EOT
2024-06-22T20:59:29.5604370Z                 ubuntu:***
2024-06-22T20:59:29.5604984Z             EOT
2024-06-22T20:59:29.5605673Z         }
2024-06-22T20:59:29.5606446Z       [32m+[0m[0m name                      = "master"
2024-06-22T20:59:29.5607394Z       [32m+[0m[0m network_acceleration_type = "standard"
2024-06-22T20:59:29.5608520Z       [32m+[0m[0m platform_id               = "standard-v3"
2024-06-22T20:59:29.5609642Z       [32m+[0m[0m service_account_id        = (known after apply)
2024-06-22T20:59:29.5610809Z       [32m+[0m[0m status                    = (known after apply)
2024-06-22T20:59:29.5611995Z       [32m+[0m[0m zone                      = "ru-central1-a"
2024-06-22T20:59:29.5612544Z 
2024-06-22T20:59:29.5613097Z       [32m+[0m[0m boot_disk {
2024-06-22T20:59:29.5614068Z           [32m+[0m[0m auto_delete = true
2024-06-22T20:59:29.5615044Z           [32m+[0m[0m device_name = (known after apply)
2024-06-22T20:59:29.5616507Z           [32m+[0m[0m disk_id     = (known after apply)
2024-06-22T20:59:29.5617542Z           [32m+[0m[0m mode        = (known after apply)
2024-06-22T20:59:29.5618205Z 
2024-06-22T20:59:29.5618600Z           [32m+[0m[0m initialize_params {
2024-06-22T20:59:29.5619672Z               [32m+[0m[0m block_size  = (known after apply)
2024-06-22T20:59:29.5620621Z               [32m+[0m[0m description = (known after apply)
2024-06-22T20:59:29.5621692Z               [32m+[0m[0m image_id    = "fd8di2mid9ojikcm93en"
2024-06-22T20:59:29.5622616Z               [32m+[0m[0m name        = (known after apply)
2024-06-22T20:59:29.5623536Z               [32m+[0m[0m size        = 30
2024-06-22T20:59:29.5624393Z               [32m+[0m[0m snapshot_id = (known after apply)
2024-06-22T20:59:29.5625683Z               [32m+[0m[0m type        = "network-hdd"
2024-06-22T20:59:29.5626462Z             }
2024-06-22T20:59:29.5626977Z         }
2024-06-22T20:59:29.5627390Z 
2024-06-22T20:59:29.5627701Z       [32m+[0m[0m network_interface {
2024-06-22T20:59:29.5628617Z           [32m+[0m[0m index              = (known after apply)
2024-06-22T20:59:29.5629633Z           [32m+[0m[0m ip_address         = (known after apply)
2024-06-22T20:59:29.5630699Z           [32m+[0m[0m ipv4               = true
2024-06-22T20:59:29.5631624Z           [32m+[0m[0m ipv6               = (known after apply)
2024-06-22T20:59:29.5632724Z           [32m+[0m[0m ipv6_address       = (known after apply)
2024-06-22T20:59:29.5633743Z           [32m+[0m[0m mac_address        = (known after apply)
2024-06-22T20:59:29.5634647Z           [32m+[0m[0m nat                = true
2024-06-22T20:59:29.5635695Z           [32m+[0m[0m nat_ip_address     = (known after apply)
2024-06-22T20:59:29.5636749Z           [32m+[0m[0m nat_ip_version     = (known after apply)
2024-06-22T20:59:29.5637380Z           [32m+[0m[0m security_group_ids = (known after apply)
2024-06-22T20:59:29.5638132Z           [32m+[0m[0m subnet_id          = (known after apply)
2024-06-22T20:59:29.5638967Z         }
2024-06-22T20:59:29.5639234Z 
2024-06-22T20:59:29.5639693Z       [32m+[0m[0m resources {
2024-06-22T20:59:29.5640383Z           [32m+[0m[0m core_fraction = 100
2024-06-22T20:59:29.5641075Z           [32m+[0m[0m cores         = 4
2024-06-22T20:59:29.5641922Z           [32m+[0m[0m memory        = 4
2024-06-22T20:59:29.5642548Z         }
2024-06-22T20:59:29.5642982Z     }
2024-06-22T20:59:29.5643342Z 
2024-06-22T20:59:29.5643869Z [1m  # yandex_compute_instance.vms["worker-1"][0m will be created
2024-06-22T20:59:29.5644940Z [0m  [32m+[0m[0m resource "yandex_compute_instance" "vms" {
2024-06-22T20:59:29.5645982Z       [32m+[0m[0m created_at                = (known after apply)
2024-06-22T20:59:29.5647115Z       [32m+[0m[0m folder_id                 = (known after apply)
2024-06-22T20:59:29.5648110Z       [32m+[0m[0m fqdn                      = (known after apply)
2024-06-22T20:59:29.5649281Z       [32m+[0m[0m gpu_cluster_id            = (known after apply)
2024-06-22T20:59:29.5650360Z       [32m+[0m[0m hostname                  = "worker-1"
2024-06-22T20:59:29.5651425Z       [32m+[0m[0m id                        = (known after apply)
2024-06-22T20:59:29.5652345Z       [32m+[0m[0m maintenance_grace_period  = (known after apply)
2024-06-22T20:59:29.5653336Z       [32m+[0m[0m maintenance_policy        = (known after apply)
2024-06-22T20:59:29.5653928Z       [32m+[0m[0m metadata                  = {
2024-06-22T20:59:29.5654548Z           [32m+[0m[0m "ssh-keys" = <<-EOT
2024-06-22T20:59:29.5658618Z                 ubuntu:***
2024-06-22T20:59:29.5659065Z             EOT
2024-06-22T20:59:29.5659409Z         }
2024-06-22T20:59:29.5659841Z       [32m+[0m[0m name                      = "worker-1"
2024-06-22T20:59:29.5660477Z       [32m+[0m[0m network_acceleration_type = "standard"
2024-06-22T20:59:29.5661105Z       [32m+[0m[0m platform_id               = "standard-v3"
2024-06-22T20:59:29.5661957Z       [32m+[0m[0m service_account_id        = (known after apply)
2024-06-22T20:59:29.5662698Z       [32m+[0m[0m status                    = (known after apply)
2024-06-22T20:59:29.5663333Z       [32m+[0m[0m zone                      = "ru-central1-a"
2024-06-22T20:59:29.5663701Z 
2024-06-22T20:59:29.5663866Z       [32m+[0m[0m boot_disk {
2024-06-22T20:59:29.5664426Z           [32m+[0m[0m auto_delete = true
2024-06-22T20:59:29.5664978Z           [32m+[0m[0m device_name = (known after apply)
2024-06-22T20:59:29.5665635Z           [32m+[0m[0m disk_id     = (known after apply)
2024-06-22T20:59:29.5666204Z           [32m+[0m[0m mode        = (known after apply)
2024-06-22T20:59:29.5666547Z 
2024-06-22T20:59:29.5666744Z           [32m+[0m[0m initialize_params {
2024-06-22T20:59:29.5667374Z               [32m+[0m[0m block_size  = (known after apply)
2024-06-22T20:59:29.5668101Z               [32m+[0m[0m description = (known after apply)
2024-06-22T20:59:29.5668758Z               [32m+[0m[0m image_id    = "fd8di2mid9ojikcm93en"
2024-06-22T20:59:29.5669430Z               [32m+[0m[0m name        = (known after apply)
2024-06-22T20:59:29.5669960Z               [32m+[0m[0m size        = 30
2024-06-22T20:59:29.5670604Z               [32m+[0m[0m snapshot_id = (known after apply)
2024-06-22T20:59:29.5671176Z               [32m+[0m[0m type        = "network-hdd"
2024-06-22T20:59:29.5671818Z             }
2024-06-22T20:59:29.5672321Z         }
2024-06-22T20:59:29.5672855Z 
2024-06-22T20:59:29.5673218Z       [32m+[0m[0m network_interface {
2024-06-22T20:59:29.5674005Z           [32m+[0m[0m index              = (known after apply)
2024-06-22T20:59:29.5674610Z           [32m+[0m[0m ip_address         = (known after apply)
2024-06-22T20:59:29.5675178Z           [32m+[0m[0m ipv4               = true
2024-06-22T20:59:29.5675831Z           [32m+[0m[0m ipv6               = (known after apply)
2024-06-22T20:59:29.5676439Z           [32m+[0m[0m ipv6_address       = (known after apply)
2024-06-22T20:59:29.5677051Z           [32m+[0m[0m mac_address        = (known after apply)
2024-06-22T20:59:29.5677673Z           [32m+[0m[0m nat                = true
2024-06-22T20:59:29.5678253Z           [32m+[0m[0m nat_ip_address     = (known after apply)
2024-06-22T20:59:29.5678919Z           [32m+[0m[0m nat_ip_version     = (known after apply)
2024-06-22T20:59:29.5679515Z           [32m+[0m[0m security_group_ids = (known after apply)
2024-06-22T20:59:29.5680121Z           [32m+[0m[0m subnet_id          = (known after apply)
2024-06-22T20:59:29.5680664Z         }
2024-06-22T20:59:29.5680862Z 
2024-06-22T20:59:29.5681049Z       [32m+[0m[0m resources {
2024-06-22T20:59:29.5681513Z           [32m+[0m[0m core_fraction = 100
2024-06-22T20:59:29.5682087Z           [32m+[0m[0m cores         = 4
2024-06-22T20:59:29.5682591Z           [32m+[0m[0m memory        = 4
2024-06-22T20:59:29.5683067Z         }
2024-06-22T20:59:29.5683399Z     }
2024-06-22T20:59:29.5683552Z 
2024-06-22T20:59:29.5683893Z [1m  # yandex_compute_instance.vms["worker-2"][0m will be created
2024-06-22T20:59:29.5684639Z [0m  [32m+[0m[0m resource "yandex_compute_instance" "vms" {
2024-06-22T20:59:29.5685317Z       [32m+[0m[0m created_at                = (known after apply)
2024-06-22T20:59:29.5685935Z       [32m+[0m[0m folder_id                 = (known after apply)
2024-06-22T20:59:29.5686642Z       [32m+[0m[0m fqdn                      = (known after apply)
2024-06-22T20:59:29.5687297Z       [32m+[0m[0m gpu_cluster_id            = (known after apply)
2024-06-22T20:59:29.5687905Z       [32m+[0m[0m hostname                  = "worker-2"
2024-06-22T20:59:29.5688610Z       [32m+[0m[0m id                        = (known after apply)
2024-06-22T20:59:29.5689250Z       [32m+[0m[0m maintenance_grace_period  = (known after apply)
2024-06-22T20:59:29.5689982Z       [32m+[0m[0m maintenance_policy        = (known after apply)
2024-06-22T20:59:29.5690747Z       [32m+[0m[0m metadata                  = {
2024-06-22T20:59:29.5691259Z           [32m+[0m[0m "ssh-keys" = <<-EOT
2024-06-22T20:59:29.5695701Z                 ubuntu:***
2024-06-22T20:59:29.5696092Z             EOT
2024-06-22T20:59:29.5696440Z         }
2024-06-22T20:59:29.5696983Z       [32m+[0m[0m name                      = "worker-2"
2024-06-22T20:59:29.5697582Z       [32m+[0m[0m network_acceleration_type = "standard"
2024-06-22T20:59:29.5698295Z       [32m+[0m[0m platform_id               = "standard-v3"
2024-06-22T20:59:29.5698932Z       [32m+[0m[0m service_account_id        = (known after apply)
2024-06-22T20:59:29.5699592Z       [32m+[0m[0m status                    = (known after apply)
2024-06-22T20:59:29.5700293Z       [32m+[0m[0m zone                      = "ru-central1-b"
2024-06-22T20:59:29.5700629Z 
2024-06-22T20:59:29.5700826Z       [32m+[0m[0m boot_disk {
2024-06-22T20:59:29.5701459Z           [32m+[0m[0m auto_delete = true
2024-06-22T20:59:29.5702100Z           [32m+[0m[0m device_name = (known after apply)
2024-06-22T20:59:29.5702691Z           [32m+[0m[0m disk_id     = (known after apply)
2024-06-22T20:59:29.5703222Z           [32m+[0m[0m mode        = (known after apply)
2024-06-22T20:59:29.5703654Z 
2024-06-22T20:59:29.5703855Z           [32m+[0m[0m initialize_params {
2024-06-22T20:59:29.5704431Z               [32m+[0m[0m block_size  = (known after apply)
2024-06-22T20:59:29.5705105Z               [32m+[0m[0m description = (known after apply)
2024-06-22T20:59:29.5705742Z               [32m+[0m[0m image_id    = "fd8di2mid9ojikcm93en"
2024-06-22T20:59:29.5706343Z               [32m+[0m[0m name        = (known after apply)
2024-06-22T20:59:29.5706940Z               [32m+[0m[0m size        = 30
2024-06-22T20:59:29.5707497Z               [32m+[0m[0m snapshot_id = (known after apply)
2024-06-22T20:59:29.5708072Z               [32m+[0m[0m type        = "network-hdd"
2024-06-22T20:59:29.5708604Z             }
2024-06-22T20:59:29.5708920Z         }
2024-06-22T20:59:29.5709080Z 
2024-06-22T20:59:29.5709365Z       [32m+[0m[0m network_interface {
2024-06-22T20:59:29.5709936Z           [32m+[0m[0m index              = (known after apply)
2024-06-22T20:59:29.5710545Z           [32m+[0m[0m ip_address         = (known after apply)
2024-06-22T20:59:29.5711183Z           [32m+[0m[0m ipv4               = true
2024-06-22T20:59:29.5711743Z           [32m+[0m[0m ipv6               = (known after apply)
2024-06-22T20:59:29.5712353Z           [32m+[0m[0m ipv6_address       = (known after apply)
2024-06-22T20:59:29.5713028Z           [32m+[0m[0m mac_address        = (known after apply)
2024-06-22T20:59:29.5713566Z           [32m+[0m[0m nat                = true
2024-06-22T20:59:29.5714218Z           [32m+[0m[0m nat_ip_address     = (known after apply)
2024-06-22T20:59:29.5714831Z           [32m+[0m[0m nat_ip_version     = (known after apply)
2024-06-22T20:59:29.5715391Z           [32m+[0m[0m security_group_ids = (known after apply)
2024-06-22T20:59:29.5716083Z           [32m+[0m[0m subnet_id          = (known after apply)
2024-06-22T20:59:29.5716541Z         }
2024-06-22T20:59:29.5716746Z 
2024-06-22T20:59:29.5717013Z       [32m+[0m[0m resources {
2024-06-22T20:59:29.5717548Z           [32m+[0m[0m core_fraction = 100
2024-06-22T20:59:29.5718052Z           [32m+[0m[0m cores         = 4
2024-06-22T20:59:29.5718615Z           [32m+[0m[0m memory        = 4
2024-06-22T20:59:29.5719026Z         }
2024-06-22T20:59:29.5719338Z     }
2024-06-22T20:59:29.5719491Z 
2024-06-22T20:59:29.5719894Z [1m  # yandex_compute_instance.vms["worker-3"][0m will be created
2024-06-22T20:59:29.5720543Z [0m  [32m+[0m[0m resource "yandex_compute_instance" "vms" {
2024-06-22T20:59:29.5721225Z       [32m+[0m[0m created_at                = (known after apply)
2024-06-22T20:59:29.5721955Z       [32m+[0m[0m folder_id                 = (known after apply)
2024-06-22T20:59:29.5722598Z       [32m+[0m[0m fqdn                      = (known after apply)
2024-06-22T20:59:29.5723418Z       [32m+[0m[0m gpu_cluster_id            = (known after apply)
2024-06-22T20:59:29.5724105Z       [32m+[0m[0m hostname                  = "worker-3"
2024-06-22T20:59:29.5724737Z       [32m+[0m[0m id                        = (known after apply)
2024-06-22T20:59:29.5725445Z       [32m+[0m[0m maintenance_grace_period  = (known after apply)
2024-06-22T20:59:29.5726121Z       [32m+[0m[0m maintenance_policy        = (known after apply)
2024-06-22T20:59:29.5726702Z       [32m+[0m[0m metadata                  = {
2024-06-22T20:59:29.5727275Z           [32m+[0m[0m "ssh-keys" = <<-EOT
2024-06-22T20:59:29.5731251Z                 ubuntu:***
2024-06-22T20:59:29.5731625Z             EOT
2024-06-22T20:59:29.5732029Z         }
2024-06-22T20:59:29.5732463Z       [32m+[0m[0m name                      = "worker-3"
2024-06-22T20:59:29.5733573Z       [32m+[0m[0m network_acceleration_type = "standard"
2024-06-22T20:59:29.5734246Z       [32m+[0m[0m platform_id               = "standard-v3"
2024-06-22T20:59:29.5734879Z       [32m+[0m[0m service_account_id        = (known after apply)
2024-06-22T20:59:29.5735606Z       [32m+[0m[0m status                    = (known after apply)
2024-06-22T20:59:29.5736238Z       [32m+[0m[0m zone                      = "ru-central1-d"
2024-06-22T20:59:29.5736571Z 
2024-06-22T20:59:29.5736768Z       [32m+[0m[0m boot_disk {
2024-06-22T20:59:29.5737306Z           [32m+[0m[0m auto_delete = true
2024-06-22T20:59:29.5737812Z           [32m+[0m[0m device_name = (known after apply)
2024-06-22T20:59:29.5738399Z           [32m+[0m[0m disk_id     = (known after apply)
2024-06-22T20:59:29.5739033Z           [32m+[0m[0m mode        = (known after apply)
2024-06-22T20:59:29.5739368Z 
2024-06-22T20:59:29.5739564Z           [32m+[0m[0m initialize_params {
2024-06-22T20:59:29.5740204Z               [32m+[0m[0m block_size  = (known after apply)
2024-06-22T20:59:29.5740814Z               [32m+[0m[0m description = (known after apply)
2024-06-22T20:59:29.5741437Z               [32m+[0m[0m image_id    = "fd8di2mid9ojikcm93en"
2024-06-22T20:59:29.5742080Z               [32m+[0m[0m name        = (known after apply)
2024-06-22T20:59:29.5742606Z               [32m+[0m[0m size        = 30
2024-06-22T20:59:29.5743256Z               [32m+[0m[0m snapshot_id = (known after apply)
2024-06-22T20:59:29.5743908Z               [32m+[0m[0m type        = "network-hdd"
2024-06-22T20:59:29.5744375Z             }
2024-06-22T20:59:29.5744749Z         }
2024-06-22T20:59:29.5744910Z 
2024-06-22T20:59:29.5745133Z       [32m+[0m[0m network_interface {
2024-06-22T20:59:29.5745708Z           [32m+[0m[0m index              = (known after apply)
2024-06-22T20:59:29.5746399Z           [32m+[0m[0m ip_address         = (known after apply)
2024-06-22T20:59:29.5746967Z           [32m+[0m[0m ipv4               = true
2024-06-22T20:59:29.5747535Z           [32m+[0m[0m ipv6               = (known after apply)
2024-06-22T20:59:29.5748204Z           [32m+[0m[0m ipv6_address       = (known after apply)
2024-06-22T20:59:29.5748814Z           [32m+[0m[0m mac_address        = (known after apply)
2024-06-22T20:59:29.5749431Z           [32m+[0m[0m nat                = true
2024-06-22T20:59:29.5749963Z           [32m+[0m[0m nat_ip_address     = (known after apply)
2024-06-22T20:59:29.5750585Z           [32m+[0m[0m nat_ip_version     = (known after apply)
2024-06-22T20:59:29.5751241Z           [32m+[0m[0m security_group_ids = (known after apply)
2024-06-22T20:59:29.5751862Z           [32m+[0m[0m subnet_id          = (known after apply)
2024-06-22T20:59:29.5752324Z         }
2024-06-22T20:59:29.5752591Z 
2024-06-22T20:59:29.5752760Z       [32m+[0m[0m resources {
2024-06-22T20:59:29.5753237Z           [32m+[0m[0m core_fraction = 100
2024-06-22T20:59:29.5753720Z           [32m+[0m[0m cores         = 4
2024-06-22T20:59:29.5754285Z           [32m+[0m[0m memory        = 4
2024-06-22T20:59:29.5754854Z         }
2024-06-22T20:59:29.5755238Z     }
2024-06-22T20:59:29.5755390Z 
2024-06-22T20:59:29.5755910Z [1m  # yandex_iam_service_account_static_access_key.bucket-static_access_key[0m will be updated in-place
2024-06-22T20:59:29.5756994Z [0m  [33m~[0m[0m resource "yandex_iam_service_account_static_access_key" "bucket-static_access_key" {
2024-06-22T20:59:29.5757795Z         id                 = "ajepl81chs3qstnmq1jt"
2024-06-22T20:59:29.5758393Z         [90m# (5 unchanged attributes hidden)[0m[0m
2024-06-22T20:59:29.5758889Z     }
2024-06-22T20:59:29.5759139Z 
2024-06-22T20:59:29.5759489Z [1m  # yandex_resourcemanager_folder_iam_binding.editor[0m will be created
2024-06-22T20:59:29.5760304Z [0m  [32m+[0m[0m resource "yandex_resourcemanager_folder_iam_binding" "editor" {
2024-06-22T20:59:29.5761087Z       [32m+[0m[0m folder_id = "b1gcms0oj5ro6jjsgqdg"
2024-06-22T20:59:29.5761775Z       [32m+[0m[0m id        = (known after apply)
2024-06-22T20:59:29.5762305Z       [32m+[0m[0m members   = [
2024-06-22T20:59:29.5762920Z           [32m+[0m[0m "serviceAccount:ajedsrhv4ua9ld7t22ph",
2024-06-22T20:59:29.5763417Z         ]
2024-06-22T20:59:29.5763786Z       [32m+[0m[0m role      = "editor"
2024-06-22T20:59:29.5764260Z     }
2024-06-22T20:59:29.5764409Z 
2024-06-22T20:59:29.5764781Z [1m  # yandex_vpc_subnet.subnet-a[0m will be [1m[31mdestroyed[0m
2024-06-22T20:59:29.5765574Z   # (because yandex_vpc_subnet.subnet-a is not in configuration)
2024-06-22T20:59:29.5766259Z [0m  [31m-[0m[0m resource "yandex_vpc_subnet" "subnet-a" {
2024-06-22T20:59:29.5766957Z       [31m-[0m[0m created_at     = "2024-06-22T15:20:12Z" [90m-> null[0m[0m
2024-06-22T20:59:29.5767803Z       [31m-[0m[0m folder_id      = "b1gcms0oj5ro6jjsgqdg" [90m-> null[0m[0m
2024-06-22T20:59:29.5768538Z       [31m-[0m[0m id             = "e9brv9lccdmvglc35fnc" [90m-> null[0m[0m
2024-06-22T20:59:29.5769185Z       [31m-[0m[0m labels         = {} [90m-> null[0m[0m
2024-06-22T20:59:29.5769904Z       [31m-[0m[0m name           = "subnet-a" [90m-> null[0m[0m
2024-06-22T20:59:29.5770568Z       [31m-[0m[0m network_id     = "enpkcdt3mcqlr1gmum67" [90m-> null[0m[0m
2024-06-22T20:59:29.5771158Z       [31m-[0m[0m v4_cidr_blocks = [
2024-06-22T20:59:29.5771717Z           [31m-[0m[0m "192.168.10.0/24",
2024-06-22T20:59:29.5772194Z         ] [90m-> null[0m[0m
2024-06-22T20:59:29.5773191Z       [31m-[0m[0m v6_cidr_blocks = [] [90m-> null[0m[0m
2024-06-22T20:59:29.5774237Z       [31m-[0m[0m zone           = "ru-central1-a" [90m-> null[0m[0m
2024-06-22T20:59:29.5774743Z     }
2024-06-22T20:59:29.5775006Z 
2024-06-22T20:59:29.5775342Z [1m  # yandex_vpc_subnet.subnet-b[0m will be [1m[31mdestroyed[0m
2024-06-22T20:59:29.5776062Z   # (because yandex_vpc_subnet.subnet-b is not in configuration)
2024-06-22T20:59:29.5776731Z [0m  [31m-[0m[0m resource "yandex_vpc_subnet" "subnet-b" {
2024-06-22T20:59:29.5777525Z       [31m-[0m[0m created_at     = "2024-06-22T15:20:13Z" [90m-> null[0m[0m
2024-06-22T20:59:29.5778268Z       [31m-[0m[0m folder_id      = "b1gcms0oj5ro6jjsgqdg" [90m-> null[0m[0m
2024-06-22T20:59:29.5779073Z       [31m-[0m[0m id             = "e2lupau8bgpa84pspf97" [90m-> null[0m[0m
2024-06-22T20:59:29.5779729Z       [31m-[0m[0m labels         = {} [90m-> null[0m[0m
2024-06-22T20:59:29.5780343Z       [31m-[0m[0m name           = "subnet-b" [90m-> null[0m[0m
2024-06-22T20:59:29.5781122Z       [31m-[0m[0m network_id     = "enpkcdt3mcqlr1gmum67" [90m-> null[0m[0m
2024-06-22T20:59:29.5781710Z       [31m-[0m[0m v4_cidr_blocks = [
2024-06-22T20:59:29.5782202Z           [31m-[0m[0m "192.168.20.0/24",
2024-06-22T20:59:29.5782724Z         ] [90m-> null[0m[0m
2024-06-22T20:59:29.5783230Z       [31m-[0m[0m v6_cidr_blocks = [] [90m-> null[0m[0m
2024-06-22T20:59:29.5783949Z       [31m-[0m[0m zone           = "ru-central1-b" [90m-> null[0m[0m
2024-06-22T20:59:29.5784459Z     }
2024-06-22T20:59:29.5784611Z 
2024-06-22T20:59:29.5785117Z [1m  # yandex_vpc_subnet.subnet-d[0m will be [1m[31mdestroyed[0m
2024-06-22T20:59:29.5785905Z   # (because yandex_vpc_subnet.subnet-d is not in configuration)
2024-06-22T20:59:29.5786583Z [0m  [31m-[0m[0m resource "yandex_vpc_subnet" "subnet-d" {
2024-06-22T20:59:29.5787290Z       [31m-[0m[0m created_at     = "2024-06-22T15:20:12Z" [90m-> null[0m[0m
2024-06-22T20:59:29.5788079Z       [31m-[0m[0m folder_id      = "b1gcms0oj5ro6jjsgqdg" [90m-> null[0m[0m
2024-06-22T20:59:29.5788814Z       [31m-[0m[0m id             = "fl8asquatn3nu84e1mb3" [90m-> null[0m[0m
2024-06-22T20:59:29.5789450Z       [31m-[0m[0m labels         = {} [90m-> null[0m[0m
2024-06-22T20:59:29.5790125Z       [31m-[0m[0m name           = "subnet-d" [90m-> null[0m[0m
2024-06-22T20:59:29.5790828Z       [31m-[0m[0m network_id     = "enpkcdt3mcqlr1gmum67" [90m-> null[0m[0m
2024-06-22T20:59:29.5791619Z       [31m-[0m[0m v4_cidr_blocks = [
2024-06-22T20:59:29.5792133Z           [31m-[0m[0m "192.168.30.0/24",
2024-06-22T20:59:29.5792602Z         ] [90m-> null[0m[0m
2024-06-22T20:59:29.5793203Z       [31m-[0m[0m v6_cidr_blocks = [] [90m-> null[0m[0m
2024-06-22T20:59:29.5793843Z       [31m-[0m[0m zone           = "ru-central1-d" [90m-> null[0m[0m
2024-06-22T20:59:29.5794340Z     }
2024-06-22T20:59:29.5794563Z 
2024-06-22T20:59:29.5794865Z [1m  # yandex_vpc_subnet.subnets[0][0m will be created
2024-06-22T20:59:29.5795483Z [0m  [32m+[0m[0m resource "yandex_vpc_subnet" "subnets" {
2024-06-22T20:59:29.5796170Z       [32m+[0m[0m created_at     = (known after apply)
2024-06-22T20:59:29.5796749Z       [32m+[0m[0m folder_id      = (known after apply)
2024-06-22T20:59:29.5797313Z       [32m+[0m[0m id             = (known after apply)
2024-06-22T20:59:29.5797941Z       [32m+[0m[0m labels         = (known after apply)
2024-06-22T20:59:29.5798481Z       [32m+[0m[0m name           = "subnet-a"
2024-06-22T20:59:29.5799018Z       [32m+[0m[0m network_id     = "enpkcdt3mcqlr1gmum67"
2024-06-22T20:59:29.5799659Z       [32m+[0m[0m v4_cidr_blocks = [
2024-06-22T20:59:29.5800136Z           [32m+[0m[0m "192.168.10.0/24",
2024-06-22T20:59:29.5800567Z         ]
2024-06-22T20:59:29.5801060Z       [32m+[0m[0m v6_cidr_blocks = (known after apply)
2024-06-22T20:59:29.5801619Z       [32m+[0m[0m zone           = "ru-central1-a"
2024-06-22T20:59:29.5802132Z     }
2024-06-22T20:59:29.5802316Z 
2024-06-22T20:59:29.5802563Z [1m  # yandex_vpc_subnet.subnets[1][0m will be created
2024-06-22T20:59:29.5803197Z [0m  [32m+[0m[0m resource "yandex_vpc_subnet" "subnets" {
2024-06-22T20:59:29.5803860Z       [32m+[0m[0m created_at     = (known after apply)
2024-06-22T20:59:29.5804432Z       [32m+[0m[0m folder_id      = (known after apply)
2024-06-22T20:59:29.5805030Z       [32m+[0m[0m id             = (known after apply)
2024-06-22T20:59:29.5805652Z       [32m+[0m[0m labels         = (known after apply)
2024-06-22T20:59:29.5806208Z       [32m+[0m[0m name           = "subnet-b"
2024-06-22T20:59:29.5806836Z       [32m+[0m[0m network_id     = "enpkcdt3mcqlr1gmum67"
2024-06-22T20:59:29.5807369Z       [32m+[0m[0m v4_cidr_blocks = [
2024-06-22T20:59:29.5807876Z           [32m+[0m[0m "192.168.20.0/24",
2024-06-22T20:59:29.5808351Z         ]
2024-06-22T20:59:29.5808744Z       [32m+[0m[0m v6_cidr_blocks = (known after apply)
2024-06-22T20:59:29.5809319Z       [32m+[0m[0m zone           = "ru-central1-b"
2024-06-22T20:59:29.5809825Z     }
2024-06-22T20:59:29.5810024Z 
2024-06-22T20:59:29.5810279Z [1m  # yandex_vpc_subnet.subnets[2][0m will be created
2024-06-22T20:59:29.5810907Z [0m  [32m+[0m[0m resource "yandex_vpc_subnet" "subnets" {
2024-06-22T20:59:29.5811577Z       [32m+[0m[0m created_at     = (known after apply)
2024-06-22T20:59:29.5812161Z       [32m+[0m[0m folder_id      = (known after apply)
2024-06-22T20:59:29.5813068Z       [32m+[0m[0m id             = (known after apply)
2024-06-22T20:59:29.5813810Z       [32m+[0m[0m labels         = (known after apply)
2024-06-22T20:59:29.5814544Z       [32m+[0m[0m name           = "subnet-d"
2024-06-22T20:59:29.5815215Z       [32m+[0m[0m network_id     = "enpkcdt3mcqlr1gmum67"
2024-06-22T20:59:29.5815760Z       [32m+[0m[0m v4_cidr_blocks = [
2024-06-22T20:59:29.5816240Z           [32m+[0m[0m "192.168.30.0/24",
2024-06-22T20:59:29.5816731Z         ]
2024-06-22T20:59:29.5817211Z       [32m+[0m[0m v6_cidr_blocks = (known after apply)
2024-06-22T20:59:29.5817856Z       [32m+[0m[0m zone           = "ru-central1-d"
2024-06-22T20:59:29.5818335Z     }
2024-06-22T20:59:29.5818483Z 
2024-06-22T20:59:29.5818747Z [1mPlan:[0m 10 to add, 1 to change, 3 to destroy.
2024-06-22T20:59:29.5819257Z [0m
2024-06-22T20:59:29.5819560Z Changes to Outputs:
2024-06-22T20:59:29.5820092Z   [32m+[0m[0m internal-ip-address_worker-1   = (known after apply)
2024-06-22T20:59:29.5821032Z   [32m+[0m[0m internal-ip-address_worker-2   = (known after apply)
2024-06-22T20:59:29.5821747Z   [32m+[0m[0m internal-ip-address_worker-3   = (known after apply)
2024-06-22T20:59:29.5822456Z   [32m+[0m[0m internal_ip_address_master     = (known after apply)
2024-06-22T20:59:29.5823208Z   [32m+[0m[0m master_ip_address_nat-master   = (known after apply)
2024-06-22T20:59:29.5823915Z   [32m+[0m[0m master_ip_address_nat-worker-1 = (known after apply)
2024-06-22T20:59:29.5824651Z   [32m+[0m[0m master_ip_address_nat-worker-2 = (known after apply)
2024-06-22T20:59:29.5825321Z   [32m+[0m[0m master_ip_address_nat-worker-3 = (known after apply)
2024-06-22T20:59:29.5825865Z [90m
2024-06-22T20:59:29.5826827Z ─────────────────────────────────────────────────────────────────────────────[0m
2024-06-22T20:59:29.5827225Z 
2024-06-22T20:59:29.5827640Z Note: You didn't use the -out option to save this plan, so Terraform can't
2024-06-22T20:59:29.5828392Z guarantee to take exactly these actions if you run "terraform apply" now.
2024-06-22T20:59:29.5837841Z 
2024-06-22T20:59:29.5848389Z ##[warning]The `set-output` command is deprecated and will be disabled soon. Please upgrade to using Environment Files. For more information see: https://github.blog/changelog/2022-10-11-github-actions-deprecating-save-state-and-set-output-commands/
2024-06-22T20:59:29.5850759Z 
2024-06-22T20:59:29.5854360Z ##[warning]The `set-output` command is deprecated and will be disabled soon. Please upgrade to using Environment Files. For more information see: https://github.blog/changelog/2022-10-11-github-actions-deprecating-save-state-and-set-output-commands/
2024-06-22T20:59:29.5856197Z 
2024-06-22T20:59:29.5859120Z ##[warning]The `set-output` command is deprecated and will be disabled soon. Please upgrade to using Environment Files. For more information see: https://github.blog/changelog/2022-10-11-github-actions-deprecating-save-state-and-set-output-commands/
2024-06-22T20:59:29.5929192Z Post job cleanup.
2024-06-22T20:59:29.6916532Z [command]/usr/bin/git version
2024-06-22T20:59:29.6963291Z git version 2.45.2
2024-06-22T20:59:29.7008071Z Temporarily overriding HOME='/home/runner/work/_temp/6cd68fe5-6128-4481-862c-a8e7c04540d3' before making global git config changes
2024-06-22T20:59:29.7009468Z Adding repository directory to the temporary git global config as a safe directory
2024-06-22T20:59:29.7013989Z [command]/usr/bin/git config --global --add safe.directory /home/runner/work/atlantis/atlantis
2024-06-22T20:59:29.7055785Z [command]/usr/bin/git config --local --name-only --get-regexp core\.sshCommand
2024-06-22T20:59:29.7096210Z [command]/usr/bin/git submodule foreach --recursive sh -c "git config --local --name-only --get-regexp 'core\.sshCommand' && git config --local --unset-all 'core.sshCommand' || :"
2024-06-22T20:59:29.7338853Z [command]/usr/bin/git config --local --name-only --get-regexp http\.https\:\/\/github\.com\/\.extraheader
2024-06-22T20:59:29.7368958Z http.https://github.com/.extraheader
2024-06-22T20:59:29.7378887Z [command]/usr/bin/git config --local --unset-all http.https://github.com/.extraheader
2024-06-22T20:59:29.7418333Z [command]/usr/bin/git submodule foreach --recursive sh -c "git config --local --name-only --get-regexp 'http\.https\:\/\/github\.com\/\.extraheader' && git config --local --unset-all 'http.https://github.com/.extraheader' || :"
2024-06-22T20:59:29.7917304Z Cleaning up orphan processes



```

</details>
