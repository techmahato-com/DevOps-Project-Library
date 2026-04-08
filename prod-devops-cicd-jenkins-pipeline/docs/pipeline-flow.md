# Pipeline Flow

## Stages

```
Git Push (webhook or poll SCM)
  │
  ▼
1. Checkout          — Clone source from Git
  │
  ▼
2. Build             — mvn clean package -DskipTests
  │
  ▼
3. Unit Test         — mvn test
  │
  ▼
4. SonarQube Scan    — mvn sonar:sonar → quality gate check
  │                    SonarQube: http://10.0.12.24:9000
  ▼
5. OWASP DC Scan     — /opt/owasp-dc/bin/dependency-check.sh
  │                    Fails pipeline on CVSS >= 7.0
  ▼
6. Docker Build      — docker build -t <ecr-repo>:<git-sha> .
  │
  ▼
7. Trivy Scan        — trivy image --exit-code 1 --severity HIGH,CRITICAL
  │                    Trivy v0.69.3 installed at /usr/bin/trivy
  ▼
8. Docker Push       — ECR login via IAM role + docker push
  │                    ECR: myapp-dev-app (441345502954.dkr.ecr.us-east-1.amazonaws.com)
  ▼
9. Deploy            — SSM Run Command (EC2) or kubectl apply (future EKS)
  │
  ▼
10. Health Check     — curl endpoint, verify HTTP 200
```

## Jenkinsfile Location

`app/Jenkinsfile` — Declarative pipeline.

## ECR Image Tagging Convention

```
441345502954.dkr.ecr.us-east-1.amazonaws.com/myapp-dev-app:<git-sha>
```

## Quality Gates

| Tool | Failure Condition |
|---|---|
| SonarQube | Quality gate status != `OK` |
| OWASP DC | Any dependency with CVSS >= 7.0 |
| Trivy | Any HIGH or CRITICAL CVE in Docker image |

## ECR Lifecycle Policy

- Keep last 10 tagged images (prefixed `v`, `release`, `latest`)
- Expire untagged images after 7 days

## Tool Paths on Jenkins EC2

| Tool | Path |
|---|---|
| Maven | `/opt/maven/bin/mvn` |
| Trivy | `/usr/bin/trivy` |
| OWASP DC | `/opt/owasp-dc/bin/dependency-check.sh` |
| Docker | `/usr/bin/docker` |
| Java | `/usr/lib/jvm/java-17-amazon-corretto.x86_64` |
