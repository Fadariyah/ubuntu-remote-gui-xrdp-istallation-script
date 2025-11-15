# Remote GUI for Ubuntu VPS (XRDP + Xfce/MATE + Google Chrome)
---
### tDLR; Use this command
```bash
wget -q -O remotegui.sh https://raw.githubusercontent.com/Fadariyah/ubuntu-remote-gui-xrdp-istallation-script/refs/heads/main/remotegui.sh && sudo chmod +x remotegui.sh && sudo ./remotegui.sh
```
---
สคริปต์ `remotegui.sh` ใช้สำหรับติดตั้ง Desktop Environment แบบเบา ๆ (**Xfce** หรือ **MATE minimal**)  
พร้อมทั้งติดตั้ง **XRDP** เพื่อใช้ Remote Desktop (RDP) และติดตั้ง **Google Chrome** บน Ubuntu Server/VPS

หลังรันสคริปต์เสร็จ คุณสามารถเปิด Remote Desktop จากเครื่อง Windows/macOS/Linux แล้วต่อเข้า VPS ได้ทันที

---

## Features / คุณสมบัติ

- เลือกติดตั้ง Desktop Environment ได้ 2 แบบ:
  - **Xfce** – เบา เสถียร เหมาะกับการใช้งานทั่วไปบน VPS
  - **MATE (minimal)** – หน้าตาคลาสสิก ใช้งานง่าย ใกล้เคียง Xfce
- ติดตั้งและตั้งค่า **XRDP** (RDP server) ให้อัตโนมัติ
- สร้างไฟล์ session (`.xsession`) ให้กับ user ที่รันสคริปต์ (ผ่าน sudo)
- หากมี **UFW** และเปิดใช้งานอยู่ จะสั่ง `ufw allow 3389/tcp` ให้อัตโนมัติ
- ติดตั้ง **Google Chrome browser** บน Desktop ที่รันผ่าน RDP

---

## Requirements / สิ่งที่ต้องมี

- ระบบปฏิบัติการ: **Ubuntu Server** (เช่น 20.04 / 22.04 / 24.04)
- สิทธิ์: ต้องรันสคริปต์ด้วย **root** หรือ `sudo`
- อินเทอร์เน็ต: ต้องเชื่อมต่อ internet เพื่อดาวน์โหลดแพ็กเกจ และ Chrome

---

## Quick Usage (1-line install) / การใช้งานแบบ 1 บรรทัด

รันคำสั่งเดียวบน VPS (ในโฟลเดอร์ไหนก็ได้):

```bash
wget -q -O remotegui.sh https://raw.githubusercontent.com/Fadariyah/ubuntu-remote-gui-xrdp-istallation-script/refs/heads/main/remotegui.sh && sudo chmod +x remotegui.sh && sudo ./remotegui.sh
```

> ปรับ URL ให้ตรงกับ repo/branch ที่คุณใช้จริงบน GitHub ถ้าคุณเปลี่ยนชื่อ repo หรือสาขา

คำสั่งนี้จะ:
1. ดาวน์โหลดไฟล์ `remotegui.sh`
2. ให้สิทธิ์ execute
3. รันสคริปต์ด้วย `sudo`

---

## Manual Usage / การใช้งานแบบทีละขั้นตอน

### 1. Clone Repo (ถ้าคุณใช้ GitHub repo นี้)

```bash
git clone https://github.com/Fadariyah/ubuntu-remote-gui-xrdp-istallation-script.git
cd ubuntu-remote-gui-xrdp-istallation-script
```

### 2. ให้สิทธิ์รันสคริปต์

```bash
chmod +x remotegui.sh
```

### 3. รันสคริปต์ด้วย sudo

```bash
sudo ./remotegui.sh
```

---

## What the script does / สคริปต์ทำอะไรบ้าง

1. ตรวจสอบว่าเป็น Ubuntu และต้องรันด้วย root/sudo
2. ให้คุณเลือก Desktop Environment:
   - `1` → Xfce
   - `2` → MATE (minimal)
3. อัปเดตและอัปเกรดแพ็กเกจ (`apt-get update && apt-get upgrade`)
4. ติดตั้งแพ็กเกจพื้นฐานสำหรับ GUI + XRDP
5. ติดตั้ง Desktop Environment ที่เลือก
6. ติดตั้ง **Google Chrome** จาก official repo ของ Google
7. ตั้งค่า `/etc/xrdp/startwm.sh` ให้เรียก desktop ที่เลือก
8. สร้างไฟล์ `~/.xsession` ให้ user ที่รันสคริปต์ (ผ่าน sudo)
9. เปิด service XRDP และตั้งให้ start อัตโนมัติ
10. ถ้ามี UFW และเปิดใช้งาน จะเปิดพอร์ต `3389/tcp`
11. แสดง IP ของ VPS และสรุปวิธีการเชื่อมต่อ RDP

---

## Desktop Selection Menu / เมนูเลือก Desktop

ตอนรันสคริปต์จะเห็นเมนูประมาณนี้:

```text
Select Desktop Environment to install / เลือก Desktop Environment ที่ต้องการติดตั้ง:
  1) Xfce - light & stable / เบา เสถียร (แนะนำ)
  2) MATE (minimal) - classic & simple / หน้าตาคลาสสิก ใช้งานง่าย ใกล้เคียง Xfce
  q) Cancel / ยกเลิก

Enter choice (1/2) or q:
```

เลือกหมายเลขแล้วกด Enter

---

## Connect via Remote Desktop / การเชื่อมต่อผ่าน Remote Desktop

หลังสคริปต์รันเสร็จ จะมีสรุปหน้าจอว่า:

- Desktop Environment ที่ติดตั้ง
- IP ของ VPS
- มี XRDP เปิดพอร์ต **3389**

### Windows

1. เปิด **Remote Desktop Connection** (`mstsc`)
2. ใส่:
   - Computer: IP ของ VPS (เช่น `203.0.113.10`)
3. กด Connect
4. ใส่ Username/Password ตาม user บน Ubuntu (เช่น user ที่ใช้ `ssh`)

### macOS

1. ติดตั้ง **Microsoft Remote Desktop** จาก Mac App Store
2. Add PC → ใส่ IP
3. ดับเบิลคลิกแล้ว login

### Linux

- ใช้ `remmina`, `rdesktop`, หรือ `xfreerdp`

---

## Notes / หมายเหตุ

- ถ้าใช้ `sudo ./remotegui.sh`  
  - สคริปต์จะถือว่า user เป้าหมายคือ `$SUDO_USER`  
  - เวลาต่อ RDP ให้ใช้ user เดียวกับที่ใช้ `ssh` ปกติ
- ถ้ารันเป็น root โดยตรง  
  - สคริปต์จะตั้งค่า session ให้ root (`/root/.xsession`)  
  - ไม่แนะนำให้ login RDP เป็น root ในการใช้งานจริง

---

## Troubleshooting / ปัญหาที่พบบ่อย

### RDP ขึ้นจอดำ / เด้งออก

```bash
sudo systemctl status xrdp
sudo systemctl restart xrdp
```

### ต่อไม่ติดเลย (Connection error)

- เช็ค firewall:
  ```bash
  sudo ufw status
  sudo ufw allow 3389/tcp
  ```
- เช็คว่า IP ถูกต้อง และสามารถ `ssh` เข้าได้ปกติ

---

## Security Tips / ทิปด้านความปลอดภัย

- ตั้งรหัสผ่านที่เดายากสำหรับทุก user ที่ใช้ RDP
- จำกัด IP ที่อนุญาตเข้าถึงพอร์ต 3389 (ผ่าน UFW หรือ firewall ของผู้ให้บริการ VPS)
- พิจารณาใช้ SSH tunnel เพื่อ forward RDP แทนการเปิดพอร์ตกับ internet ตรง ๆ

---

## License

เลือก License ตามที่คุณต้องการบน GitHub (แนะนำ MIT หรืออื่น ๆ ตามสะดวก)
