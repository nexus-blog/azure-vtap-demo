---
title: 사전 준비
nav: Prep
topics: Azure CLI; Bicep; SSH; RDP
description: vTAP 실습을 시작하기 전에 필요한 Azure 구독, 도구 설치 등 사전 요구 사항을 확인합니다.
---

vTAP 실습을 시작하기 전에 아래 사항을 확인하세요.

## Azure 구독 요구 사항

| 항목 | 요구 사항 |
|------|-----------|
| Azure 구독 | 활성화된 구독 (Pay-As-You-Go 또는 Enterprise) |
| 리전 | **Korea Central** (vTAP Preview 지원 리전) |
| 권한 | 구독 또는 리소스 그룹에 대한 **Contributor** 이상 |

> ⚠️ Azure vTAP은 Preview 기능입니다. 구독에서 `Microsoft.Network/virtualNetworkTaps` 리소스 공급자가 등록되어 있어야 합니다.

## 필요 도구

### 필수

- **Azure CLI** (v2.50+)  
  ```bash
  # 설치 확인
  az version
  ```

- **Bicep CLI** (Azure CLI에 포함됨)  
  ```bash
  az bicep version
  # 업그레이드
  az bicep upgrade
  ```

### 선택

- **Visual Studio Code** + [Bicep Extension](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-bicep)
- **Wireshark** — Collector VM에서 트래픽 분석 시 사용 (VM에 설치)
- **SSH 클라이언트** — App VM(Linux) 접속용
- **RDP 클라이언트** — Collector VM(Windows) 접속용

## Azure CLI 로그인

```bash
# Azure 로그인
az login

# 구독 선택
az account set --subscription "<YOUR_SUBSCRIPTION_ID>"

# 리소스 공급자 등록 확인
az provider show -n Microsoft.Network --query "registrationState" -o tsv
```

## 프로젝트 클론

```bash
git clone https://github.com/<your-org>/azure-vtap-demo.git
cd azure-vtap-demo
```


