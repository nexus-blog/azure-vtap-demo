---
title: Home
layout: page
---

# Azure Virtual Network TAP (vTAP) 실습 가이드

Azure Virtual Network TAP(vTAP)을 사용하여, 실제 애플리케이션 트래픽이 **패킷 미러링(Packet Mirroring)** 형태로 Collector VM으로 전달되는 동작을 확인하는 End-to-End 실습 가이드입니다.

> ⚠️ **Preview 기능 안내**  
> Azure vTAP은 2026년 현재 **Preview 상태**이며, **Azure Korea Central Region**도 Preview 대상 리전에 포함됩니다.  
> SLA가 제공되지 않으므로 프로덕션 적용 전 반드시 사전 검증(POC/데모)을 권장합니다.

## 아키텍처

```
[Local PC / Terminal]
        |
        |  HTTP (curl)
        v
[Application Gateway]
        |
        v
[App VM (Nginx)]
        |
        |  (Mirrored by vTAP)
        v
[Collector VM (Wireshark)]
```

## 확인 포인트

- Local 환경에서 발생한 실제 HTTP 요청
- Application Gateway → App VM 으로 전달되는 실트래픽
- App VM NIC 레벨에서 vTAP에 의해 복제되는 미러링 트래픽

{% include toc.html %}

------

{% include template/credits.html %}
