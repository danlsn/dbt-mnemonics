{% macro _convert(name, expression, kind, option=none) %}
{% set decode = name.startswith('decode_') %}
{% if name == 'short_label' and option not in [2,3] %}{{ exceptions.raise_compiler_error('groups must be 2 or 3') }}{% endif %}
case when ({{ expression }}) is null then null else
{% if decode %}
{% call dbt_mnemonics._bind(dbt_mnemonics._decode(name[7:], '(' ~ expression ~ ')::varchar', option), 'rawhex') %}
{{ dbt_mnemonics._output('@dbtm_rawhex@::varchar', kind) }}
{% endcall %}{% if kind == 'integer' %}::number(38,0){% else %}::varchar{% endif %}
{% else %}
{% call dbt_mnemonics._bind(dbt_mnemonics._hex_input('(' ~ expression ~ ')',kind), 'hx') %}
{% if name == 'short_label' %}
{{ dbt_mnemonics._encode('proquint', "lower(substr(sha2(to_binary(@dbtm_hx@::varchar,'HEX'),256),1," ~ option*4 ~ '))',false) }}
{% else %}{{ dbt_mnemonics._encode(name,'@dbtm_hx@::varchar',option) }}{% endif %}
{% endcall %}::varchar
{% endif %}end
{% endmacro %}

{% macro _output(h, kind) %}
{% if kind == 'hex' %}{{ h }}
{% elif kind == 'text' %}case when try_hex_decode_string({{ h }}) is null then {{ dbt_mnemonics._error('invalid UTF-8',h) }} else hex_decode_string({{ h }}) end
{% elif kind == 'integer' %}
{% call dbt_mnemonics._bind("ltrim(" ~ h ~ ", '0')",'mag') %}
case when {{ h }} = '' then {{ dbt_mnemonics._error('zero bytes cannot decode to integer',h) }}::number
when length(@dbtm_mag@::varchar)>32 or (length(@dbtm_mag@::varchar)=32 and @dbtm_mag@::varchar>'4b3b4ca85a86c47a098a223fffffffff')
then {{ dbt_mnemonics._error('integer exceeds NUMBER(38,0)',h) }}::number
when @dbtm_mag@::varchar='' then 0 else to_number(@dbtm_mag@::varchar,'{{ 'X'*32 }}') end
{% endcall %}
{% else %}{{ exceptions.raise_compiler_error('output_type must be hex, text or integer') }}{% endif %}
{% endmacro %}

{% macro _encode(name,h,strict) %}
{% set hex='0123456789abcdef' %}
{% set bits=dbt_mnemonics._bits(h,hex,4) %}
{% if name == 'bip39' %}
case when length({{ h }}) not in (32,40,48,56,64) then {{ dbt_mnemonics._error('BIP39 expects 16, 20, 24, 28 or 32 bytes. Actual bytes', 'length(' ~ h ~ ')/2') }} else
{% set bits=bits ~ ' || left(' ~ dbt_mnemonics._bits("lower(left(sha2(to_binary(" ~ h ~ ",'HEX'),256),2))",hex,4) ~ ',length(' ~ h ~ ')/8)' %}
{% endif %}
{% call dbt_mnemonics._bind(bits,'stream') %}
{% if name=='crockford_base32' %}
{{ dbt_mnemonics._symbols('@dbtm_stream@::varchar','0123456789ABCDEFGHJKMNPQRSTVWXYZ',5,'ceil(length(@dbtm_stream@::varchar)/5)') }}
{% elif name=='proquint' %}
case {% if strict %}when mod(length({{ h }}),4)=2 then {{ dbt_mnemonics._error('strict proquint requires an even byte count',h) }}{% endif %}
when {{ h }}='' then '' else
array_to_string(transform(array_generate_range(0,ceil(length(@dbtm_stream@::varchar)/16)::int), qi ->
{% for pos,w,alphabet in [(1,4,'bdfghjklmnprstvz'),(5,2,'aiou'),(7,4,'bdfghjklmnprstvz'),(11,2,'aiou'),(13,4,'bdfghjklmnprstvz')] %}
substr('{{ alphabet }}',1+{{ dbt_mnemonics._number("substr(@dbtm_stream@::varchar || '00000000',qi*16+" ~ pos ~ ',' ~ w ~ ')',w) }},1){% if not loop.last %} || {% endif %}
{% endfor %}),'-') || iff(mod(length({{ h }}),4)=2,'~'||to_varchar((length({{ h }})/2)::int),'') end
{% else %}
array_to_string(transform(array_generate_range(0,(length(@dbtm_stream@::varchar)/11)::int), wi -> get({{ dbt_mnemonics._words() }}, {{ dbt_mnemonics._number('substr(@dbtm_stream@::varchar,wi*11+1,11)',11) }})::varchar),' ')
{% endif %}
{% endcall %}::varchar
{% if name=='bip39' %}end{% endif %}
{% endmacro %}
