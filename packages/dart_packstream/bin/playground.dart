import 'package:dart_packstream/src/ps_data_type.dart';

void main() {
  final float = PsFloat(1.23);
  print(
    float.toBytes().map((e) => e.toRadixString(16).padLeft(2, '0')).join(' '),
  );
}
