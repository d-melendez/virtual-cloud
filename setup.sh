sudo apt update -y && sudo apt install docker.io -y
#git clone https://github.com/sleepypower/virtual-cloud.git
#cd virtual-cloud

docker build -t horizon:latest .
docker run -d \
  --name horizon \
  -p 80:80 \
  horizon:latest