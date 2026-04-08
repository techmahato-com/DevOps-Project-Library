# Troubleshooting

## Terraform

**`terraform plan` shows changes after a clean apply**
- Check for manually added resources (inline policies, SG rules etc.) not in state
- Run `terraform state list` and compare against AWS console
- Fix: import the resource or remove it manually, then re-apply

**Error: S3 bucket already exists**
- Bucket names are globally unique. Update `bucket_suffix` in `terraform.tfvars`

**Error: Backend initialization failed**
- S3 bucket and DynamoDB table must exist first — follow bootstrap steps in `runbook.md`

**Error: `ignore_changes` attribute not found**
- EC2 module uses `ignore_changes = [ami, user_data]` — attribute must be `ami` not `ami_id`

**NAT instance not routing traffic**
- Verify `source_dest_check = false` on the NAT instance
- Verify private route table `0.0.0.0/0` points to NAT instance network interface
- Verify NAT SG allows inbound from private subnet CIDRs (`10.0.11.0/24`, `10.0.12.0/24`)

---

## Jenkins

**Jenkins UI not accessible on http://localhost:8080**
- Confirm SSM port forwarding session is active (see runbook)
- Confirm Jenkins service is running:
  ```bash
  # Via SSM session on i-0dedbe4a946c00b00
  sudo systemctl status jenkins
  ```
- Check bootstrap log: `sudo cat /var/log/jenkins-bootstrap.log`

**Jenkins service inactive / not installed**
- Bootstrap script failed — check log for the exact error
- Common cause: `wget` not available on AL2023 (use `curl` instead — already fixed in script)
- Common cause: Trivy RPM URL returned 404 — script now handles this non-fatally
- Re-run bootstrap via SSM (see runbook)

**Jenkins cannot push to ECR**
- Verify IAM instance profile `myapp-dev-profile-jenkins` is attached
- Test from SSM session: `aws ecr get-login-password --region us-east-1`
- Verify ECR policy in IAM module includes the correct repo ARNs

**Docker permission denied in Jenkins pipeline**
- Jenkins user must be in docker group:
  ```bash
  groups jenkins   # should include 'docker'
  sudo usermod -aG docker jenkins && sudo systemctl restart jenkins
  ```

**Maven not found in pipeline**
- Maven is at `/opt/maven/bin/mvn` — not on default PATH in non-interactive shells
- In Jenkinsfile, use full path or configure Maven in Jenkins Global Tool Configuration:
  `MAVEN_HOME = /opt/maven`

**`user_data` script did not run on instance creation**
- Verify `file()` is used in `main.tf` (not `filebase64()` — that double-encodes)
- Check cloud-init: `sudo cloud-init status --long`
- Check output: `sudo cat /var/log/cloud-init-output.log`

---

## SonarQube

**SonarQube container not starting**
- Check kernel param: `sysctl vm.max_map_count` — must be >= 524288
  ```bash
  sudo sysctl -w vm.max_map_count=524288
  ```
- Check container logs: `docker logs sonarqube`
- Elasticsearch needs >= 2GB RAM — t3.medium (4GB) is the minimum

**SonarQube UI not accessible**
- Confirm SSM port forwarding is active on port 9000 (see runbook)
- Confirm container is running: `docker ps --filter name=sonarqube`
- Container takes ~60 seconds to be ready after start

**SonarQube quality gate always passes**
- Ensure a quality gate is assigned to the project in SonarQube UI
- Verify `sonar.projectKey` in Jenkinsfile matches the SonarQube project key

---

## ECR

**Image push fails: no basic auth credentials**
- Re-authenticate:
  ```bash
  aws ecr get-login-password --region us-east-1 | \
    docker login --username AWS --password-stdin \
    441345502954.dkr.ecr.us-east-1.amazonaws.com
  ```

**Image pull fails on deployment target**
- Verify the target instance/role has `ecr:BatchGetImage` and `ecr:GetDownloadUrlForLayer`

---

## SSM

**`SessionManagerPlugin is not found`**
- Install the plugin on your local machine:
  - Windows: https://s3.amazonaws.com/session-manager-downloads/plugin/latest/windows/SessionManagerPluginSetup.exe
  - Mac: `brew install --cask session-manager-plugin`
  - Linux: https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html

**SSM session connects but commands fail with exit 127**
- `exec >` redirect causes issues in SSM's non-interactive shell
- Bootstrap scripts use `tee -a` for logging instead — already fixed

**Instance not appearing in SSM**
- Verify `AmazonSSMManagedInstanceCore` policy is attached to the instance role
- Verify SSM agent is running: `sudo systemctl status amazon-ssm-agent`
- Verify instance has outbound internet access via NAT to reach SSM endpoints
