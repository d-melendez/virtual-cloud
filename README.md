## OpenStack Horizon in Docker (DigitalOcean friendly)

This image installs OpenStack Horizon using the Ubuntu Cloud Archive and runs it under Apache with mod_wsgi. It is designed to run easily on a DigitalOcean Droplet.

### Build the image

```bash
docker build -t horizon:latest .
```

You can choose a specific OpenStack release from the Ubuntu Cloud Archive by passing `--build-arg UCA_SERIES=<series>`. Examples: `caracal` (2024.1), `bobcat` (2023.2).

```bash
docker build --build-arg UCA_SERIES=caracal -t horizon:caracal .
```

### Environment variables

- `HORIZON_ALLOWED_HOSTS` (default `*`): comma-free hostname, or `*` for any. Example: `dashboard.example.com`.
- `HORIZON_TIME_ZONE` (default `UTC`)
- `HORIZON_WEBROOT` (default `/`)
- `HORIZON_DEBUG` (default `false`): `true` or `false`
- `HORIZON_KEYSTONE_URL` (no default): If set, overrides Keystone endpoint, e.g. `http://<keystone-host>:5000/v3`

### Run on a DigitalOcean Droplet

1. Open firewall for HTTP (port 80) on the Droplet.

2. Start the container with port forwarding and your Keystone URL:

```bash
docker run -d \
  --name horizon \
  -p 80:80 \
  -e HORIZON_ALLOWED_HOSTS="*" \
  -e HORIZON_TIME_ZONE="UTC" \
  -e HORIZON_DEBUG=false \
  -e HORIZON_WEBROOT="/" \
  -e HORIZON_KEYSTONE_URL="http://<keystone-host-or-ip>:5000/v3" \
  horizon:latest
```

3. Access the dashboard at: `http://<droplet-public-ip>/`

If you have a domain, point DNS A record to the droplet IP, then set `HORIZON_ALLOWED_HOSTS` to that hostname for stricter security.

### Notes

- The container uses a simple healthcheck hitting `http://localhost/`.
- For TLS, put a reverse proxy (e.g., Nginx or Caddy) in front, or terminate TLS on the droplet and proxy to the container.
- To persist customizations, mount a volume at `/etc/openstack-dashboard` and edit `local_settings.py`.
