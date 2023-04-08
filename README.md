# IP Monitor

IP Monitor is a simple Dart program that monitors the system's 
IP address and updates a DNS TXT record using the DreamHost API 
when the IP changes. 

An example .plist file is included to run this program as a macos daemon. 

## Features

- Monitors the system's IP address using the [icanhazip.com](https://icanhazip.com/) API
- Updates a DNS TXT record with the 'ip_monitor' comment when the IP changes
- Uses the DreamHost API to manage the DNS records
- Runs the script every 5 minutes to check for IP changes

## Prerequisites

- Dart SDK installed on your system

To build the project:

```dart compile exe bin/ip_monitor.dart -o ~/Downloads```