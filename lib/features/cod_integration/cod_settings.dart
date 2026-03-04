import 'package:flutter/material.dart';
import 'cod_repository.dart';

class CodSettingsWidget extends StatelessWidget {
  const CodSettingsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () async {
            await CodRepository.connectCod();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('CoD Account verbunden!')),
            );
          },
          child: const Text('Mit CoD verbinden'),
        ),
        ElevatedButton(
          onPressed: () async {
            await CodRepository.disconnectCod();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('CoD Account getrennt!')),
            );
          },
          child: const Text('CoD Verbindung trennen'),
        ),
      ],
    );
  }
}
