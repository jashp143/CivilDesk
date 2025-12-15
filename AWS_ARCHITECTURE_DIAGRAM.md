# Civildesk AWS Architecture Diagrams

This document contains architecture diagrams in multiple formats for visualization.

---

## Architecture Overview (Mermaid)

```mermaid
graph TB
    subgraph Internet
        Users[Users/Mobile Apps]
    end
    
    subgraph AWS_Cloud
        subgraph CloudFront
            CDN[CloudFront CDN]
        end
        
        subgraph ALB_Layer
            ALB[Application Load Balancer<br/>SSL Termination<br/>Health Checks]
        end
        
        subgraph VPC["VPC (10.0.0.0/16)"]
            subgraph Public_Subnets["Public Subnets"]
                NAT[NAT Gateway]
            end
            
            subgraph Private_Subnets["Private Subnets"]
                subgraph EC2_Backend["EC2 Backend Instances"]
                    EC2_Backend1[EC2 Backend 1<br/>Spring Boot<br/>t3.medium]
                    EC2_Backend2[EC2 Backend 2<br/>Spring Boot<br/>t3.medium]
                end
                
                subgraph EC2_GPU["EC2 GPU Instance"]
                    FaceService[Face Recognition Service<br/>FastAPI + GPU]
                end
                
                subgraph Database_Layer["Database Layer"]
                    RDS[(RDS PostgreSQL<br/>Multi-AZ)]
                    Redis[(ElastiCache Redis<br/>Cluster)]
                end
            end
            
            subgraph S3_Layer["S3 Storage"]
                S3_Uploads[S3: Uploads<br/>Documents, Images]
                S3_Videos[S3: Videos<br/>Face Recognition]
                S3_Backups[S3: Backups<br/>Automated]
            end
        end
        
        subgraph AWS_Services["AWS Managed Services"]
            Secrets[Secrets Manager<br/>Credentials]
            CloudWatch[CloudWatch<br/>Logs & Metrics]
            Route53[Route 53<br/>DNS]
            ACM[Certificate Manager<br/>SSL/TLS]
        end
    end
    
    Users -->|HTTPS| CDN
    CDN -->|HTTPS| ALB
    ALB -->|HTTP| EC2_Backend1
    ALB -->|HTTP| EC2_Backend2
    ALB -->|HTTP| FaceService
    
    EC2_Backend1 -->|JDBC| RDS
    EC2_Backend2 -->|JDBC| RDS
    FaceService -->|psycopg2| RDS
    
    EC2_Backend1 -->|Redis Protocol| Redis
    EC2_Backend2 -->|Redis Protocol| Redis
    FaceService -->|Redis Protocol| Redis
    
    EC2_Backend1 -->|S3 API| S3_Uploads
    EC2_Backend2 -->|S3 API| S3_Uploads
    FaceService -->|S3 API| S3_Videos
    
    EC2_Backend1 -->|Read Secrets| Secrets
    EC2_Backend2 -->|Read Secrets| Secrets
    FaceService -->|Read Secrets| Secrets
    
    EC2_Backend1 -->|Logs| CloudWatch
    EC2_Backend2 -->|Logs| CloudWatch
    FaceService -->|Logs| CloudWatch
    
    ALB -->|SSL Cert| ACM
    Route53 -->|DNS| ALB
    
    EC2_Backend1 -.->|Auto Scaling| EC2_Backend2
```

---

## Network Architecture (Mermaid)

```mermaid
graph TB
    subgraph VPC["VPC: 10.0.0.0/16"]
        subgraph Public_Subnet_1a["Public Subnet 1a<br/>10.0.1.0/24<br/>us-east-1a"]
            ALB[Application Load Balancer]
            NAT1[NAT Gateway]
        end
        
        subgraph Public_Subnet_1b["Public Subnet 1b<br/>10.0.2.0/24<br/>us-east-1b"]
            NAT2[NAT Gateway<br/>Standby]
        end
        
        subgraph Private_Subnet_1a["Private Subnet 1a<br/>10.0.10.0/24<br/>us-east-1a"]
            ECS_Task_1[ECS Backend Task 1]
            EC2_Face[EC2 Face Service]
            RDS_Primary[(RDS Primary<br/>Multi-AZ)]
        end
        
        subgraph Private_Subnet_1b["Private Subnet 1b<br/>10.0.11.0/24<br/>us-east-1b"]
            ECS_Task_2[ECS Backend Task 2]
            RDS_Standby[(RDS Standby<br/>Multi-AZ)]
            Redis[(ElastiCache Redis)]
        end
    end
    
    Internet[Internet] -->|HTTPS| ALB
    ALB -->|HTTP| EC2_Backend1
    ALB -->|HTTP| EC2_Backend2
    ALB -->|HTTP| EC2_Face
    
    EC2_Backend1 -->|Via NAT| Internet
    EC2_Backend2 -->|Via NAT| Internet
    EC2_Face -->|Via NAT| Internet
    
    EC2_Backend1 --> RDS_Primary
    EC2_Backend2 --> RDS_Primary
    EC2_Face --> RDS_Primary
    
    RDS_Primary -.->|Replication| RDS_Standby
    
    EC2_Backend1 --> Redis
    EC2_Backend2 --> Redis
    EC2_Face --> Redis
```

---

## Data Flow Diagram (Mermaid)

```mermaid
sequenceDiagram
    participant User as Mobile App User
    participant ALB as Application Load Balancer
    participant EC2_Backend as EC2 Backend
    participant Face as Face Service
    participant RDS as RDS PostgreSQL
    participant Redis as ElastiCache
    participant S3 as S3 Buckets
    
    Note over User,S3: Authentication Flow
    User->>ALB: POST /api/auth/login
    ALB->>EC2_Backend: Forward Request
    EC2_Backend->>RDS: Validate Credentials
    RDS-->>EC2_Backend: User Data
    EC2_Backend->>Redis: Cache Session
    EC2_Backend-->>ALB: JWT Token
    ALB-->>User: Response with Token
    
    Note over User,S3: Face Recognition Flow
    User->>ALB: POST /api/face-recognition/verify
    ALB->>Face: Forward Request
    Face->>S3: Upload Video
    Face->>Face: Process Video (GPU)
    Face->>RDS: Query Face Embeddings
    RDS-->>Face: Embeddings Data
    Face->>Redis: Cache Results
    Face->>Face: Match Faces
    Face-->>ALB: Match Result
    ALB-->>User: Response
    
    Note over User,S3: File Upload Flow
    User->>ALB: POST /api/employees/upload
    ALB->>EC2_Backend: Forward Request
    EC2_Backend->>S3: Upload File
    S3-->>EC2_Backend: File URL
    EC2_Backend->>RDS: Save File Reference
    EC2_Backend-->>ALB: Success Response
    ALB-->>User: File URL
```

---

## Security Architecture (Mermaid)

```mermaid
graph TB
    subgraph Security_Layers["Security Layers"]
        subgraph Perimeter["Perimeter Security"]
            WAF[AWS WAF<br/>Optional]
            ALB_SG[ALB Security Group<br/>Ports 80, 443]
        end
        
        subgraph Network["Network Security"]
            VPC[VPC Isolation]
            Private_Subnets[Private Subnets]
            Security_Groups[Security Groups<br/>Least Privilege]
            NACL[Network ACLs<br/>Optional]
        end
        
        subgraph Application["Application Security"]
            IAM_Roles[IAM Roles<br/>Least Privilege]
            Secrets[Secrets Manager<br/>Encrypted]
            SSL[SSL/TLS<br/>End-to-End]
        end
        
        subgraph Data["Data Security"]
            Encryption_At_Rest[Encryption at Rest<br/>RDS, S3, EBS]
            Encryption_In_Transit[Encryption in Transit<br/>TLS 1.2+]
            Backup_Encryption[Backup Encryption]
        end
        
        subgraph Monitoring["Security Monitoring"]
            CloudTrail[CloudTrail<br/>Audit Logs]
            GuardDuty[GuardDuty<br/>Threat Detection]
            CloudWatch[CloudWatch<br/>Alarms]
        end
    end
    
    Internet --> WAF
    WAF --> ALB_SG
    ALB_SG --> VPC
    VPC --> Private_Subnets
    Private_Subnets --> Security_Groups
    Security_Groups --> IAM_Roles
    IAM_Roles --> Secrets
    Secrets --> Encryption_At_Rest
    Encryption_At_Rest --> Encryption_In_Transit
    Encryption_In_Transit --> Backup_Encryption
    Backup_Encryption --> CloudTrail
    CloudTrail --> GuardDuty
    GuardDuty --> CloudWatch
```

---

## High Availability Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Multi-AZ Deployment                       │
└─────────────────────────────────────────────────────────────┘

Availability Zone 1 (us-east-1a)          Availability Zone 2 (us-east-1b)
┌──────────────────────────────┐          ┌──────────────────────────────┐
│ Public Subnet                │          │ Public Subnet                │
│ - ALB Listener               │          │ - ALB Listener               │
│ - NAT Gateway (Active)       │          │ - NAT Gateway (Standby)     │
└──────────────────────────────┘          └──────────────────────────────┘
           │                                        │
           │                                        │
┌──────────────────────────────┐          ┌──────────────────────────────┐
│ Private Subnet               │          │ Private Subnet               │
│ - EC2 Backend Instance 1      │          │ - EC2 Backend Instance 2    │
│ - EC2 Face Service (Primary) │          │ - EC2 Face Service (Standby) │
│ - RDS Primary                │◄─────────┤ - RDS Standby (Multi-AZ)    │
│ - ElastiCache Node 1         │ Repl     │ - ElastiCache Node 2         │
└──────────────────────────────┘          └──────────────────────────────┘
           │                                        │
           └────────────────┬───────────────────────┘
                           │
                  ┌────────┴────────┐
                  │   S3 Buckets     │
                  │  (Multi-Region)  │
                  └──────────────────┘
```

---

## Cost Breakdown by Service

```mermaid
pie title Monthly AWS Costs (Estimated)
    "RDS PostgreSQL" : 150
    "EC2 GPU (g4dn.xlarge)" : 150
    "EC2 Backend" : 60
    "ElastiCache Redis" : 50
    "Application Load Balancer" : 20
    "Data Transfer" : 10
    "CloudWatch" : 10
    "S3 Storage" : 5
```

---

## Scaling Architecture

```mermaid
graph LR
    subgraph Auto_Scaling["Auto Scaling"]
        subgraph EC2_Scaling["EC2 Auto Scaling"]
            CPU_Metric[CPU Metric]
            CPU_Metric -->|> 70%| Scale_Out[Scale Out]
            CPU_Metric -->|< 30%| Scale_In[Scale In]
            Scale_Out --> EC2_Instances[More EC2 Instances]
            Scale_In --> EC2_Instances
        end
        
        subgraph EC2_Scaling["EC2 Scaling"]
            ASG[Auto Scaling Group]
            ASG --> EC2_Instances[Multiple EC2 Instances]
        end
    end
    
    subgraph Load_Distribution["Load Distribution"]
        ALB[Application Load Balancer]
        ALB --> EC2_Instances
        ALB --> EC2_Instances
    end
    
    subgraph Database_Scaling["Database Scaling"]
        RDS_Primary[(RDS Primary)]
        RDS_Read_Replica[(Read Replica)]
        RDS_Primary -.->|Replication| RDS_Read_Replica
    end
```

---

## Disaster Recovery Architecture

```
Primary Region (us-east-1)              Secondary Region (us-west-2)
┌──────────────────────────┐            ┌──────────────────────────┐
│ - EC2 Auto Scaling Group │            │ - EC2 Auto Scaling Group │
│ - RDS (Multi-AZ)         │            │ - RDS Read Replica       │
│ - ElastiCache            │            │ - ElastiCache (Standby)  │
│ - S3 Buckets             │───────────►│ - S3 Cross-Region Repl  │
│ - ALB                    │   Backup   │ - ALB (Standby)         │
└──────────────────────────┘            └──────────────────────────┘
         │                                        │
         └────────────────┬───────────────────────┘
                         │
              ┌───────────┴───────────┐
              │   Backup Strategy      │
              │ - RDS Automated        │
              │ - S3 Versioning        │
              │ - EC2 Launch Templates │
              │ - Configuration Files  │
              └────────────────────────┘
```

---

## Export Formats

### For Draw.io / Lucidchart

1. Copy the Mermaid diagrams above
2. Use online Mermaid editor: https://mermaid.live/
3. Export as PNG, SVG, or PDF
4. Import into draw.io or Lucidchart

### For Documentation

- Use Mermaid in Markdown (GitHub, GitLab support)
- Export as images for presentations
- Use in Confluence, Notion, or other documentation tools

---

## Architecture Components Summary

| Component | Service | Purpose | High Availability |
|-----------|---------|---------|-------------------|
| Load Balancing | ALB | Distribute traffic, SSL termination | Multi-AZ |
| Backend API | EC2 (t3.medium) | Spring Boot application | Auto-scaling, Multi-AZ |
| Face Recognition | EC2 GPU | FastAPI service with GPU | Auto Scaling Group |
| Database | RDS PostgreSQL | Primary data store | Multi-AZ, Automated backups |
| Cache | ElastiCache Redis | Session storage, caching | Cluster mode (optional) |
| File Storage | S3 | Documents, images, videos | Cross-region replication |
| Secrets | Secrets Manager | Credential storage | Multi-region |
| Monitoring | CloudWatch | Logs, metrics, alarms | Global service |
| DNS | Route 53 | Domain management | Global service |
| SSL/TLS | ACM | Certificate management | Global service |

---

**Last Updated**: December 2024

