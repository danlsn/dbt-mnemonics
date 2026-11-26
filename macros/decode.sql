{% macro _decode(name,x,strict) %}
{% set hex='0123456789abcdef' %}
{% if name=='crockford_base32' %}
{% set alphabet='0123456789ABCDEFGHJKMNPQRSTVWXYZ' %}
{% call dbt_mnemonics._bind("translate(upper(replace(" ~ x ~ ",'-','')), 'OIL','011')",'clean') %}
case when not regexp_like(@dbtm_clean@::varchar,'[{{ alphabet }}]*') or mod(length(@dbtm_clean@::varchar),8) not in (0,2,4,5,7)
then {{ dbt_mnemonics._error('invalid Crockford symbols or length',x) }} else
{% call dbt_mnemonics._bind(dbt_mnemonics._bits('@dbtm_clean@::varchar',alphabet,5),'stream') %}
case when contains(substr(@dbtm_stream@::varchar,8*floor(length(@dbtm_stream@::varchar)/8)+1),'1')
then {{ dbt_mnemonics._error('nonzero Crockford padding bits',x) }}
else {{ dbt_mnemonics._symbols('@dbtm_stream@::varchar',hex,4,'2*floor(length(@dbtm_stream@::varchar)/8)') }} end
{% endcall %}::varchar end
{% endcall %}::varchar
{% elif name=='proquint' %}
{% set c='bdfghjklmnprstvz' %}{% set v='aiou' %}
{% set group='[' ~ c ~ '][' ~ v ~ '][' ~ c ~ '][' ~ v ~ '][' ~ c ~ ']' %}
case when {{ x }}='' then '' when not regexp_like({{ x }},'{{ group }}(-{{ group }})*{% if not strict %}(~[1-9][0-9]*)?{% endif %}') then {{ dbt_mnemonics._error('invalid proquint or suffix',x) }} else
{% call dbt_mnemonics._bind("replace(split_part(" ~ x ~ ",'~',1),'-','')",'quints') %}
{% set stream %}
{% call dbt_mnemonics._join('length(@dbtm_quints@::varchar)/5','qi') %}
{% for a,w in [(c,4),(v,2),(c,4),(v,2),(c,4)] %}
substr('{{ dbt_mnemonics._bit_table(w) }}',1+{{ w }}*(position(substr(@dbtm_quints@::varchar,qi*5+{{ loop.index }},1),'{{ a }}')-1),{{ w }}){% if not loop.last %} || {% endif %}
{% endfor %}
{% endcall %}
{% endset %}
{% call dbt_mnemonics._bind(stream,'stream') %}
{% call dbt_mnemonics._bind(dbt_mnemonics._symbols('@dbtm_stream@::varchar',hex,4,'length(@dbtm_stream@::varchar)/4'),'padded') %}
case when not contains({{ x }},'~') then @dbtm_padded@::varchar
when split_part({{ x }},'~',2)=to_varchar((length(@dbtm_padded@::varchar)/2-1)::int) and right(@dbtm_padded@::varchar,2)='00' then left(@dbtm_padded@::varchar,length(@dbtm_padded@::varchar)-2)
else {{ dbt_mnemonics._error('invalid proquint padding or byte count',x) }} end
{% endcall %}::varchar
{% endcall %}::varchar
{% endcall %}::varchar end
{% else %}
{% call dbt_mnemonics._bind("split(" ~ x ~ ",' ')",'tokens') %}
case when array_size(@dbtm_tokens@) not in (12,15,18,21,24) then {{ dbt_mnemonics._error('invalid BIP39 word count',x) }} else
{% set stream %}
array_to_string(transform(@dbtm_tokens@::array, word -> coalesce(substr('{{ dbt_mnemonics._bit_table(11) }}',1+11*array_position(word::variant,{{ dbt_mnemonics._words() }}),11),'?')),'')
{% endset %}
{% call dbt_mnemonics._bind(stream,'stream') %}
case when contains(@dbtm_stream@::varchar,'?') then {{ dbt_mnemonics._error('unknown BIP39 word',x) }} else
{% call dbt_mnemonics._bind(dbt_mnemonics._symbols('@dbtm_stream@::varchar',hex,4,'array_size(@dbtm_tokens@)*8/3'),'entropy') %}
case when right(@dbtm_stream@::varchar,(array_size(@dbtm_tokens@)/3)::int)=left({{ dbt_mnemonics._bits("lower(left(sha2(to_binary(@dbtm_entropy@::varchar,'HEX'),256),2))",hex,4) }},(array_size(@dbtm_tokens@)/3)::int)
then @dbtm_entropy@::varchar else {{ dbt_mnemonics._error('invalid BIP39 checksum',x) }} end
{% endcall %}::varchar end
{% endcall %}::varchar end
{% endcall %}::varchar
{% endif %}
{% endmacro %}
