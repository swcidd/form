import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:plus_one/auth/password_hasher.dart';

void main() {
  // A cheap count for the tests that are about behaviour rather than cost:
  // the derivation is deliberately slow, and 6000 of these assertions do not
  // need to pay for it.
  const hasher = PasswordHasher(iterations: 200);

  group('verifiers', () {
    test('a verifier is not the password', () {
      const password = 'bench-press-100';
      final encoded = hasher.hash(password);

      expect(encoded, isNot(contains(password)));
      // Scheme, cost, salt, key - so a verifier can be checked without being
      // told how it was written.
      expect(encoded.split(r'$'), hasLength(4));
      expect(encoded, startsWith('${PasswordHasher.scheme}\$200\$'));
    });

    test('the right password matches the verifier', () {
      final encoded = const PasswordHasher().hash('bench-press-100');

      expect(const PasswordHasher().verify('bench-press-100', encoded), isTrue);
    });

    test('the wrong password does not', () {
      final encoded = hasher.hash('bench-press-100');

      expect(hasher.verify('bench-press-101', encoded), isFalse);
      expect(hasher.verify('', encoded), isFalse);
      expect(hasher.verify('BENCH-PRESS-100', encoded), isFalse);
      // Off by a trailing space is still off: trimming belongs to the screen
      // that reads the field, not to the check.
      expect(hasher.verify('bench-press-100 ', encoded), isFalse);
    });

    test('the same password twice gets two verifiers', () {
      // A shared salt would let one stolen file confirm that two accounts with
      // the same password share it.
      final first = hasher.hash('bench-press-100');
      final second = hasher.hash('bench-press-100');

      expect(first, isNot(second));
      expect(hasher.verify('bench-press-100', first), isTrue);
      expect(hasher.verify('bench-press-100', second), isTrue);
    });

    test('a verifier carries its own cost', () {
      final cheap = const PasswordHasher(iterations: 500).hash('hunter2');

      // Checking it with a hasher that would write a different cost has to
      // still work, because the stored verifier is the authority on how it was
      // written: otherwise raising the default would lock every account out.
      expect(
        const PasswordHasher(iterations: 99).verify('hunter2', cheap),
        isTrue,
      );
    });

    test('a verifier that cannot be read is not a match', () {
      // A damaged row has to answer "no" rather than throw: sign-in is the one
      // place a crash costs the whole app.
      for (final broken in [
        '',
        'not a verifier',
        r'pbkdf2-sha256$200$c2FsdA', // truncated
        r'pbkdf2-sha256$200$c2FsdA$', // no key
        r'pbkdf2-sha256$abc$c2FsdA$a2V5', // cost is not a number
        r'pbkdf2-sha256$0$c2FsdA$a2V5', // cost below one
        r'pbkdf2-sha256$200$!!!$a2V5', // salt is not base64
        r'pbkdf2-sha256$200$c2FsdA$!!!', // key is not base64
        r'bcrypt$200$c2FsdA$a2V5', // another scheme
      ]) {
        expect(
          hasher.verify('hunter2', broken),
          isFalse,
          reason: 'should reject "$broken"',
        );
      }
    });

    test('a verifier for another password is not accepted after tampering', () {
      final encoded = hasher.hash('hunter2');
      final parts = encoded.split(r'$');
      // Swap the key for one derived from a different password.
      final forged = [
        parts[0],
        parts[1],
        parts[2],
        hasher.hash('something-else').split(r'$').last,
      ].join(r'$');

      expect(hasher.verify('hunter2', forged), isFalse);
    });
  });

  group('the derivation', () {
    test('matches RFC 2898 test vector 2', () {
      // PBKDF2-HMAC-SHA256: P="password", S="salt", c=1, dkLen=32. Pinning one
      // published vector is what says this is PBKDF2 and not merely something
      // that happens to be slow and repeatable.
      final key = PasswordHasher.derive(
        'password',
        salt: utf8.encode('salt'),
        iterations: 1,
      );

      expect(
        key,
        equals([
          0x12, 0x0f, 0xb6, 0xcf, 0xfc, 0xf8, 0xb3, 0x2c, //
          0x43, 0xe7, 0x22, 0x52, 0x56, 0xc4, 0xf8, 0x37,
          0xa8, 0x65, 0x48, 0xc9, 0x2c, 0xcc, 0x35, 0x48,
          0x08, 0x05, 0x98, 0x7c, 0xb7, 0x0b, 0xe1, 0x7b,
        ]),
      );
    });

    test('matches RFC 2898 test vector with two iterations', () {
      final key = PasswordHasher.derive(
        'password',
        salt: utf8.encode('salt'),
        iterations: 2,
      );

      expect(
        key,
        equals([
          0xae, 0x4d, 0x0c, 0x95, 0xaf, 0x6b, 0x46, 0xd3, //
          0x2d, 0x0a, 0xdf, 0xf9, 0x28, 0xf0, 0x6d, 0xd0,
          0x2a, 0x30, 0x3f, 0x8e, 0xf3, 0xc2, 0x51, 0xdf,
          0xd6, 0xe2, 0xd8, 0x5a, 0x95, 0x47, 0x4c, 0x43,
        ]),
      );
    });

    test('zero iterations is refused rather than silently weak', () {
      expect(
        () => PasswordHasher.derive(
          'password',
          salt: utf8.encode('salt'),
          iterations: 0,
        ),
        throwsArgumentError,
      );
    });
  });
}
