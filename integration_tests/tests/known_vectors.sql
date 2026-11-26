with inputs as (
    select '7f000001' as ipv4, '0001' as fixed_width, repeat('00',16) as entropy,
        repeat('abandon ',11) || 'about' as phrase
)
select * from inputs
where {{ dbt_mnemonics.proquint('ipv4', 'hex') }} is distinct from 'lusab-babad'
   or {{ dbt_mnemonics.decode_proquint("'bahab~1'", 'integer') }} is distinct from 1
   or {{ dbt_mnemonics.crockford_base32('fixed_width', 'hex') }} is distinct from '000G'
   or {{ dbt_mnemonics.decode_crockford_base32("'OOO-g'") }} is distinct from fixed_width
   or {{ dbt_mnemonics.bip39('entropy','hex') }} is distinct from phrase
   or {{ dbt_mnemonics.decode_bip39('phrase') }} is distinct from entropy
   or {{ dbt_mnemonics.short_label("''",'text') }} is distinct from {{ dbt_mnemonics.proquint("'e3b0c44298fc'",'hex') }}
   or {{ dbt_mnemonics.crockford_base32('99999999999999999999999999999999999999','integer') }} is distinct from '9CXMSA2TGV27M2CA48ZZZZZZZW'
   or {{ dbt_mnemonics.decode_crockford_base32("'9CXMSA2TGV27M2CA48ZZZZZZZW'",'integer') }} is distinct from 99999999999999999999999999999999999999
