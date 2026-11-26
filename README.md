# dbt-mnemonics

Convert Snowflake column values into pronounceable proquints, English BIP39 phrases, or Crockford Base32 strings. All seven macros use adapter dispatch and compile to scalar SQL. Snowflake is the first supported adapter.

## Install

For a local checkout beside your dbt project, add this to your project's `packages.yml` and run `dbt deps`.

```yaml
packages:
  - local: ../dbt-mnemonics
```

## Use in a model

```sql
select
    {{ dbt_mnemonics.proquint('customer_id', input_type='text') }} as customer_quint,
    {{ dbt_mnemonics.short_label('customer_id', input_type='text') }} as customer_label,
    {{ dbt_mnemonics.bip39('sha256_hex', input_type='hex') }} as digest_words,
    {{ dbt_mnemonics.crockford_base32('sequence_number', input_type='integer') }} as sequence_code
from {{ ref('customers') }}
```

Pass a SQL expression as the first argument. Encoders require `input_type`. Text uses exact UTF-8. Hex accepts digit pairs with optional `0x` or `0X`. Unsigned whole numbers use the shortest big-endian representation, with one zero byte for zero. Each macro propagates SQL NULL.

| Encoder | Decoder | Convention |
|---|---|---|
| `proquint` | `decode_proquint` | One five-letter group per two bytes. Odd lengths get a zero padding byte and an original-byte-count suffix, e.g. hex `01` becomes `bahab~1`. Pass `strict=true` on either side for standard groups only. |
| `bip39` | `decode_bip39` | 16, 20, 24, 28 or 32 bytes of entropy. The English word list is compiled into SQL. Decoding verifies the SHA-256 checksum. |
| `crockford_base32` | `decode_crockford_base32` | Five-bit groups with zero bits on the right. Hex `0001` becomes `000G`. Decoding ignores hyphens and case, accepts O for zero and I/L for one, and checks padding. |
| `short_label` | — | First three proquint groups of SHA-256 over the input bytes. Pass `groups=2` for a shorter label. Collisions are possible. |

Decoders return lowercase hex. For example, `{{ dbt_mnemonics.decode_proquint('customer_quint', output_type='text') }}` restores the original text. Text output requires valid UTF-8. Integer output requires at least one byte and a value within Snowflake's NUMBER(38,0) range. Empty text and empty hex represent zero bytes.

## Verify in Snowflake

From this checkout, run the following with your Snowflake profile.

```sh
dbt deps --project-dir integration_tests --profile YOUR_PROFILE
dbt test --project-dir integration_tests --profile YOUR_PROFILE
```

The bundled dictionary is the [standard BIP39 English word list](https://github.com/bitcoin/bips/blob/master/bip-0039/english.txt).
