Demonstration using [Ookla's speedtest-cli](https://www.speedtest.net/apps/cli) and [Home Assistant](https://www.home-assistant.io/) to monitor home internet speeds.

- Runs a speed test every 15 minutes.
- Reports the download/upload speeds to a Home Assistant webhook.
- Home Assistant automation sends a notification if the download speed is below a threshold for 20 minutes.

_Disclaimer, my Python is amateur, and I'm in my early days with Home Assistant._

## Home Assistant

Use a [`template`](https://www.home-assistant.io/integrations/template) (triggered by a [webhook](https://www.home-assistant.io/integrations/template/#trigger-based-sensor-and-binary-sensor-storing-webhook-information)) to store the download and upload speeds as entities.

<details><summary>configuration.yaml</summary>

```yml
template:
  - trigger:
      - platform: webhook
        webhook_id: my-super-secret-webhook-id
    sensor:
      - name: "Webhook Speedtest Download"
        state: "{{ trigger.json.download }}"
        unit_of_measurement: MB
      - name: "Webhook Speedtest Upload"
        state: "{{ trigger.json.upload }}"
        unit_of_measurement: MB
```

The above will generate two entities: `sensor.webhook_speedtest_download` and `sensor.webhook_speedtest_upload`.

</details>

<details><summary>curl example</summary>

```sh
curl --header "Content-Type: application/json" \
  --request POST \
  --data '{"download": 98, "upload": 22}' \
  http://homeassistant.local:8123/api/webhook/my-super-secret-webhook-id
```

</details>

Add a [Entities card](https://www.home-assistant.io/dashboards/entities/) to the dashboard showing the current download and upload speeds, as well as a chart showing download speeds over the last 24 hours.

<details><summary>"Entities" card</summary>

```yml
cards:
  - type: entities
    entities:
      - entity: sensor.webhook_speedtest_download
        name: Download
        icon: mdi:download
        secondary_info: last-changed
      - entity: sensor.webhook_speedtest_upload
        name: Upload
        icon: mdi:upload
        secondary_info: last-changed
    footer:
      type: graph
      entity: sensor.webhook_speedtest_download
      hours_to_show: 24
      detail: 2
    title: AcmeInternet
    state_color: false
```

</details>

Trigger an automation that sends a [notification](https://www.home-assistant.io/integrations/notify/) if the download speed is less than 50MB for 20 minutes.

<details><summary>Automation YAML</summary>

```yaml
alias: Slow Internet Notification
description: ""
trigger:
  - platform: numeric_state
    entity_id: sensor.webhook_speedtest_download
    below: "50"
    for:
      hours: 0
      minutes: 20
      seconds: 0
condition: []
action:
  - service: notify.mobile_app_phone1
    data:
      message: Internet is slow!
mode: restart
```

</details>

## Podman

Copy `.env.dist` to `.env`, and update `HA_WEBHOOK`.

Use Podman (or Docker) to run the instructions in the `Dockerfile` and generate an image.

<details><summary>Build Docker image and start container</summary>

```bash
podman build --tag speedtest-app -f ./Dockerfile
podman run -d --name speedtest-app speedtest-app
```

</details>

Podman does not autostart containers on boot. Follow [this guide](https://linuxhandbook.com/autostart-podman-containers/) for setting up a `systemd` service.
