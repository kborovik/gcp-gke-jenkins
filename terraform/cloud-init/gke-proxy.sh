#!/usr/bin/env bash
# shellcheck disable=SC2154
# shellcheck disable=SC2086
export DEBIAN_FRONTEND noninteractive
# add OpenVPN apt repo
curl -fsSL https://as-repository.openvpn.net/as-repo-public.gpg | apt-key add -
cat <<EOF | tee /etc/apt/sources.list.d/openvpn-as-repo.list
deb [arch=$(dpkg --print-architecture)] http://as-repository.openvpn.net/as/debian $(lsb_release -cs) main
EOF
apt update -y && apt upgrade -y && apt install -y less bash-completion git jq make net-tools openvpn-as tree
# configure OpenVPN
external_ip=$(curl -sSL http://ipinfo.io | grep '"ip"' | cut -d'"' -f4)
/usr/local/openvpn_as/scripts/sacli --key "host.name" --value "$external_ip" ConfigPut
/usr/local/openvpn_as/scripts/sacli --key "vpn.client.routing.reroute_gw" --value "false" ConfigPut
/usr/local/openvpn_as/scripts/sacli --key "vpn.server.routing.private_network.0" --value "10.128.0.0/21" ConfigPut
/usr/local/openvpn_as/scripts/sacli --key "vpn.server.dhcp_option.domain" --value "lab5.gcp" ConfigPut
/usr/local/openvpn_as/scripts/sacli --key "vpn.server.dhcp_option.adapter_domain_suffix" --value "lab5.gcp" ConfigPut
/usr/local/openvpn_as/scripts/sacli --key "vpn.client.routing.reroute_dns" --value "true" ConfigPut
# create openvpn-create-user.sh
cat <<'EOF' | tee /usr/local/bin/openvpn-create-user.sh
#!/bin/env bash
openvpn_user_name="$1"
openvpn_auth_file="$HOME"/"$openvpn_user_name".ovpn
_usage() {
  echo "Usage: $(basename "$0") <openvpn_user_name>"
  exit 1
}
[[ -z "$openvpn_user_name" ]] && _usage
sudo /usr/local/openvpn_as/scripts/sacli --user "$openvpn_user_name" AutoGenerateOnBehalfOf
sudo /usr/local/openvpn_as/scripts/sacli --user "$openvpn_user_name" RemoveLocalPassword
sudo /usr/local/openvpn_as/scripts/sacli --user "$openvpn_user_name" --key "type" --value "user_connect" UserPropPut
sudo /usr/local/openvpn_as/scripts/sacli --user "$openvpn_user_name" --key "prop_autologin" --value "true" UserPropPut
sudo /usr/local/openvpn_as/scripts/sacli --user "$openvpn_user_name" GetAutologin | tee "$openvpn_auth_file"
chmod 0600 "$openvpn_auth_file"
EOF
chmod 755 /usr/local/bin/openvpn-create-user.sh
systemctl reboot
