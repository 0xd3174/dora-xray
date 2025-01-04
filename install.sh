#!/usr/bin/env bash

#################
### CONSTANTS ###
#################

INSTALL_PATH="/opt/dora-xray";

###############
### UTILITY ###
###############

info()  { echo -e "\033[36m[!]\033[0m $*"; }
sub()   { echo "  $*"; }
readw() { read -rp "$(echo -e "\033[33m[?]\033[0m $1 ")" "$2"; }
fatal() { echo -e "\033[31m[X]\033[0m $*"; exit 1; }

log_entry() {
  mkdir -p "${INSTALL_PATH}/logs/";
	touch "${INSTALL_PATH}/logs/installation.log";
  exec > >(tee -a "${INSTALL_PATH}/logs/installation.log") 2>&1;
}

####################
### PREPARATIONS ###
####################

check_for_root() {
	if [[ $EUID -ne 0 ]]; then
    fatal "You must be root to run this script";
	fi
}

check_for_distribution() {
	SYSTEM=$(cat /etc/os-release | sed -n 's/^NAME="\([^"]*\).*/\1/p' | awk '{print $1}');
	
	case $SYSTEM in 
		Debian) ;;
		Ubuntu) ;;
		*) fatal "Snsupported system available is Ubuntu and Debian";;
	esac
}

updates_warning() {
  info "The system must be updated before installation with command";
	sub "apt-get install && apt-get upgrade && reboot";
	echo;LOGFILE
	
	readw "Have you updated the system? [y/N]" IS_UPDATED;
	case $IS_UPDATED in
		Y) ;;
		y) ;;
		N) fatal "Abort installation";;
		n) fatal "Abort installation";;
		*) fatal "Abort installation";;
	esac
}

print_banner() {
	echo;
	echo -e "\033[35m\033[47m                                             \033[0m";
  echo -e "\033[35m\033[47m ██████████                                  \033[0m";
  echo -e "\033[35m\033[47m ░░███░░░░███                                \033[0m";
  echo -e "\033[35m\033[47m  ░███   ░░███  ██████  ████████   ██████    \033[0m";
  echo -e "\033[35m\033[47m  ░███    ░███ ███░░███░░███░░███ ░░░░░███   \033[0m";
  echo -e "\033[35m\033[47m  ░███    ░███░███ ░███ ░███ ░░░   ███████   \033[0m";
  echo -e "\033[35m\033[47m  ░███    ███ ░███ ░███ ░███      ███░░███   \033[0m";
  echo -e "\033[35m\033[47m  ██████████  ░░██████  █████    ░░████████  \033[0m";
  echo -e "\033[35m\033[47m ░░░░░░░░░░    ░░░░░░  ░░░░░      ░░░░░░░░   \033[0m"; 
  echo -e "\033[35m\033[47m                                             \033[0m";
  echo -e "\033[35m\033[47m  █████ █████                                \033[0m";
  echo -e "\033[35m\033[47m ░░███ ░░███                                 \033[0m";
  echo -e "\033[35m\033[47m  ░░███ ███   ████████   ██████   █████ ████ \033[0m";
  echo -e "\033[35m\033[47m   ░░█████   ░░███░░███ ░░░░░███ ░░███ ░███  \033[0m";
  echo -e "\033[35m\033[47m    ███░███   ░███ ░░░   ███████  ░███ ░███  \033[0m";
  echo -e "\033[35m\033[47m   ███ ░░███  ░███      ███░░███  ░███ ░███  \033[0m";
  echo -e "\033[35m\033[47m  █████ █████ █████    ░░████████ ░░███████  \033[0m";
  echo -e "\033[35m\033[47m ░░░░░ ░░░░░ ░░░░░      ░░░░░░░░   ░░░░░███  \033[0m";
  echo -e "\033[35m\033[47m                                   ███ ░███  \033[0m";
  echo -e "\033[35m\033[47m                                  ░░██████   \033[0m";
  echo -e "\033[35m\033[47m                                   ░░░░░░    \033[0m";
	echo -e "\033[35m\033[47m                                             \033[0m";
	echo;
}

ask_for_settings() {
	readw "Enter the add of your site (www.example.com)" SNI;
  echo;
}

install_deps() {
  apt-get install wget curl ufw jq micro socat crontab net-tools unzip -y;

	install_nginx;
}

install_nginx() {
  case $SYSTEM in
    Debian)
      apt-get install debian-archive-keyring
      curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor \
        | tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
      gpg --dry-run --quiet --no-keyring --import --import-options import-show /usr/share/keyrings/nginx-archive-keyring.gpg
      echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] \
      http://nginx.org/packages/debian `lsb_release -cs` nginx" \
        | tee /etc/apt/sources.list.d/nginx.list
      echo -e "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n" \
        | tee /etc/apt/preferences.d/99nginx
      ;;
    Ubuntu)
      apt-get install ubuntu-keyring
      curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor \
        | tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
      gpg --dry-run --quiet --no-keyring --import --import-options import-show /usr/share/keyrings/nginx-archive-keyring.gpg
      echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] \
      http://nginx.org/packages/ubuntu `lsb_release -cs` nginx" \
        | tee /etc/apt/sources.list.d/nginx.list
      echo -e "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n" \
        | tee /etc/apt/preferences.d/99nginx
      ;;
  esac

  apt-get update -y && apt-get install nginx -y;
  sytemctl stop nginx;
}

clone_repo() {
  wget https://github.com/0xd3174/dora-xray/archive/refs/heads/master.zip -O dora-xray.zip;
  unzip dora-xray.zip;
  cd dora-xray-master;
}

############
### MAIN ###
############

setup_xray() {
	bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install -u root;

  TEMP=$(xray x25519);
  PRIVATE_KEY=$(echo "$TEMP" | sed -n 's/.*Private key: //p');
  PUBLIC_KEY=$(echo "$TEMP" | sed -n 's/.*Public key: //p');
  SHORT_ID=$(openssl rand -hex 8);

  sed -i "s/{{SNI}}/${SNI}/" ./config/server.json;
  sed -i "s/{{PRIVATE_KEY}}/${PRIVATE_KEY}/" ./config/server.json;
  sed -i "s/{{PUBLIC_KEY}}/${PUBLIC_KEY}/" ./config/server.json;
  sed -i "s/{{SHORT_ID}}/${SHORT_ID}/" ./config/server.json;

  cat ./config/server.json > /usr/local/etc/xray/config.json;
}

get_certificates() {
	wget -O -  https://get.acme.sh | sh;

  ACME=/root/.acme.sh/acme.sh;
  CERTS_PATH="${INSTALL_PATH}/certs/${SNI}"

  ${ACME} --set-default-ca --server letsencrypt;
  ${ACME} --standalone --issue -d ${SNI} --keylength ec-256 --force;
  ${ACME} --installcert --ecc -d ${SNI} \
    --cert-file "${CERTS_PATH}/cert.crt" \
    --key-file "${CERTS_PATH}/cert.key" \
    --fullchain-file "${CERTS_PATH}/fullchain.crt";

  echo <<EOF
#!/bin/bash

${ACME} --installcert --ecc -d ${SNI} \
  --cert-file "${CERTS_PATH}/cert.crt" \
  --key-file "${CERTS_PATH}/cert.key" \
  --fullchain-file "${CERTS_PATH}/fullchain.crt";
echo "Xray Certificates Renewed"

chmod +r "${CERTS_PATH}/cert.key"
echo "Read Permission Granted for Private Key"

sudo systemctl restart xray
echo "Xray Restarted"
EOF > "${CERTS_PATH}/renew.sh"

  chmod +x "${CERTS_PATH}/renew.sh";
  (crontab -l; echo "0 1 1 * * bash ${CERTS_PATH}/renew.sh") | sort -u | crontab -
}

setup_nginx() {
  sed -i "s/{{SNI}}/${SNI}/" ./config/nginx.conf;
  # //\//\\/ is some kind of magiс to escape all of backslashes
  sed -i "s/{{CERT_PATH}}/${CERTS_PATH//\//\\/}\/fullchain.crt/" ./config/nginx.conf;
  sed -i "s/{{CERT_KEY_PATH}}/${CERTS_PATH//\//\\/}\/cert.key/" ./config/nginx.conf;

  cat ./config/nginx.conf > /etc/nginx/nginx.conf;
}

disable_ipv6() {
  interface_name=$(ifconfig -s | awk 'NR==2 {print $1}')
  if [[ ! "$(sysctl net.ipv6.conf.all.disable_ipv6)" == *"= 1" ]]; then
    echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
  fi
  
  if [[ ! "$(sysctl net.ipv6.conf.default.disable_ipv6)" == *"= 1" ]]; then
    echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
  fi
  if [[ ! "$(sysctl net.ipv6.conf.lo.disable_ipv6)" == *"= 1" ]]; then
    echo "net.ipv6.conf.lo.disable_ipv6 = 1" >> /etc/sysctl.conf
  fi

  if [[ ! "$(sysctl net.ipv6.conf.$interface_name.disable_ipv6)" == *"= 1" ]]; then
    echo "net.ipv6.conf.$interface_name.disable_ipv6 = 1" >> /etc/sysctl.conf
  fi
  sysctl -p
}

setup_ufw() {
	ufw allow 22 80 443;
  ufw enable;
}

main() {
  log_entry;

  check_for_root;
  check_for_distribution;
  updates_warning;
  
  print_banner;
  clone_repo;
  ask_for_settings;
  install_deps;

  setup_xray;
  get_certificates;
  setup_nginx;
  disable_ipv6;
  setup_ufw;
}

main