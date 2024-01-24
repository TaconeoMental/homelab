#!/usr/bin/env python3

import argparse
import time
import os
import yaml
import pathlib
import jinja2
import sys

ZONE_TEMPLATE = """\
$ORIGIN {{ zone.origin }}
$TTL {{ zone.ttl }}
@                    IN  SOA  {{ zone.soa.ns }} {{ zone.soa.user }} (
                         {{ zone.soa.serial }} ; serial number of this zone file
                         1d         ; slave refresh (1 day)
                         2h         ; slave retry time in case of a problem (2 hours)
                         4w         ; slave expiration time (4 weeks)
                         1h         ; maximum caching time in case of failed lookups (1 hour)
                         )

{% for record in zone.records -%}
{{ record }}
{% endfor %}
"""

NAMED_TEMPLATE = """\
{% for zone in zones -%}
zone "{{ zone }}" {
    type master;
    file "/etc/bind/db.{{ zone }}";
};
{% endfor %}
"""

def format_record(record):
    record_type = record["type"]
    host = record.get("host", "@")
    value = record["value"]

    if record_type == "TXT":
        value = '"{}"'.format(value)

    if record_type == "MX":
        value = "{} {}".format(record["priority"], value)

    values = (host, record_type, value)
    return '%-20s IN  %-5s %s' % values

def get_zones(zone_dir):
    for file in os.scandir(zone_dir):
        with open(file, "r") as f:
            json_conf = yaml.safe_load(f.read())

        zone = {
            "origin": json_conf["origin"],
            "ttl": json_conf["ttl"],
            "soa": json_conf["soa"] | {"serial": str(int(time.time()))},
            "records": [format_record(record) for record in json_conf["records"]]
        }
        yield json_conf["origin"].rstrip("."), zone

def main():
    argparser = argparse.ArgumentParser()
    argparser.add_argument("-c", "--config-dir", required=True)
    argparser.add_argument("-o", "--output-dir", required=True)
    args = argparser.parse_args()

    zone_template = jinja2.Template(ZONE_TEMPLATE)
    named_template = jinja2.Template(NAMED_TEMPLATE)

    if not os.path.isdir(args.config_dir):
        sys.exit(f"'{args.config_dir}' does not exist")

    zones = list()

    for zone, zone_data in get_zones(args.config_dir):
        zones.append(zone)
        with open(pathlib.Path(args.output_dir) / f"db.{zone}", "w") as zf:
            content = zone_template.render(zone=zone_data)
            zf.write(content)

    with open(pathlib.Path(args.output_dir) / f"named.conf.zones", "w") as cf:
        content = named_template.render(zones=zones)
        cf.write(content)

if __name__ == "__main__":
    main()
