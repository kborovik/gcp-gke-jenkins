/*

Project metadata

*/
resource "google_compute_project_metadata_item" "enable_osconfig" {
  key   = "enable-osconfig"
  value = "true"
}

resource "google_compute_project_metadata_item" "enable_guest_attributes" {
  key   = "enable-guest-attributes"
  value = "true"
}

resource "google_compute_project_metadata_item" "ssh_keys" {
  key   = "ssh-keys"
  value = <<-EOT
      kb:ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPFasnr4+Ckyb/Bn0fJuoMC0jYET7AviV/1zt1IIBLYY kb
  EOT
}
