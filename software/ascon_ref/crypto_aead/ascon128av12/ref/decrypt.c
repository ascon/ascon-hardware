#include "api.h"
#include "ascon.h"
#include "crypto_aead.h"
#include "permutations.h"
#include "printstate.h"
#include "word.h"

int crypto_aead_decrypt(unsigned char* m, unsigned long long* mlen,
                        unsigned char* nsec, const unsigned char* c,
                        unsigned long long clen, const unsigned char* ad,
                        unsigned long long adlen, const unsigned char* npub,
                        const unsigned char* k) {
  (void)nsec;

  if (clen < CRYPTO_ABYTES) return -1;

  /* set plaintext size */
  *mlen = clen - CRYPTO_ABYTES;

  /* load key and nonce */
  const uint64_t K0 = LOADBYTES(k, 8);
  const uint64_t K1 = LOADBYTES(k + 8, 8);
  const uint64_t N0 = LOADBYTES(npub, 8);
  const uint64_t N1 = LOADBYTES(npub + 8, 8);

  /* initialize */
  state_t s;
  s.x0 = ASCON_128A_IV;
  s.x1 = K0;
  s.x2 = K1;
  s.x3 = N0;
  s.x4 = N1;
  P12(&s);
  s.x3 ^= K0;
  s.x4 ^= K1;
  printstate("initialization", &s);

  if (adlen) {
    /* full associated data blocks */
    while (adlen >= ASCON_128A_RATE) {
      s.x0 ^= LOADBYTES(ad, 8);
      s.x1 ^= LOADBYTES(ad + 8, 8);
      P8(&s);
      ad += ASCON_128A_RATE;
      adlen -= ASCON_128A_RATE;
    }
    /* final associated data block */
    if (adlen >= 8) {
      s.x0 ^= LOADBYTES(ad, 8);
      s.x1 ^= LOADBYTES(ad + 8, adlen - 8);
      s.x1 ^= PAD(adlen - 8);
    } else {
      s.x0 ^= LOADBYTES(ad, adlen);
      s.x0 ^= PAD(adlen);
    }
    P8(&s);
  }
  /* domain separation */
  s.x4 ^= 1;
  printstate("process associated data", &s);

  /* full ciphertext blocks */
  clen -= CRYPTO_ABYTES;
  while (clen >= ASCON_128A_RATE) {
    uint64_t c0 = LOADBYTES(c, 8);
    uint64_t c1 = LOADBYTES(c + 8, 8);
    STOREBYTES(m, s.x0 ^ c0, 8);
    STOREBYTES(m + 8, s.x1 ^ c1, 8);
    s.x0 = c0;
    s.x1 = c1;
    P8(&s);
    m += ASCON_128A_RATE;
    c += ASCON_128A_RATE;
    clen -= ASCON_128A_RATE;
  }
  /* final ciphertext block */
  if (clen >= 8) {
    uint64_t c0 = LOADBYTES(c, 8);
    uint64_t c1 = LOADBYTES(c + 8, clen - 8);
    STOREBYTES(m, s.x0 ^ c0, 8);
    STOREBYTES(m + 8, s.x1 ^ c1, clen - 8);
    s.x0 = c0;
    s.x1 = CLEARBYTES(s.x1, clen - 8);
    s.x1 |= c1;
    s.x1 ^= PAD(clen - 8);
  } else {
    uint64_t c0 = LOADBYTES(c, clen);
    STOREBYTES(m, s.x0 ^ c0, clen);
    s.x0 = CLEARBYTES(s.x0, clen);
    s.x0 |= c0;
    s.x0 ^= PAD(clen);
  }
  c += clen;
  printstate("process ciphertext", &s);

  /* finalize */
  s.x2 ^= K0;
  s.x3 ^= K1;
  P12(&s);
  s.x3 ^= K0;
  s.x4 ^= K1;
  printstate("finalization", &s);

  /* set tag */
  uint8_t t[16];
  STOREBYTES(t, s.x3, 8);
  STOREBYTES(t + 8, s.x4, 8);

  /* verify tag (should be constant time, check compiler output) */
  int result = 0;
  for (int i = 0; i < CRYPTO_ABYTES; ++i) result |= c[i] ^ t[i];
  result = (((result - 1) >> 8) & 1) - 1;

  return result;
}
