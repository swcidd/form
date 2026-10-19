import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

/// Derives and checks the verifier kept for an account's password.
///
/// An account on this device never stores the password itself. What goes in the
/// store is a PBKDF2-HMAC-SHA256 verifier over a random per-account salt, so a
/// copy of the database file does not hand over a password the person may have
/// reused somewhere that matters.
///
/// What this does *not* protect is the training data: it sits in the same file,
/// in the clear, and a rooted device can read it. This protects the secret, not
/// the account. Anything stronger means the password never reaching the device,
/// which is a server's job and where [AuthRepository] is designed to be
/// replaced.
///
/// The cost is stored inside the verifier string rather than assumed, so a
/// verifier written with an older count still verifies with its own count after
/// the default is raised.
///
/// The work is deliberately slow. It runs once per sign-in, off the frame, and
/// that is the point: a few hundred milliseconds of deliberate work is what
/// makes guessing a password from a stolen file expensive.
class PasswordHasher {
  const PasswordHasher({this.iterations = defaultIterations});

  /// Iteration count for a newly written verifier.
  ///
  /// Chosen by measuring on the slowest device to hand: it aims for a sign-in
  /// that stays under a second on a low-end phone while costing an attacker
  /// the same per guess. See `docs/AUTH.md` for the measurement.
  static const int defaultIterations = 12000;

  /// Bytes of salt per verifier. 16 is the usual recommendation and short
  /// enough that storing it beside the hash costs nothing.
  static const int saltBytes = 16;

  /// Bytes of derived key. One SHA-256 block, which is the standard length.
  static const int keyBytes = 32;

  /// Marks the scheme, so a verifier written by a different algorithm is
  /// rejected rather than misread as this one.
  static const String scheme = 'pbkdf2-sha256';

  final int iterations;

  /// A verifier for [password], with a fresh random salt.
  ///
  /// Returns `scheme$iterations$salt$key`, all base64 after the second field,
  /// which is what lets [verify] work out how to check it without being told.
  String hash(String password) {
    final salt = _salt();
    final key = derive(password, salt: salt, iterations: iterations);
    return [
      scheme,
      '$iterations',
      base64.encode(salt),
      base64.encode(key),
    ].join(r'$');
  }

  /// Whether [password] is the one [encoded] was written for.
  ///
  /// Answers false for anything it cannot read - another scheme, a truncated
  /// string, a field that is not base64 - because a verifier that cannot be
  /// understood is not a match, and throwing here would turn a corrupt row into
  /// a crash on the sign-in screen.
  bool verify(String password, String encoded) {
    final parsed = _parse(encoded);
    if (parsed == null) return false;

    final key = derive(
      password,
      salt: parsed.salt,
      iterations: parsed.iterations,
    );
    return _constantTimeEquals(key, parsed.key);
  }

  /// The derived key for [password] and [salt], as RFC 2898 defines it.
  @visibleForTesting
  static Uint8List derive(
    String password, {
    required List<int> salt,
    required int iterations,
  }) {
    if (iterations < 1) {
      throw ArgumentError.value(iterations, 'iterations', 'must be at least 1');
    }

    final prf = Hmac(sha256, utf8.encode(password));
    final hashLength = sha256.convert(const []).bytes.length;
    final blocks = (keyBytes + hashLength - 1) ~/ hashLength;
    final derived = Uint8List(blocks * hashLength);

    for (var block = 1; block <= blocks; block++) {
      // U1 = PRF(password, salt || INT_32_BE(block))
      final seed = Uint8List(salt.length + 4)
        ..setRange(0, salt.length, salt)
        ..setRange(salt.length, salt.length + 4, _bigEndian(block));
      var u = Uint8List.fromList(prf.convert(seed).bytes);
      final accumulator = Uint8List.fromList(u);

      // U2..Un folded in by XOR: the part that makes each iteration cost the
      // attacker as much as it costs this device.
      for (var round = 1; round < iterations; round++) {
        u = Uint8List.fromList(prf.convert(u).bytes);
        for (var i = 0; i < accumulator.length; i++) {
          accumulator[i] ^= u[i];
        }
      }

      derived.setRange(
        (block - 1) * hashLength,
        block * hashLength,
        accumulator,
      );
    }

    return derived.sublist(0, keyBytes);
  }

  static _Verifier? _parse(String encoded) {
    final parts = encoded.split(r'$');
    if (parts.length != 4 || parts[0] != scheme) return null;

    final iterations = int.tryParse(parts[1]);
    if (iterations == null || iterations < 1) return null;

    try {
      final salt = base64.decode(parts[2]);
      final key = base64.decode(parts[3]);
      if (salt.isEmpty || key.isEmpty) return null;
      return _Verifier(iterations: iterations, salt: salt, key: key);
    } on FormatException {
      // Base64 that is not base64: a row that has been damaged rather than a
      // password that is wrong, and either way not a match.
      return null;
    }
  }

  /// A match is decided without short-circuiting, so how long the answer took
  /// says nothing about how much of the key was right.
  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var difference = 0;
    for (var i = 0; i < a.length; i++) {
      difference |= a[i] ^ b[i];
    }
    return difference == 0;
  }

  static List<int> _bigEndian(int value) => [
    value >> 24 & 0xff,
    value >> 16 & 0xff,
    value >> 8 & 0xff,
    value & 0xff,
  ];

  // Random.secure(): a salt from a predictable generator would let the same
  // password derive the same key on every device, which is the thing the salt
  // exists to prevent.
  static final Random _random = Random.secure();

  static Uint8List _salt() =>
      Uint8List.fromList(List.generate(saltBytes, (_) => _random.nextInt(256)));
}

/// The three fields a stored verifier carries.
class _Verifier {
  const _Verifier({
    required this.iterations,
    required this.salt,
    required this.key,
  });

  final int iterations;
  final List<int> salt;
  final List<int> key;
}
