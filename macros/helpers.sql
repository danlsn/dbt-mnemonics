{# Substitute a SQL expression without creating a correlated subquery. #}
{% macro _bind(value, alias) %}{{ caller().replace('@dbtm_' ~ alias ~ '@', '(' ~ value ~ ')') }}{% endmacro %}

{% macro _join(n, alias) %}
array_to_string(transform(array_generate_range(0, ({{ n }})::int), {{ alias }} -> {{ caller() }}), '')
{% endmacro %}

{% macro _error(message, value) %}
to_varchar(to_number(concat('dbt_mnemonics: {{ message }} [', left(to_varchar({{ value }}), 40), ']')))
{% endmacro %}

{% macro _hex_input(x, kind) %}
{% if kind == 'hex' %}
case when regexp_like({{ x }}, '(0[xX])?([0-9a-fA-F]{2})*') then lower(regexp_replace({{ x }}, '^0[xX]', ''))
else {{ dbt_mnemonics._error('expected pairs of hex digits', x) }} end
{% elif kind == 'text' %}lower(hex_encode({{ x }}))
{% elif kind == 'integer' %}
case when {{ x }} < 0 or trunc({{ x }}) != {{ x }} then {{ dbt_mnemonics._error('expected unsigned integer', x) }}
else
{% call dbt_mnemonics._bind("lower(ltrim(to_char((" ~ x ~ ")::number(38,0), '" ~ 'X'*32 ~ "'), ' 0'))", 'digits') %}
iff(length(@dbtm_digits@::varchar) = 0, '00', lpad(@dbtm_digits@::varchar, 2 * ceil(length(@dbtm_digits@::varchar)/2), '0'))
{% endcall %}::varchar end
{% else %}{{ exceptions.raise_compiler_error('input_type must be hex, text or integer') }}{% endif %}
{% endmacro %}

{# Convert between bit strings and fixed-size alphabet symbols. #}
{% macro _bits(s, alphabet, width) %}
array_to_string(transform(regexp_substr_all({{ s }}, '.'), ch ->
substr('{{ dbt_mnemonics._bit_table(width) }}', 1 + {{ width }} * (position(ch::varchar, '{{ alphabet }}')-1), {{ width }})), '')
{% endmacro %}
{% macro _bit_table(width) -%}
{% for i in range(2**width) %}{% for j in range(width-1,-1,-1) %}{{ (i // 2**j) % 2 }}{% endfor %}{% endfor %}
{%- endmacro %}
{% macro _number(bits, width) %}
(0{% for j in range(width) %} + substr({{ bits }}, {{ j+1 }}, 1)::int * {{ 2**(width-1-j) }}{% endfor %})
{% endmacro %}
{% macro _symbols(s, alphabet, width, count) %}
array_to_string(transform(regexp_substr_all(left({{ s }}, ({{ count }})::int * {{ width }}), '.{1,{{ width }}}'), chunk ->
substr('{{ alphabet }}', 1 + {{ dbt_mnemonics._number("rpad(chunk::varchar, " ~ width ~ ", '0')",width) }}, 1)), '')
{% endmacro %}
