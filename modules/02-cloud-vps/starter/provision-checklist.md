# Lightsail Provisioning Checklist

Use this checklist to track your progress through the exercise.

## AWS Account
- [ ] Created AWS account (or already had one)
- [ ] Logged into the AWS console
- [ ] Navigated to Lightsail (lightsail.aws.amazon.com)

## Instance Creation
- [ ] Chose a region close to me
- [ ] Selected Linux/Unix platform
- [ ] Selected OS Only > Ubuntu 22.04 LTS
- [ ] Selected instance plan: ___________
- [ ] Named the instance: ___________
- [ ] Instance is running (status: Running)

## Firewall Configuration
- [ ] Deleted the default HTTP rule (port 80)
- [ ] Deleted the default HTTPS rule (port 443)
- [ ] Confirmed only SSH (port 22) remains
- [ ] Checked IPv6 firewall rules too

## Static IP
- [ ] Created a static IP
- [ ] Attached it to my instance
- [ ] Wrote down the IP address: ___________

## Verification
- [ ] Instance shows as "Running" in the dashboard
- [ ] Static IP is attached and shows on the Networking tab
- [ ] Firewall shows SSH only
- [ ] Filled in server-info.txt with my details
