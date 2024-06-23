output "internal-ip-address-master" {
value = "${yandex_compute_instance.master.network_interface.0.ip_address}"
}
output "master_ip_address_nat-master" {
value = "${yandex_compute_instance.master.network_interface.0.nat_ip_address}"
}


output "internal-ip-address-worker-1" {
value = "${yandex_compute_instance.worker-1.network_interface.0.ip_address}"
}
output "master_ip_address_nat-worker-1" {
value = "${yandex_compute_instance.worker-1.network_interface.0.nat_ip_address}"
}


output "internal-ip-address-worker-2" {
value = "${yandex_compute_instance.worker-2.network_interface.0.ip_address}"
}
output "master_ip_address_nat-worker-2" {
value = "${yandex_compute_instance.worker-2.network_interface.0.nat_ip_address}"
}


output "internal-ip-address-worker-3" {
value = "${yandex_compute_instance.worker-3.network_interface.0.ip_address}"
}
output "master_ip_address_nat-worker-3" {
value = "${yandex_compute_instance.worker-3.network_interface.0.nat_ip_address}"
}


