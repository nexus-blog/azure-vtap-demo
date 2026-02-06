---
title: 리소스 정리
nav: Cleanup
topics: Resource Group; 비용 관리
description: 실습이 완료되면, 불필요한 과금을 방지하기 위해 생성된 리소스를 삭제합니다.
---

실습이 완료되면, 불필요한 과금을 방지하기 위해 생성된 리소스를 삭제합니다.

## 리소스 그룹 전체 삭제

가장 간단한 방법은 리소스 그룹 전체를 삭제하는 것입니다.

### Azure CLI

```bash
az group delete \
  --name rg-vtap-lab \
  --yes \
  --no-wait
```

> `--no-wait` 옵션을 사용하면 삭제가 백그라운드에서 진행됩니다.

### Azure Portal

1. **Resource groups** → `rg-vtap-lab` 선택
2. **Delete resource group** 클릭
3. 리소스 그룹 이름 입력 후 **Delete** 확인

## 삭제 확인

```bash
# 리소스 그룹 존재 여부 확인
az group exists --name rg-vtap-lab
```

`false`가 반환되면 정상적으로 삭제된 것입니다.

## 삭제되는 리소스 목록

| 리소스 유형 | 이름 |
|------------|------|
| Virtual Network | vnet-vtap-lab |
| VM (Linux) | vm-app |
| VM (Windows) | vm-collector |
| Application Gateway | agw-vtap-lab |
| vTAP | vtap-app-to-collector |
| NSG | nsg-app, nsg-collector |
| Public IP | pip-app, pip-collector, pip-agw |
| Disk | 각 VM의 OS Disk |
| NIC | 각 VM의 Network Interface |

> ⚠️ 리소스 그룹 삭제 시 **그룹 내 모든 리소스가 영구 삭제**됩니다. 삭제 전 필요한 데이터(Wireshark 캡처 파일 등)를 반드시 백업하세요.


