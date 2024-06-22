# diplom-devops




![image](https://github.com/Dimarkle/diplom-devops/assets/118626944/1c368806-1d11-4cfc-bfe4-5b450a38ea45)







![image](https://github.com/Dimarkle/diplom-devops/assets/118626944/5f91963b-f597-4e63-852c-661874bb8028)



Ansible-playbook отработал корректно. Далее скопируем закрытый ключ и сформированный inventory-kubespray с локальной машины на мастер-ноду


![image](https://github.com/Dimarkle/diplom-devops/assets/118626944/2d13a2a4-8f4b-4900-8314-662e1a4eca32)




С мастер-ноды запустим развертывание Kubernetes методом Kubespray:



![image](https://github.com/Dimarkle/diplom-devops/assets/118626944/1d772ea2-246b-40e8-8ba9-71349d1b0ab0)


конец вывода:


![image](https://github.com/Dimarkle/diplom-devops/assets/118626944/6e385f30-1306-46d9-9faf-9db2027dfeb3)



Результат работы kubectl, отрабатывает без ошибок:


![image](https://github.com/Dimarkle/diplom-devops/assets/118626944/77acb492-17bb-4dad-b3d8-d4aefad0d31b)




Отредактировал kubectl config:


![image](https://github.com/Dimarkle/diplom-devops/assets/118626944/69c4a975-3f7c-418c-8cc2-1f8ac533bdb8)



kube-prometheus

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


Проверка:



![image](https://github.com/Dimarkle/diplom-devops/assets/118626944/489eaaaa-3d9f-40c1-805e-b4f2bc7ac815)





Для доступа к интерфейсу изменим сетевую политику:



![image](https://github.com/Dimarkle/diplom-devops/assets/118626944/acd8fb67-0ffb-45d4-be72-0beb17971121)


![image](https://github.com/Dimarkle/diplom-devops/assets/118626944/5acc2858-44dd-45a8-861a-5be377b0c961)


![image](https://github.com/Dimarkle/diplom-devops/assets/118626944/6c38cfb2-3b5b-414a-a7a5-40ce6d89630e)

Проверка

![image](https://github.com/Dimarkle/diplom-devops/assets/118626944/6f7ae294-b4a2-45b8-9996-5e4f9fbc05f5)


# Docker

Загрузим версию 1.0 в гитхаб.


![image](https://github.com/Dimarkle/diplom-devops/assets/118626944/d69bb3af-0636-4d4f-9c61-4ff70af1725e)

Создадим репу в докер хабе:

![image](https://github.com/Dimarkle/diplom-devops/assets/118626944/f124b48b-5e3f-4a5d-8258-94e0b1e024ab)




Выполним сборку образа на основе Dockerfile 

![image](https://github.com/Dimarkle/diplom-devops/assets/118626944/6eaa6216-6c07-4e74-962b-31950ae239f2)





Отправим созданный образ на DockerHub:




![image](https://github.com/Dimarkle/diplom-devops/assets/118626944/92564487-e746-4569-8a8e-9e36749bfc3c)



Проверяем:

![image](https://github.com/Dimarkle/diplom-devops/assets/118626944/484ce855-2d46-4f95-bc74-2e382b4a1522)


# Подготовка системы мониторинга и деплой приложения



Создаем секреты:


![image](https://github.com/Dimarkle/diplom-devops/assets/118626944/a75187bf-50af-4746-97ed-5e824e56f02d)



Создаем файл Image.yml


Версия 1.1:


![image](https://github.com/Dimarkle/diplom-devops/assets/118626944/8ca532ec-1eae-419b-8569-769e725a9c88)


Ошибок нет:



![image](https://github.com/Dimarkle/diplom-devops/assets/118626944/07f84a82-637e-43cb-9fb2-df3501dd5da4)


doker:


![image](https://github.com/Dimarkle/diplom-devops/assets/118626944/3cca91a9-224c-42b9-a58d-949bdb5ff76f)












```
diman@Diman:~/diplom/terraform$ yc iam key create --service-account-name diman-diplom -o key.json --output key.json --folder-id b1g************
id: *****************
service_account_id:  *****************h
created_at: "2024-06-22T15:27:16.073806810Z"
key_algorithm: RSA_2048
```
```
diman@Diman:~/diplom/terraform$ yc config set service-account-key key.json
diman@Diman:~/diplom/terraform$ yc config list
```

![image](https://github.com/Dimarkle/diplom-devops/assets/118626944/724acbea-964b-4478-a6f8-c7f51281744c)





![image](https://github.com/Dimarkle/diplom-devops/assets/118626944/05aa9110-e340-4ba6-a237-74110abd96f9)



![image](https://github.com/Dimarkle/diplom-devops/assets/118626944/f93d1c57-81db-4d74-85b2-d24f104673f4)


![image](https://github.com/Dimarkle/diplom-devops/assets/118626944/f57f9be3-4094-4064-8486-150be48c9fc9)




