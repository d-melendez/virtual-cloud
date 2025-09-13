sudo apt update -y && sudo apt install docker.io -y
git clone https://github.com/sleepypower/virtual-cloud.git
cd virtual-cloud

sudo docker build -t horizon:latest .

sudo docker run -d \
  --name horizon \
  -p 80:80 \
  -e HORIZON_ALLOWED_HOSTS="*" \
  -e HORIZON_TIME_ZONE="UTC" \
  -e HORIZON_DEBUG=false \
  -e HORIZON_WEBROOT="/" \
  -e HORIZON_KEYSTONE_URL="http://<keystone-host-or-ip>:5000/v3" \
  horizon:latest