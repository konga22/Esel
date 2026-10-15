import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

/// 시연(mock) 계정의 비밀번호 확인용 다이제스트.
///
/// 실제 인증은 서버가 한다(DEV-05). mock은 기기 안에서만 "같은 이메일에 아무 비밀번호나
/// 넣으면 그 계정 기록이 열리던" 문제를 막으려고, 비밀번호 대신 솔트를 붙여 여러 번
/// SHA-256한 값만 보안 저장소에 둔다. 새 패키지 없이 쓰려고 SHA-256을 직접 구현했다
/// (FIPS 180-4, 테스트에 표준 벡터).
abstract final class PasswordDigest {
  static const int rounds = 2000;

  static String newSalt() {
    final random = Random.secure();
    return base64Url.encode(List.generate(16, (_) => random.nextInt(256)));
  }

  static String digest(String password, String salt) {
    final saltBytes = utf8.encode(salt);
    var value = sha256([...saltBytes, ...utf8.encode(password)]);
    for (var i = 1; i < rounds; i++) {
      value = sha256([...value, ...saltBytes]);
    }
    return base64Url.encode(value);
  }

  /// 길이가 같으면 끝까지 비교한다(앞 글자가 틀린 순간 멈추지 않음).
  static bool matches(String password, String salt, String expected) {
    final actual = digest(password, salt);
    if (actual.length != expected.length) return false;
    var diff = 0;
    for (var i = 0; i < actual.length; i++) {
      diff |= actual.codeUnitAt(i) ^ expected.codeUnitAt(i);
    }
    return diff == 0;
  }

  static const List<int> _k = [
    0x428a2f98,
    0x71374491,
    0xb5c0fbcf,
    0xe9b5dba5,
    0x3956c25b,
    0x59f111f1,
    0x923f82a4,
    0xab1c5ed5,
    0xd807aa98,
    0x12835b01,
    0x243185be,
    0x550c7dc3,
    0x72be5d74,
    0x80deb1fe,
    0x9bdc06a7,
    0xc19bf174,
    0xe49b69c1,
    0xefbe4786,
    0x0fc19dc6,
    0x240ca1cc,
    0x2de92c6f,
    0x4a7484aa,
    0x5cb0a9dc,
    0x76f988da,
    0x983e5152,
    0xa831c66d,
    0xb00327c8,
    0xbf597fc7,
    0xc6e00bf3,
    0xd5a79147,
    0x06ca6351,
    0x14292967,
    0x27b70a85,
    0x2e1b2138,
    0x4d2c6dfc,
    0x53380d13,
    0x650a7354,
    0x766a0abb,
    0x81c2c92e,
    0x92722c85,
    0xa2bfe8a1,
    0xa81a664b,
    0xc24b8b70,
    0xc76c51a3,
    0xd192e819,
    0xd6990624,
    0xf40e3585,
    0x106aa070,
    0x19a4c116,
    0x1e376c08,
    0x2748774c,
    0x34b0bcb5,
    0x391c0cb3,
    0x4ed8aa4a,
    0x5b9cca4f,
    0x682e6ff3,
    0x748f82ee,
    0x78a5636f,
    0x84c87814,
    0x8cc70208,
    0x90befffa,
    0xa4506ceb,
    0xbef9a3f7,
    0xc67178f2,
  ];

  static int _rotr(int x, int n) => ((x >>> n) | (x << (32 - n))) & 0xFFFFFFFF;

  /// SHA-256 한 번.
  static Uint8List sha256(List<int> message) {
    final length = message.length;
    final padded = Uint8List(((length + 9 + 63) ~/ 64) * 64)
      ..setRange(0, length, message);
    padded[length] = 0x80;
    final bits = ByteData.view(padded.buffer);
    // 메시지 길이(비트)를 마지막 8바이트에. 2^32비트 넘는 입력은 받지 않는다.
    bits.setUint32(padded.length - 4, (length * 8) & 0xFFFFFFFF);
    bits.setUint32(padded.length - 8, (length * 8) ~/ 0x100000000);

    final h = [
      0x6a09e667,
      0xbb67ae85,
      0x3c6ef372,
      0xa54ff53a,
      0x510e527f,
      0x9b05688c,
      0x1f83d9ab,
      0x5be0cd19,
    ];
    final w = List<int>.filled(64, 0);
    for (var chunk = 0; chunk < padded.length; chunk += 64) {
      for (var i = 0; i < 16; i++) {
        w[i] = bits.getUint32(chunk + i * 4);
      }
      for (var i = 16; i < 64; i++) {
        final s0 =
            _rotr(w[i - 15], 7) ^ _rotr(w[i - 15], 18) ^ (w[i - 15] >>> 3);
        final s1 =
            _rotr(w[i - 2], 17) ^ _rotr(w[i - 2], 19) ^ (w[i - 2] >>> 10);
        w[i] = (w[i - 16] + s0 + w[i - 7] + s1) & 0xFFFFFFFF;
      }
      var a = h[0], b = h[1], c = h[2], d = h[3];
      var e = h[4], f = h[5], g = h[6], hh = h[7];
      for (var i = 0; i < 64; i++) {
        final s1 = _rotr(e, 6) ^ _rotr(e, 11) ^ _rotr(e, 25);
        final ch = (e & f) ^ ((~e & 0xFFFFFFFF) & g);
        final t1 = (hh + s1 + ch + _k[i] + w[i]) & 0xFFFFFFFF;
        final s0 = _rotr(a, 2) ^ _rotr(a, 13) ^ _rotr(a, 22);
        final maj = (a & b) ^ (a & c) ^ (b & c);
        final t2 = (s0 + maj) & 0xFFFFFFFF;
        hh = g;
        g = f;
        f = e;
        e = (d + t1) & 0xFFFFFFFF;
        d = c;
        c = b;
        b = a;
        a = (t1 + t2) & 0xFFFFFFFF;
      }
      h[0] = (h[0] + a) & 0xFFFFFFFF;
      h[1] = (h[1] + b) & 0xFFFFFFFF;
      h[2] = (h[2] + c) & 0xFFFFFFFF;
      h[3] = (h[3] + d) & 0xFFFFFFFF;
      h[4] = (h[4] + e) & 0xFFFFFFFF;
      h[5] = (h[5] + f) & 0xFFFFFFFF;
      h[6] = (h[6] + g) & 0xFFFFFFFF;
      h[7] = (h[7] + hh) & 0xFFFFFFFF;
    }
    final out = ByteData(32);
    for (var i = 0; i < 8; i++) {
      out.setUint32(i * 4, h[i]);
    }
    return out.buffer.asUint8List();
  }
}
