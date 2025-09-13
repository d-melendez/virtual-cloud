## OpenStack Horizon in Docker (zero-config)

This image installs OpenStack Horizon and runs it under Apache with mod_wsgi. It ships with safe defaults (in-process cache, `ALLOWED_HOSTS=['*']`, `WEBROOT='/'`). No configuration is required.

### Build

```bash
docker build -t horizon:latest .
```

### Run

```bash
docker run -d \
  --name horizon \
  -p 80:80 \
  horizon:latest
```

Open: `http://<droplet-public-ip>/`

Notes:

- For HTTPS, put a reverse proxy (nginx/caddy) in front.
- To customize in the future, mount your own `/etc/openstack-dashboard/local_settings.py`.
