#!/usr/bin/env dart

import '../example/basic_example.dart' as basic_example;

/// Entry point for running the Ecocash SDK example
void main(List<String> arguments) async {
  print('Starting Ecocash Dart SDK Example...\n');

  await basic_example.main();

  print('\nFor more examples, check out:');
  print('- example/basic_example.dart - Basic usage examples');
  print('- example/advanced_example.dart - Advanced features');
  print('- example/main.dart - Legacy example');
  print('- test/ - Unit tests');
  print('- README.md - Full documentation');
}
