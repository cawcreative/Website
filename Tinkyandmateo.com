# Tinkyandmateo.com - Build & Deployment Configuration

## Domain Information
- **Domain**: tinkyandmateo.com
- **Status**: Active
- **Owner**: cawcreative
- **Last Updated**: 2026-04-28

---

## DNS Records Configuration

### Primary Records (Required)

#### TXT Record (IPv4)
```
Host: @_github-pages-challenge-cawcreative
Type: A
Value: c2462f539b2440bd2479c2d157351f
TTL: 3600
Priority: N/A
```

#### AAAA Record (IPv6) - Optional
```
Host: @
Type: AAAA
Value: [YOUR_IPV6_ADDRESS]
TTL: 3600
Priority: N/A
```

#### CNAME Records
```
Host: www
Type: CNAME
Value: tinkyandmateo.com
TTL: 3600
Priority: N/A
```

### Email Records (if needed)

#### MX Record
```
Host: @
Type: MX
Value: mail.tinkyandmateo.com
TTL: 3600
Priority: 10
```

#### SPF Record
```
Host: @
Type: TXT
Value: v=spf1 include:_spf.google.com ~all
TTL: 3600
```

#### DKIM Record
```
Host: default._domainkey
Type: CNAME
Value: default.domainkey.tinkyandmateo.com
TTL: 3600
```

#### DMARC Record
```
Host: _dmarc
Type: TXT
Value: v=DMARC1; p=none; rua=mailto:admin@tinkyandmateo.com
TTL: 3600
```

### SSL/TLS Records

#### CAA Record (Certificate Authority Authorization)
```
Host: @
Type: CAA
Value: 0 issue "letsencrypt.org"
TTL: 3600
```

---

## Build Configuration

### Prerequisites
- Node.js v16+ or Python 3.8+
- npm/yarn package manager
- Git
- Docker (optional, for containerized builds)

### Build Steps

```bash
# 1. Clone the repository
git clone https://github.com/cawcreative/Website.git
cd Website

# 2. Install dependencies
npm install
# or
yarn install

# 3. Build for production
npm run build
# or
yarn build

# 4. Output directory
# Build artifacts will be in: ./dist or ./build
```

### Build Scripts (package.json)
```json
{
  "scripts": {
    "dev": "webpack serve --mode development",
    "build": "webpack --mode production",
    "test": "jest",
    "lint": "eslint src/",
    "deploy": "npm run build && npm run deploy:production"
  }
}
```

---

## Deployment Configuration

### Deployment Environments

#### Development
- **Domain**: dev.tinkyandmateo.com
- **Environment**: development
- **Auto-deploy**: On push to `develop` branch

#### Staging
- **Domain**: staging.tinkyandmateo.com
- **Environment**: staging
- **Auto-deploy**: On push to `staging` branch

#### Production
- **Domain**: tinkyandmateo.com
- **Environment**: production
- **Auto-deploy**: On tagged releases (v*.*.*)

### Hosting Options

#### Option 1: GitHub Pages
```yaml
- Domain: tinkyandmateo.com
- Repository: cawcreative/Website
- Branch: main (or gh-pages)
- SSL: Automatic (via GitHub)
```

#### Option 2: Netlify
```yaml
- Domain: tinkyandmateo.com
- Build Command: npm run build
- Publish Directory: dist/
- Auto-deploy: On push to main
- SSL: Automatic (via Let's Encrypt)
```

#### Option 3: Vercel
```yaml
- Domain: tinkyandmateo.com
- Framework: Next.js / React / Vue / Static
- Build Command: npm run build
- Output Directory: .next / dist / build
- SSL: Automatic
```

#### Option 4: Self-Hosted (VPS/Dedicated Server)
```yaml
- Server: [YOUR_SERVER_IP]
- SSL: Let's Encrypt (certbot)
- Web Server: Nginx / Apache
- Auto-deploy: GitHub Actions / Webhook
```

---

## CI/CD Pipeline (.github/workflows/deploy.yml)

```yaml
name: Build and Deploy

on:
  push:
    branches: [main, staging, develop]
    tags: ['v*']
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '16'
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Run linting
        run: npm run lint
      
      - name: Run tests
        run: npm run test
      
      - name: Build
        run: npm run build
      
      - name: Upload artifacts
        uses: actions/upload-artifact@v3
        with:
          name: build-artifacts
          path: dist/

  deploy-production:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main' || startsWith(github.ref, 'refs/tags/v')
    steps:
      - uses: actions/checkout@v3
      
      - name: Download artifacts
        uses: actions/download-artifact@v3
        with:
          name: build-artifacts
          path: dist/
      
      - name: Deploy to production
        run: |
          echo "Deploying to tinkyandmateo.com"
          # Add your deployment script here
          # Example: ./scripts/deploy.sh production

  deploy-staging:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/staging'
    steps:
      - uses: actions/checkout@v3
      
      - name: Download artifacts
        uses: actions/download-artifact@v3
        with:
          name: build-artifacts
          path: dist/
      
      - name: Deploy to staging
        run: |
          echo "Deploying to staging.tinkyandmateo.com"
          # Add your deployment script here
```

---

## SSL/TLS Certificate Setup

### Using Let's Encrypt with Certbot

```bash
# Install certbot
sudo apt-get install certbot python3-certbot-nginx

# Generate certificate
sudo certbot certonly --nginx -d tinkyandmateo.com -d www.tinkyandmateo.com

# Auto-renewal
sudo certbot renew --dry-run
```

### Certificate Validation Methods
- **HTTP-01**: For public domains
- **DNS-01**: For wildcard certificates
- **TLS-ALPN-01**: For port 443 validation

---

## Performance & Security Checklist

### Security
- [ ] SSL/TLS certificate installed and configured
- [ ] DNS records properly configured
- [ ] HTTPS redirect enabled
- [ ] CAA records configured
- [ ] SPF, DKIM, DMARC records set (if using email)
- [ ] Security headers configured (CSP, X-Frame-Options, etc.)

### Performance
- [ ] CDN configured (CloudFlare, Akamai, etc.)
- [ ] Caching headers optimized
- [ ] Gzip compression enabled
- [ ] Images optimized
- [ ] Critical CSS inlined
- [ ] Lazy loading implemented

### Monitoring
- [ ] Uptime monitoring enabled
- [ ] Error tracking (Sentry, LogRocket, etc.)
- [ ] Analytics configured (Google Analytics, Mixpanel, etc.)
- [ ] Log aggregation setup (ELK, Datadog, etc.)

---

## Rollback Procedure

```bash
# If deployment fails, rollback to previous version
git revert <commit-hash>
git push origin main

# Or checkout previous tag
git checkout <previous-tag>
npm run build
npm run deploy
```

---

## Support & Documentation

- **Repository**: https://github.com/cawcreative/Website
- **Issues**: https://github.com/cawcreative/Website/issues
- **Wiki**: https://github.com/cawcreative/Website/wiki

---

## Configuration Checklist

Before going live, ensure:

- [ ] Replace `[YOUR_SERVER_IP]` with actual server IP
- [ ] Configure DNS records with your registrar
- [ ] Set up SSL certificate
- [ ] Configure CI/CD pipeline
- [ ] Set up monitoring and alerting
- [ ] Test HTTPS on all subdomains
- [ ] Verify email records (if applicable)
- [ ] Test deployment pipeline end-to-end
- [ ] Document any custom deployment steps
- [ ] Set up backup and disaster recovery plan
