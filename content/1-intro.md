---
title: Azure vTAP 소개
nav: Intro
topics: vTAP; Packet Mirroring; VXLAN
description: Azure Virtual Network TAP의 개요, 동작 원리, 핵심 개념을 설명합니다.
---

## Azure Virtual Network TAP 이란?

**Azure Virtual Network TAP(Terminal Access Point)** 은 가상 머신의 네트워크 인터페이스(NIC)를 통과하는 트래픽을 **실시간으로 복제(미러링)** 하여, 지정된 대상(Collector)으로 전송하는 기능입니다.

- 원본 트래픽에 **성능 영향 없음**
- NIC 레벨에서 동작하므로 **Load Balancer, Application Gateway와 무관**
- 복제된 패킷은 **VXLAN(UDP 4789)** 형태로 캡슐화되어 전달

## 동작 원리

```
                    ┌─────────────────┐
                    │  Application    │
                    │  Gateway (L7)   │
                    └────────┬────────┘
                             │  HTTP 요청
                             ▼
                    ┌─────────────────┐
                    │   App VM NIC    │◄── vTAP Source
                    │   (vm-app)      │
                    └────────┬────────┘
                             │
                ┌────────────┴────────────┐
                │                         │
                ▼                         ▼
        ┌──────────────┐        ┌──────────────────┐
        │ 원본 트래픽   │        │ 미러링 트래픽      │
        │ (정상 처리)   │        │ (VXLAN UDP 4789) │
        └──────────────┘        └────────┬─────────┘
                                         │
                                         ▼
                                ┌──────────────────┐
                                │  Collector VM NIC │◄── vTAP Destination
                                │  (vm-collector)   │
                                └──────────────────┘
```

## 핵심 개념

| 개념 | 설명 |
|------|------|
| **vTAP Source** | 트래픽을 미러링할 대상 VM의 NIC |
| **vTAP Destination** | 미러링된 트래픽을 수신할 Collector VM NIC |
| **VXLAN 캡슐화** | 미러링 패킷은 UDP 4789 포트로 VXLAN 캡슐화되어 전달 |
| **포트 4789** | Collector VM의 NSG에서 이 포트를 반드시 허용해야 함 |

## 이 데모의 트래픽 흐름

1. **Local PC** → `curl http://<AppGW_Public_IP>` 로 HTTP 요청 발생
2. **Application Gateway** → Backend Pool을 통해 `vm-app`으로 전달
3. **vm-app (Nginx)** → 요청을 처리하고 응답 반환
4. **vTAP** → `vm-app` NIC에서 수신/송신 패킷을 복제
5. **vm-collector (Wireshark)** → 복제된 VXLAN 패킷 수신 및 분석 가능

## 실습 네트워크 구성

| 리소스 | 서브넷 | CIDR |
|--------|--------|------|
| App VM | snet-app | 10.0.1.0/24 |
| Collector VM | snet-collector | 10.0.2.0/24 |
| Application Gateway | snet-agw | 10.0.3.0/24 |

> 💡 **서브넷 분리 이유**  
> 역할별 서브넷 분리를 통해 트래픽 흐름과 데모 목적을 명확히 합니다.


