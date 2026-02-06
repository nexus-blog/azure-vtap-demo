---
title: 테스트 및 분석
nav: Test
topics: Wireshark; HTTP; VXLAN; Packet Capture
description: 트래픽을 생성하고 Collector VM의 Wireshark에서 미러링된 패킷을 분석합니다.
---

이 단계에서는 **Local PC → Application Gateway → App VM**으로 전달되는 실제 트래픽과,  
해당 트래픽이 **vTAP을 통해 Collector VM으로 복제되는 과정**을 단계적으로 확인합니다.

## Step 1: HTTP 트래픽 생성

Local PC에서 Application Gateway Public IP로 HTTP 요청을 보냅니다.

```bash
# Application Gateway Public IP 확인
az network public-ip show \
  --resource-group rg-vtap-lab \
  --name pip-agw \
  --query ipAddress -o tsv

# HTTP 요청 전송
curl http://<APPLICATION_GATEWAY_PUBLIC_IP>
```

### 예상 응답

Nginx 기본 페이지 HTML이 반환됩니다.

```html
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...
```

### 처리 흐름

```
1. Local PC에서 HTTP 요청 생성
        ↓
2. Application Gateway가 요청 수신
        ↓
3. Backend Pool을 통해 vm-app 전달
        ↓
4. vm-app(Nginx)에서 응답 반환
        ↓ (동시에)
5. vTAP이 NIC 레벨에서 패킷 복제 → Collector VM 전송
```

## Step 2: Collector VM에서 Wireshark 캡처 시작

1. `vm-collector` VM에 RDP 접속
2. **Wireshark** 실행
3. **Capture Interface**: `Ethernet` 선택
4. 캡처 시작 (▶ 버튼)

## Step 3: Display Filter 적용

Wireshark에서 미러링된 트래픽만 필터링합니다.

### 기본 필터

```
ip.addr == 10.0.1.4 && tcp.port == 80
```

- `10.0.1.4` : vm-app Private IP
- `tcp.port == 80` : HTTP 트래픽

### Application Gateway 인스턴스 필터

```
ip.addr == 10.0.3.4 || ip.addr == 10.0.3.5
```

- `10.0.3.4`, `10.0.3.5` : Application Gateway 인스턴스 Private IP

### VXLAN 캡슐화 필터

```
udp.port == 4789
```

## Step 4: 트래픽 분석

### 확인 내용

| 확인 항목 | 기대 결과 |
|-----------|----------|
| Source IP | Application Gateway 인스턴스 IP (10.0.3.x) |
| Destination IP | vm-app Private IP (10.0.1.4) |
| Protocol | HTTP (TCP 80) |
| 캡슐화 | VXLAN (UDP 4789) |

### Wireshark 화면 예시

{% include figure.html img="09_wireshark.png" alt="Wireshark 미러링 트래픽 분석" caption="Wireshark에서 확인된 미러링 트래픽" width="100%" %}

Application Gateway를 통해 유입된 HTTP 트래픽에 대해, Application Gateway 인스턴스 Private IP (`10.0.3.4`, `10.0.3.5`) → vm-app Private IP (`10.0.1.4`)로 미러링된 트래픽이 기록됨을 확인할 수 있습니다.

## vTAP 동작 원리 요약

| 항목 | 설명 |
|------|------|
| 동작 위치 | VM NIC 레벨 (Load Balancer/Gateway와 무관) |
| 미러링 대상 | vm-app NIC에서 수신된 모든 패킷 |
| 전달 방식 | VXLAN(UDP 4789) 캡슐화 |
| 원본 영향 | 없음 — 원본 트래픽은 정상 처리 |

## 트러블슈팅

### Wireshark에서 패킷이 보이지 않는 경우

1. **NSG 확인**: Collector VM의 NSG에서 UDP 4789 인바운드가 허용되어 있는지 확인
2. **vTAP 상태 확인**: `az network vnet tap show` 명령으로 상태 확인
3. **NIC 연결 확인**: vTAP Source에 vm-app NIC가 정상 연결되어 있는지 확인
4. **캡처 인터페이스**: Wireshark에서 올바른 네트워크 인터페이스를 선택했는지 확인


