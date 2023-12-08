# FROM python:3.11-slim
# RUN apt-get update \
#   && apt-get -y install curl \
#   && curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | bash \
#   && apt-get -y install speedtest
# WORKDIR /app
# COPY . /app
# RUN pip install --trusted-host pypi.python.org -r requirements.txt
# CMD ["python", "speedtest.py"]

# https://github.com/GoogleContainerTools/distroless/blob/main/examples/python3-requirements/Dockerfile

FROM debian:11-slim AS build
RUN apt-get update \
  && apt-get install --yes curl \
  && curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | bash \
  && apt-get install --yes speedtest \
  && apt-get install --no-install-suggests --no-install-recommends --yes python3-venv gcc libpython3-dev \
  && python3 -m venv /venv \
  && /venv/bin/pip install --upgrade pip setuptools wheel

# Build the virtualenv as a separate step: Only re-execute this step when requirements.txt changes
FROM build AS build-venv
COPY requirements.txt /requirements.txt
RUN /venv/bin/pip install --disable-pip-version-check -r /requirements.txt

# Copy the virtualenv into a distroless image
FROM gcr.io/distroless/python3-debian11
COPY --from=build /usr/bin/speedtest /usr/bin/speedtest
COPY --from=build-venv /venv /venv
COPY . /app
WORKDIR /app
ENTRYPOINT ["/venv/bin/python3", "speedtest.py"]