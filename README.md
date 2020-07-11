# Django in Ubuntu, Nginx and Gunicorn

## Setup

In `$HOME` git clone this repo and cd into it.

```bash
sh setup.sh
```

### Development server

Open port `8000`. We'll remove this rule later.

```bash
sh setup.sh allowport "8000"
```

Run server:

- ```bash
  python manage.py runserver 0.0.0.0:8000
  ```

  Test _gunicorn_ to serve the app.

- ```bash
  gunicorn --bind 0.0.0.0:8000 dj.wsgi
  ```

## Gunicorn

Create a _systemd socket file_ for Gunicorn with sudo privileges.

`/etc/systemd/system/gunicorn.socket`

```sh
[Unit]
Description=gunicorn socket

[Socket]
ListenStream=/run/gunicorn.sock

[Install]
WantedBy=sockets.target
```

Create a _systemd service file_.

`/etc/systemd/system/gunicorn.service`

```sh
[Unit]
Description=gunicorn daemon
Requires=gunicorn.socket
After=network.target

[Service]
User=root
Group=www-data
WorkingDirectory=/home/root/django
ExecStart=/home/root/django/venv/bin/gunicorn \
          --access-logfile - \
          --workers 3 \
          --bind unix:/run/gunicorn.sock \
          dj.wsgi:application

[Install]
WantedBy=multi-user.target
```

Start and enable the _gunicorn_ socket.

```bash
sudo systemctl start gunicorn.socket
sudo systemctl enable gunicorn.socket
```

### Testing Socket

```bash
# Check status
sudo systemctl status gunicorn
```

If you just started the socket, this will read _inactive_.

Let's test socket activation.

```bash
curl --unix-socket /run/gunicorn.sock localhost
```

Recheck status.

Check logs if something's not right.

```bash
sudo journalctl -u gunicorn
```

Whenever you make changes to _gunicorn_ socket or service files, reload the daemon to reread the socket or service definition(s) and restart the Gunicorn process.

```bash
sudo systemctl daemon-reload
sudo systemctl restart gunicorn.socket gunicorn.service
```

Whenever you make changes to the app, restart the _gunicorn_ process to pick up the changes.

```bash
sudo systemctl restart gunicorn
```

## Nginx to proxy pass to gunicorn

Create and open a new server block in Nginx’s `sites-available` directory.

`/etc/nginx/sites-available/django`

```sh
server {
    listen 80;
    server_name {{server_domain_or_IP}};

    location = /favicon.ico { access_log off; log_not_found off; }
    location /static/ {
        root /home/root/django;
    }

    location / {
        include proxy_params;
        proxy_pass http://unix:/run/gunicorn.sock;
    }
}
```

Enable the file by linking it to the `sites-enabled` directory.

```bash
sudo ln -s /etc/nginx/sites-available/django /etc/nginx/sites-enabled
```

Whenever you make changes to the Nginx server block configuration.

```bash
# Test Nginx configuration for syntax errors
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx
```

Nginx traffic.

```bash
# Remove the rule to open port 8000
sudo ufw delete allow 8000

# Open firewall to normal traffic on port 80
sudo ufw allow 'Nginx Full'
```
