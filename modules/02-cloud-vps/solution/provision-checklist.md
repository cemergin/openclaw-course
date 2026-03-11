# Lightsail Provisioning Checklist (Completed)

## AWS Account
- [x] Created AWS account (or already had one)
- [x] Logged into the AWS console
- [x] Navigated to Lightsail (lightsail.aws.amazon.com)

## Instance Creation
- [x] Chose a region close to me
- [x] Selected Linux/Unix platform
- [x] Selected OS Only > Ubuntu 22.04 LTS
- [x] Selected instance plan: **$10/month (1 vCPU, 2GB RAM, 60GB SSD)**
- [x] Named the instance: **openclaw-01**
- [x] Instance is running (status: Running)

## Firewall Configuration
- [x] Deleted the default HTTP rule (port 80)
- [x] Deleted the default HTTPS rule (port 443)
- [x] Confirmed only SSH (port 22) remains
- [x] Checked IPv6 firewall rules too

## Static IP
- [x] Created a static IP
- [x] Attached it to my instance
- [x] Wrote down the IP address: **18.194.42.137** (yours will differ)

## Verification
- [x] Instance shows as "Running" in the dashboard
- [x] Static IP is attached and shows on the Networking tab
- [x] Firewall shows SSH only
- [x] Filled in server-info.txt with my details
