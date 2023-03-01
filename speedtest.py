import json
import logging
import os
import subprocess
import sys
import time

import dotenv
import requests

dotenv.load_dotenv()

logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        # logging.FileHandler('speedtest.log'),
        logging.StreamHandler(sys.stdout)
    ]
)


def fetch_speedtest():
    logging.debug('Speedtest started...')
    output_raw = subprocess.run(
        ['speedtest', '--accept-license', '--format', 'json'],
        stdout=subprocess.PIPE,
        check=False
    )
    logging.debug('Speedtest completed')
    output = output_raw.stdout.decode('utf-8')
    full_stats = json.loads(output)
    return full_stats


def extract_download_upload(stats):
    """Expects bytes, returns MB"""
    download = __convert(stats.get('download').get('bytes', 0))
    upload = __convert(stats.get('upload').get('bytes', 0))
    return [download, upload]


def __convert(raw_bytes):
    return int(raw_bytes / 1000000)


def send_to_ha(download, upload):
    requests.post(
        os.getenv('HA_WEBHOOK', ''),
        json={'download': download, 'upload': upload},
        timeout=10
    )


def poll_speedtest():
    stats = fetch_speedtest()
    download, upload = extract_download_upload(stats)
    logging.debug('download: %s, upload: %s', download, upload)
    send_to_ha(download, upload)


if __name__ == '__main__':
    while True:
        try:
            poll_speedtest()
        except Exception as error:
            logging.error(error)
            logging.error('CRASHED!!!')
        finally:
            time.sleep(900)
