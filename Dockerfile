FROM python:3.11-slim

RUN apt-get update \
  && apt-get -y install curl \
  && curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | bash \
  && apt-get -y install speedtest

WORKDIR /app

COPY . /app

RUN pip install --trusted-host pypi.python.org -r requirements.txt

CMD ["python", "speedtest.py"]
