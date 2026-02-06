---
title: Bicep으로 인프라 배포
nav: Deploy
topics: Bicep; ARM Template; Azure CLI
description: Bicep 템플릿을 사용하여 vTAP 실습에 필요한 전체 인프라를 일괄 배포합니다.
---

이 단계에서는 Bicep 템플릿을 사용하여 vTAP 실습에 필요한 전체 인프라를 일괄 배포합니다.

## 배포되는 리소스

| 리소스 | 이름 | 설명 |
|--------|------|------|
| Resource Group | rg-vtap-lab | 실습 리소스 그룹 |
| Virtual Network | vnet-vtap-lab | 10.0.0.0/16 |
| Subnet — App | snet-app | 10.0.1.0/24 |
| Subnet — Collector | snet-collector | 10.0.2.0/24 |
| Subnet — AppGW | snet-agw | 10.0.3.0/24 |
| VM (Linux) | vm-app | Ubuntu 24.04 + Nginx |
| VM (Windows) | vm-collector | Windows Server 2022 |
| Application Gateway | agw-vtap-lab | Standard V2, HTTP 80 |
| NSG | nsg-app / nsg-collector | SSH(22), HTTP(80), UDP(4789) |
| Public IP | pip-app / pip-collector / pip-agw | 각 리소스용 공용 IP |

## 배포 방법

### 1. 리소스 그룹 생성

```bash
az group create \
  --name rg-vtap-lab \
  --location koreacentral
```

### 2. Bicep 배포 실행

```bash
az deployment group create \
  --resource-group rg-vtap-lab \
  --template-file infra/main.bicep \
  --parameters infra/main.parameters.json
```

> 💡 배포에는 약 **10~15분**이 소요됩니다. Application Gateway 프로비저닝에 가장 많은 시간이 걸립니다.

### 3. 배포 결과 확인

```bash
# 배포 상태 확인
az deployment group show \
  --resource-group rg-vtap-lab \
  --name main \
  --query properties.provisioningState -o tsv

# 배포 출력값 확인
az deployment group show \
  --resource-group rg-vtap-lab \
  --name main \
  --query properties.outputs -o json
```

## Nginx 설치 (App VM)

Bicep 배포 후, App VM에 SSH로 접속하여 Nginx를 설치합니다.

```bash
# App VM SSH 접속
ssh azureuser@<APP_VM_PUBLIC_IP>

# Nginx 설치 및 시작
sudo apt update
sudo apt install -y nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# 설치 확인
curl http://localhost
```

{% include figure.html img="04_nginx_check.png" alt="Nginx 확인" caption="Nginx 기본 페이지 확인" width="75%" %}

## Wireshark 설치 (Collector VM)

Collector VM에 RDP로 접속하여 Wireshark를 설치합니다.

1. RDP로 `vm-collector` 접속
2. [Wireshark 다운로드](https://www.wireshark.org/download.html) 페이지에서 Windows 64-bit Installer 다운로드
3. 설치 진행 (Npcap 포함)

## Bicep 템플릿 구조

```
infra/
├── main.bicep              # 메인 템플릿 (VNet, VM, AppGW 등)
└── main.parameters.json    # 파라미터 파일 (비밀번호 등)
```

> 📌 파라미터 파일에서 VM 관리자 비밀번호를 반드시 변경하세요.


