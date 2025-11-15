#!/usr/bin/env bash
#
# remotegui.sh
# Install Desktop Environment (Xfce / MATE minimal) + XRDP + Google Chrome on Ubuntu Server/VPS
# After installation, you can connect via Remote Desktop (RDP) from your Desktop machine.

set -e

#-----------------------------
# Colors for output
#-----------------------------
CLR_GREEN="\e[32m"
CLR_YELLOW="\e[33m"
CLR_RED="\e[31m"
CLR_CYAN="\e[36m"
CLR_RESET="\e[0m"
CLR_BOLD="\e[1m"

info()  { echo -e "${CLR_CYAN}[INFO]${CLR_RESET} $1"; }
ok()    { echo -e "${CLR_GREEN}[OK]${CLR_RESET} $1"; }
warn()  { echo -e "${CLR_YELLOW}[WARN]${CLR_RESET} $1"; }
error() { echo -e "${CLR_RED}[ERROR]${CLR_RESET} $1"; }

#-----------------------------
# Require root
#-----------------------------
require_root() {
    if [ "$EUID" -ne 0 ]; then
        error "Please run this script as root (e.g., sudo ./remotegui.sh) / กรุณารันสคริปต์นี้ด้วยสิทธิ์ root (เช่น sudo ./remotegui.sh)"
        exit 1
    fi
}

#-----------------------------
# Check Ubuntu
#-----------------------------
check_ubuntu() {
    if [ ! -f /etc/os-release ]; then
        error "This script only supports Ubuntu (no /etc/os-release found) / สคริปต์นี้รองรับ Ubuntu เท่านั้น (ไม่พบไฟล์ /etc/os-release)"
        exit 1
    fi

    . /etc/os-release

    if [[ "$ID" != "ubuntu" ]]; then
        error "This script only supports Ubuntu (detected: $NAME) / สคริปต์นี้รองรับเฉพาะ Ubuntu (ตรวจพบ: $NAME)"
        exit 1
    fi

    info "Detected OS: $PRETTY_NAME / ตรวจพบระบบ: $PRETTY_NAME"
}

#-----------------------------
# Select Desktop Environment
#-----------------------------
select_desktop_env() {
    echo -e "${CLR_BOLD}Select Desktop Environment to install / เลือก Desktop Environment ที่ต้องการติดตั้ง:${CLR_RESET}"
    echo "  1) Xfce - light & stable / เบา เสถียร (แนะนำ)"
    echo "  2) MATE (minimal) - classic & simple / หน้าตาคลาสสิก ใช้งานง่าย ใกล้เคียง Xfce"
    echo "  q) Cancel / ยกเลิก"

    while true; do
        read -rp "Enter choice (1/2) or q: " choice
        case "$choice" in
            1)
                DESKTOP_NAME="Xfce"
                SESSION_CMD="startxfce4"
                DE_PACKAGES="xfce4 xfce4-goodies"
                ok "Selected Xfce / เลือก Xfce"
                break
                ;;
            2)
                DESKTOP_NAME="MATE (minimal)"
                SESSION_CMD="mate-session"
                DE_PACKAGES="ubuntu-mate-core"
                ok "Selected MATE (minimal) / เลือก MATE (minimal)"
                break
                ;;
            q|Q)
                warn "Cancelled by user / ยกเลิกการทำงาน"
                exit 0
                ;;
            *)
                warn "Invalid choice, please try again / ตัวเลือกไม่ถูกต้อง กรุณาลองใหม่"
                ;;
        esac
    done
}

#-----------------------------
# Detect target user (for RDP login)
#-----------------------------
detect_target_user() {
    TARGET_USER="${SUDO_USER:-$USER}"

    if [ "$TARGET_USER" = "root" ]; then
        warn "Running as root, session will be configured for root / กำลังรันในฐานะ root จะตั้งค่า session ให้ root"
        USER_HOME="/root"
    else
        USER_HOME="/home/$TARGET_USER"
    fi

    if [ ! -d "$USER_HOME" ]; then
        warn "Home directory for $TARGET_USER not found at $USER_HOME / ไม่พบ home directory ของ $TARGET_USER ที่ $USER_HOME"
        warn "You can still login via RDP with other users but may need to configure session manually / ยังสามารถใช้ RDP login ด้วย user อื่นได้ แต่ต้องตั้งค่า session เองภายหลัง"
    fi

    info "User to test RDP login: ${TARGET_USER} / User สำหรับทดสอบ login RDP: ${TARGET_USER}"
}

#-----------------------------
# Install base packages + XRDP
#-----------------------------
install_common_packages() {
    info "Updating package list... / อัปเดตรายการแพ็กเกจ..."
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y

    info "Upgrading packages (this may take a while)... / อัปเกรดแพ็กเกจ (อาจใช้เวลาสักพัก)..."
    apt-get upgrade -y

    info "Installing base packages for GUI + XRDP... / ติดตั้งแพ็กเกจพื้นฐานสำหรับ GUI + XRDP..."
    apt-get install -y xorg dbus-x11 x11-xserver-utils xinit
    apt-get install -y xrdp
    apt-get install -y wget gnupg
}

#-----------------------------
# Install selected Desktop Environment
#-----------------------------
install_desktop_env() {
    info "Installing Desktop Environment: ${DESKTOP_NAME} / ติดตั้ง Desktop Environment: ${DESKTOP_NAME}"
    apt-get install -y $DE_PACKAGES
    ok "Desktop Environment installed: ${DESKTOP_NAME} / ติดตั้ง ${DESKTOP_NAME} เสร็จแล้ว"
}

#-----------------------------
# Install Google Chrome
#-----------------------------
install_google_chrome() {
    info "Installing Google Chrome browser... / ติดตั้ง Google Chrome..."

    if command -v google-chrome >/dev/null 2>&1 || command -v google-chrome-stable >/dev/null 2>&1; then
        ok "Google Chrome is already installed. / พบว่า Google Chrome ถูกติดตั้งแล้ว"
        return
    fi

    mkdir -p /usr/share/keyrings

    if ! wget -q -O- https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor > /usr/share/keyrings/google-linux-signing-keyring.gpg; then
        warn "Failed to add Google signing key, skipping Chrome install. / เพิ่ม signing key ของ Google ไม่สำเร็จ ข้ามการติดตั้ง Chrome"
        return
    fi

    cat >/etc/apt/sources.list.d/google-chrome.list <<EOF
deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/google-linux-signing-keyring.gpg] http://dl.google.com/linux/chrome/deb/ stable main
EOF

    if ! apt-get update -y; then
        warn "apt-get update failed after adding Chrome repo. / apt-get update ล้มเหลวหลังเพิ่ม repo Chrome"
        return
    fi

    if apt-get install -y google-chrome-stable; then
        ok "Google Chrome installed. / ติดตั้ง Google Chrome เสร็จแล้ว"
    else
        warn "Failed to install Google Chrome. / ติดตั้ง Google Chrome ไม่สำเร็จ"
    fi
}

#-----------------------------
# Configure XRDP
#-----------------------------
configure_xrdp() {
    info "Configuring XRDP... / ตั้งค่า XRDP..."

    # Backup original startwm.sh if exists
    if [ -f /etc/xrdp/startwm.sh ]; then
        BACKUP_FILE="/etc/xrdp/startwm.sh.bak.$(date +%F-%H%M%S)"
        cp /etc/xrdp/startwm.sh "$BACKUP_FILE"
        info "Backed up /etc/xrdp/startwm.sh to $BACKUP_FILE / สำรอง /etc/xrdp/startwm.sh เป็น $BACKUP_FILE"
    fi

    # Create new startwm.sh similar to your Copilot config
    cat >/etc/xrdp/startwm.sh <<EOF
#!/bin/sh
# startwm.sh configured by remotegui.sh
# Start selected desktop session (Xfce or MATE)

# Load global profile if available
if [ -r /etc/profile ]; then
    . /etc/profile
fi

# Load locale if available
if [ -r /etc/default/locale ]; then
    . /etc/default/locale
    export LANG LANGUAGE
fi

# Ensure XDG_RUNTIME_DIR is set (important for some DE components)
export XDG_RUNTIME_DIR="/run/user/\$(id -u)"

# Start the selected desktop session
exec ${SESSION_CMD}
EOF

    chmod +x /etc/xrdp/startwm.sh

    # Add xrdp user to ssl-cert group (for cert access)
    if getent group ssl-cert >/dev/null 2>&1; then
        adduser xrdp ssl-cert >/dev/null 2>&1 || true
    fi

    # Create per-user .xsession like Copilot did
    if [ -d "$USER_HOME" ]; then
        info "Creating ~/.xsession for user: $TARGET_USER / สร้างไฟล์ ~/.xsession สำหรับ user: $TARGET_USER"

        # Just the session command (startxfce4 or mate-session)
        cat >"${USER_HOME}/.xsession" <<EOF
${SESSION_CMD}
EOF

        chown "${TARGET_USER}:${TARGET_USER}" "${USER_HOME}/.xsession" 2>/dev/null || true
        chmod +x "${USER_HOME}/.xsession" 2>/dev/null || true
    fi

    # Enable and restart XRDP
    systemctl enable --now xrdp >/dev/null 2>&1 || true
    systemctl restart xrdp || true

    ok "XRDP configured / ตั้งค่า XRDP เสร็จแล้ว"
}

#-----------------------------
# Configure firewall (UFW)
#-----------------------------
configure_firewall() {
    if command -v ufw >/dev/null 2>&1; then
        UFW_STATUS=$(ufw status | head -n1 | awk '{print $2}')
        if [ "$UFW_STATUS" = "active" ]; then
            info "UFW detected, allowing port 3389/tcp for RDP... / ตรวจพบ UFW ทำการเปิดพอร์ต 3389/tcp สำหรับ RDP..."
            ufw allow 3389/tcp || warn "Failed to open port 3389 on UFW, please check manually / เปิดพอร์ต 3389 บน UFW ไม่สำเร็จ กรุณาตรวจสอบเอง"
        else
            info "UFW is not active (status: $UFW_STATUS), skipping firewall config / UFW ไม่ได้เปิดใช้งาน (status: $UFW_STATUS) ข้ามการตั้งค่า firewall"
        fi
    else
        info "UFW not found, skipping firewall config / ไม่พบ UFW ข้ามการตั้งค่า firewall (หากมี firewall อื่น กรุณาเปิดพอร์ต 3389 เอง)"
    fi
}

#-----------------------------
# Show summary
#-----------------------------
show_summary() {
    echo
    echo -e "${CLR_BOLD}${CLR_GREEN}=== Installation Completed === / === การติดตั้งเสร็จสมบูรณ์ ===${CLR_RESET}"
    echo
    SERVER_IP=$(hostname -I 2>/dev/null | awk '{print $1}')

    if [ -n "$SERVER_IP" ]; then
        echo -e "VPS IP address: ${CLR_BOLD}$SERVER_IP${CLR_RESET} / IP ของ VPS คุณ: ${CLR_BOLD}$SERVER_IP${CLR_RESET}"
    else
        echo -e "Could not detect IP automatically. Use 'ip addr show' to check. / ไม่สามารถตรวจจับ IP ได้อัตโนมัติ ให้ใช้คำสั่ง 'ip addr show' เพื่อตรวจสอบ"
    fi

    cat <<EOF

Desktop Environment installed : ${DESKTOP_NAME}
Remote Desktop Protocol       : XRDP (Port 3389)
Browser                       : Google Chrome (if installation succeeded) / Google Chrome (หากติดตั้งสำเร็จ)

How to connect from your Desktop / วิธีเชื่อมต่อจากเครื่อง Desktop:

  1) Open a Remote Desktop (RDP) client
     - Windows: "Remote Desktop Connection"
     - macOS : "Microsoft Remote Desktop" (App Store)
     - Linux : remmina, rdesktop, xfreerdp

  2) Fill in:
     - Computer / Host:  VPS IP (e.g. ${SERVER_IP:-<server-ip>})
     - Port           :  3389
     - Username       :  ${TARGET_USER}  (or another existing user)
     - Password       :  User's password

  3) Click Connect and wait for the Desktop to appear.

Security recommendations (คำแนะนำด้านความปลอดภัย):
  - Use strong passwords for RDP users.
  - Restrict which IPs can access port 3389 (via UFW or your VPS firewall).
  - Consider using SSH tunnel to forward RDP instead of exposing port 3389 directly to the internet.

EOF
}

#-----------------------------
# main
#-----------------------------
main() {
    clear
    echo -e "${CLR_BOLD}Remote GUI Installer for Ubuntu VPS${CLR_RESET}"
    echo    "------------------------------------"
    echo

    require_root
    check_ubuntu
    select_desktop_env
    detect_target_user
    install_common_packages
    install_desktop_env
    install_google_chrome
    configure_xrdp
    configure_firewall
    show_summary
}

main "$@"
