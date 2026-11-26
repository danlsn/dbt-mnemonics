{% macro proquint(expression, input_type, strict=false) %}
  {{ return(adapter.dispatch('proquint', 'dbt_mnemonics')(expression, input_type, strict)) }}
{% endmacro %}

{% macro snowflake__proquint(expression, input_type, strict=false) %}
  {{ dbt_mnemonics._convert('proquint', expression, input_type, strict) }}
{% endmacro %}

{% macro bip39(expression, input_type) %}
  {{ return(adapter.dispatch('bip39', 'dbt_mnemonics')(expression, input_type)) }}
{% endmacro %}

{% macro snowflake__bip39(expression, input_type) %}
  {{ dbt_mnemonics._convert('bip39', expression, input_type) }}
{% endmacro %}

{% macro crockford_base32(expression, input_type) %}
  {{ return(adapter.dispatch('crockford_base32', 'dbt_mnemonics')(expression, input_type)) }}
{% endmacro %}

{% macro snowflake__crockford_base32(expression, input_type) %}
  {{ dbt_mnemonics._convert('crockford_base32', expression, input_type) }}
{% endmacro %}

{% macro decode_proquint(expression, output_type='hex', strict=false) %}
  {{ return(adapter.dispatch('decode_proquint', 'dbt_mnemonics')(expression, output_type, strict)) }}
{% endmacro %}

{% macro snowflake__decode_proquint(expression, output_type='hex', strict=false) %}
  {{ dbt_mnemonics._convert('decode_proquint', expression, output_type, strict) }}
{% endmacro %}

{% macro decode_bip39(expression, output_type='hex') %}
  {{ return(adapter.dispatch('decode_bip39', 'dbt_mnemonics')(expression, output_type)) }}
{% endmacro %}

{% macro snowflake__decode_bip39(expression, output_type='hex') %}
  {{ dbt_mnemonics._convert('decode_bip39', expression, output_type) }}
{% endmacro %}

{% macro decode_crockford_base32(expression, output_type='hex') %}
  {{ return(adapter.dispatch('decode_crockford_base32', 'dbt_mnemonics')(expression, output_type)) }}
{% endmacro %}

{% macro snowflake__decode_crockford_base32(expression, output_type='hex') %}
  {{ dbt_mnemonics._convert('decode_crockford_base32', expression, output_type) }}
{% endmacro %}

{% macro short_label(expression, input_type, groups=3) %}
  {{ return(adapter.dispatch('short_label', 'dbt_mnemonics')(expression, input_type, groups)) }}
{% endmacro %}

{% macro snowflake__short_label(expression, input_type, groups=3) %}
  {{ dbt_mnemonics._convert('short_label', expression, input_type, groups) }}
{% endmacro %}
