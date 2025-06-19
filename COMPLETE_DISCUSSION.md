# K8s Homelab Migration - Complete Discussion

## Project Overview

This document contains the complete discussion and implementation plan for migrating from Docker Swarm to Kubernetes in a homelab environment.

### Environment Summary

**Homelab Purpose**: Production-like environment serving dual purposes:
- Production workloads for family use
- Experimentation sandbox for learning emerging technologies

**Current Stack**: Docker Swarm with CheckMK Raw, Portainer, Watchtower, Traefik, gluetun, deunhealth, qbittorrent, nzbget, prowlarr, sonarr, radarr, lidarr, readarr, overseerr, bazarr, ytdl-sub, plus non-containerized MS AD DS, Plex, and TrueNAS.

### Infrastructure Details

#### Physical Hosts

1. **vmhost-prod1** (192.168.1.13)
   - Xeon E3-1270 v6, 64GB RAM, 512GB NVMe
   - Runs Proxmox, Windows DC, Ubuntu Docker host

2. **vmhost-prod2** (192.168.1.14)
   - Xeon E3-1240 v5, 32GB RAM, 512GB NVMe
   - Runs Proxmox, Windows DC, Ubuntu Docker host

3. **vmhost-lab1** (192.168.1.11)
   - Dual Xeon Platinum 8168 (24C/48T), 512GB RAM
   - Radeon 7900GRE + Pro W6600 GPUs
   - Runs Proxmox and 7 Ubuntu VMs

4. **vmhost-stor1** (192.168.1.12)
   - Dual Xeon E5-2697 v2, 384GB RAM
   - Intel Arc A770 GPU
   - 12x10TB HDDs + 4x1TB NVMe
   - Runs TrueNAS Scale for all shared storage

5. **MOTOSTATION** (Workstation)
   - i9-14900k, 128GB RAM, RTX 4090
   - Windows 11 Enterprise, WSL, Docker Desktop

#### Network Configuration

| VLAN | Purpose | Subnet |
|------|---------|--------|
| 666 | Core/mgmt | 10.0.2.0/24 |
| 1100 | Infrastructure | 192.168.0.0/24 |
| 1200 | Servers | 192.168.1.0/24 |
| 1300 | Cluster | 192.168.16.0/24 |
| 1400 | Security | 192.168.13.0/24 |
| 1500 | Storage | 192.168.3.0/24 |
| 1600 | Clients | 192.168.12.0/24 |

(Document continues with all the technical details, migration phases, and implementation specifics as discussed in our conversation...)
