---
title: vTAP 구성
nav: vTAP
topics: vTAP; Source; Destination; VXLAN 4789
description: vm-app NIC에서 수신/송신되는 트래픽을 복제하여 vm-collector NIC로 미러링되도록 vTAP을 구성합니다.
---

이 단계에서는 **vm-app NIC에서 수신/송신되는 트래픽을 복제**하여, **vm-collector(Collector VM) NIC로 미러링**되도록 vTAP을 구성합니다.

> 💡 vTAP은 Application Gateway나 Load Balancer가 아니라, **VM의 NIC(Network Interface) 레벨**에서 동작합니다.

## Azure Portal에서 구성

### Step 1: vTAP 리소스 생성

1. Azure Portal 검색창에서 `Virtual network terminal access points` 검색
2. **+ Create** 클릭

### Step 2: Basics 탭

| 항목 | 값 |
|------|-----|
| Name | `vtap-app-to-collector` |
| Region | Korea Central |
| Resource group | `rg-vtap-lab` |
| Destination IP address | Select destination resource 선택 |
| Destination resource type | Network interface |
| Destination port | 4789 |
| NIC | `vm-collector` NIC 선택 |

{% include figure.html img="07_vtap_destination.png" alt="vTAP Destination 설정" caption="vTAP Destination 설정" width="75%" %}

### Step 3: Source 탭

- **Network Interface**: `vm-app` NIC 선택 후 **Add**

{% include figure.html img="08_vtap_source.png" alt="vTAP Source 설정" caption="vTAP Source — vm-app NIC 추가" width="75%" %}

### Step 4: 배포

- **Review + Create** → **Create**

## Azure CLI로 구성 (대안)

Portal 대신 CLI로도 vTAP을 구성할 수 있습니다.

```bash
# vm-app NIC ID 조회
APP_NIC_ID=$(az vm show \
  --resource-group rg-vtap-lab \
  --name vm-app \
  --query "networkProfile.networkInterfaces[0].id" -o tsv)

# vm-collector NIC ID 조회
COLLECTOR_NIC_ID=$(az vm show \
  --resource-group rg-vtap-lab \
  --name vm-collector \
  --query "networkProfile.networkInterfaces[0].id" -o tsv)

# vTAP 리소스 생성
az network vnet tap create \
  --resource-group rg-vtap-lab \
  --name vtap-app-to-collector \
  --destination $COLLECTOR_NIC_ID \
  --port 4789

# vTAP에 Source NIC 연결
az network nic vtap-config create \
  --resource-group rg-vtap-lab \
  --nic-name $(basename $APP_NIC_ID) \
  --vtap-config-name vtap-config-app \
  --vnet-tap $( az network vnet tap show \
    --resource-group rg-vtap-lab \
    --name vtap-app-to-collector \
    --query id -o tsv)
```

## 주요 설정 포인트

### Destination Port : 4789

> 💡 Destination port(기본 4789)는 **미러링 패킷을 Collector로 전달할 때 사용되는 VXLAN 캡슐화 포트**입니다.  
> 원본 HTTP 트래픽의 포트(80)와는 무관합니다.

### Collector VM NSG 확인

Collector VM의 NSG에서 **UDP 4789 인바운드** 규칙이 허용되어 있는지 반드시 확인하세요.

```bash
# NSG 규칙 확인
az network nsg rule list \
  --resource-group rg-vtap-lab \
  --nsg-name nsg-collector \
  -o table
```

필요한 경우 규칙 추가:

```bash
az network nsg rule create \
  --resource-group rg-vtap-lab \
  --nsg-name nsg-collector \
  --name Allow-VXLAN-4789 \
  --priority 100 \
  --direction Inbound \
  --access Allow \
  --protocol Udp \
  --destination-port-ranges 4789
```

## 구성 확인

```bash
# vTAP 상태 확인
az network vnet tap show \
  --resource-group rg-vtap-lab \
  --name vtap-app-to-collector \
  -o table
```


