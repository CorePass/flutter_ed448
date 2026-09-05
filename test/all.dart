import 'test_blake3.dart' as test_blake3;
import 'test_ed448.dart' as test_ed448;
import 'test_jwt.dart' as test_jwt;

main() {
  test_blake3.test();
  test_ed448.test();
  test_jwt.test();
}
