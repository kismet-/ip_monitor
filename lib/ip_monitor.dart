import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:http/http.dart' as http;

const String apiKey = 'XXXXYYYYYZZZ'; // Replace with your API key
const String apiUrl = 'https://api.dreamhost.com/';
const String domain = 'executed.io'; // Replace with your domain

String? lastIP;

Future<void> main() async {
  Future<String> getCurrentIP() async {
    final response = await http.get(Uri.parse('https://icanhazip.com'));

    if (response.statusCode == 200) {
      return response.body.trim();
    } else {
      throw Exception('Failed to get IP address');
    }
  }

  Future<List<Map<String, dynamic>>> listDnsRecords() async {
    final response = await http.get(
      Uri.parse(
        '$apiUrl?'
        'key=$apiKey&'
        'cmd=dns-list_records&'
        'format=json',
      ),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data['result'] == 'success') {
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception('Failed to list DNS records: ${data['data']}');
      }
    } else {
      throw Exception('Failed to list DNS records');
    }
  }

  Map<String, dynamic>? findTxtRecord(List<Map<String, dynamic>> records) {
    return records.firstWhereOrNull(
      (record) =>
          record['record'] == domain &&
          record['type'] == 'TXT' &&
          record['comment'] == 'ip_monitor',
    );
  }

  Future<void> removeDnsRecord(String record, String type, String value) async {
    final response = await http.get(
      Uri.parse(
        '$apiUrl?'
        'key=$apiKey&'
        'cmd=dns-remove_record&'
        'record=$record&'
        'type=$type&'
        'value=$value&'
        'format=json',
      ),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data['result'] == 'success') {
        print('DNS record removed successfully');
      } else {
        print('Failed to remove DNS record: ${data['data']}');
      }
    } else {
      throw Exception('Failed to remove DNS record');
    }
  }

  Future<void> createTxtRecord(String ip) async {
    final String record = domain;

    final response = await http.get(
      Uri.parse(
        '$apiUrl?'
        'key=$apiKey&'
        'cmd=dns-add_record&'
        'record=$record&'
        'type=TXT&'
        'value=$ip&'
        'comment=ip_monitor&'
        'format=json',
      ),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data['result'] == 'success') {
        print('TXT record created successfully');
      } else {
        print('Failed to create TXT record: ${data['data']}');
      }
    } else {
      throw Exception('Failed to create TXT record');
    }
  }

  // Initial run to synchronize the IP
  try {
    lastIP = await getCurrentIP();
    final initialDnsRecords = await listDnsRecords();
    final initialExistingRecord = findTxtRecord(initialDnsRecords);

    if (initialExistingRecord == null ||
        initialExistingRecord['value'] != lastIP) {
      if (initialExistingRecord != null) {
        await removeDnsRecord(initialExistingRecord['record'],
            initialExistingRecord['type'], initialExistingRecord['value']);
      }
      await createTxtRecord(lastIP!);
    }
  } catch (e) {
    print('Error on initial run: $e');
  }

  while (true) {
    try {
      final currentIP = await getCurrentIP();

      if (lastIP == null) {
        lastIP = currentIP;
      } else if (lastIP != currentIP) {
        print('IP changed: $currentIP');
        final dnsRecords = await listDnsRecords();

        final existingRecord = findTxtRecord(dnsRecords);

        if (existingRecord != null && existingRecord['value'] != currentIP) {
          await removeDnsRecord(existingRecord['record'],
              existingRecord['type'], existingRecord['value']);
          await createTxtRecord(currentIP);
        } else if (existingRecord == null) {
          await createTxtRecord(currentIP);
        }

        lastIP = currentIP;
      }
    } catch (e) {
      print('Error: $e');
    }
    await Future.delayed(Duration(minutes: 5)); // Wait for 5 minutes
  }
}
