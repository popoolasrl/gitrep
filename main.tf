provider "google" {
  credentials = file("C:/application_default_credentials.json")
  project     = "my-project-81925-popoola"
  region      = "us-west2"
}

resource "google_compute_network" "adara-network" {
  name = "adara-network"
  auto_create_subnetworks = false
  
}

resource "google_compute_network" "proxy-network" {
  name = "proxy-network"
  auto_create_subnetworks = false
}

resource "google_compute_network" "private-network" {
  name = "private-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "adara-pub-subnet" {
  name          = "adara-pub-subnet"
  network = google_compute_network.adara-network.id
  ip_cidr_range = "10.122.2.0/24"
  region        = "us-west2"
}

resource "google_compute_subnetwork" "adara-proxy-subnet-1" {
  name = "adara-proxy-subnet-1"
  network = google_compute_network.proxy-network.self_link
  ip_cidr_range = "10.122.6.0/24"
  region = "us-west2"
  private_ip_google_access = true
}

resource "google_compute_subnetwork" "adara-priv-subnet" {
  name = "adara-priv-subnet"
  network = google_compute_network.private-network.self_link
  ip_cidr_range = "10.122.7.0/24"
  region = "us-west2"
  private_ip_google_access = true
}

resource "google_compute_router" "adararouter" {
  name    = "adararouter"
  region  = google_compute_subnetwork.adara-proxy-subnet-1.region
  network = google_compute_network.private-network.self_link
}

resource "google_compute_router_nat" "adaranat" {
  name                               = "adaranat"
  router                             = google_compute_router.adararouter.name
  region                             = google_compute_router.adararouter.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

}

# proxy server
resource "google_compute_instance" "proxyvm" {
  name         = "proxyvm"
  machine_type = "n2-standard-4"
  zone         = "us-west2-a"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
      labels = {
        my_label = "value"
      }
    }
  }

  // Local SSD disk
  scratch_disk {
    interface = "SCSI"
  }

  network_interface {
    network = google_compute_network.adara-network.self_link
    subnetwork = google_compute_subnetwork.adara-pub-subnet.self_link
    
  }

  network_interface {
    network = google_compute_network.private-network.self_link
    subnetwork = google_compute_subnetwork.adara-priv-subnet.self_link

    access_config {
      // Ephemeral public IP
    }
  }

  network_interface {
    network = google_compute_network.proxy-network.self_link
    subnetwork = google_compute_subnetwork.adara-proxy-subnet-1.self_link
  }
}

# prov server
resource "google_compute_instance" "provvm" {
  name         = "provvm"
  machine_type = "n2-standard-2"
  zone         = "us-west2-a"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
      labels = {
        my_label = "value"
      }
    }
  }

  // Local SSD disk
  scratch_disk {
    interface = "SCSI"
  }

  network_interface {
    network = google_compute_network.adara-network.self_link
    subnetwork = google_compute_subnetwork.adara-pub-subnet.self_link

    access_config {
      // Ephemeral public IP
    }
  }
}

resource "google_compute_instance_group" "adara-instance-group" {
  name        = "adara-instance-group"
  description = "adara instance group"
  zone = "us-west2-a"

  instances = [
    google_compute_instance.proxyvm.id, google_compute_instance.provvm.id    
  ]

  named_port {
    name = "http"
    port = "80"
  }

  named_port {
    name = "https"
    port = "443"
  }
}

resource "google_compute_instance_group_manager" "privvm-group" {
  name = "privvm-group"
  base_instance_name = "privvm"
  zone = "us-central1-a"
  target_size = 1
  auto_healing_policies {
    health_check = "health-check"
    initial_delay_sec = 300
  }
  version {
    instance_template = "privvm-template"
        
  }
  
}


