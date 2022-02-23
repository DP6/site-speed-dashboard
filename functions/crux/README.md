# main.py
## Overview

<dl>

<dt><a href="#main">main(context)</a></dt>
<dd><p>Checks if CrUX's last month table already exists and, if it does, copies the data to your BigQuery's CrUX table</p></dd>

</dl>

## Parameters

<a name="main"></a>

## main(context)

Checks if CrUX's month table already exists and, if it does, copies the data to your BigQuery's CrUX table

**Kind**: global function

| Param   | Type                | Description            |
| ------- | ------------------- | -----------------------|
| context | <code>String</code> | Context in which the request will be executed |

# util_class.py

<dl>

**<dt>table_suffix()</dt>**
<dd><p>Gets table suffix for the last month in CrUX's public dataset tables format</p></dd>

**<dt>check_rows()</dt>**
<dd><p>Gets number of rows in your BigQuery's CrUX table</p></dd>

**<dt>check_table_crux()</dt>**
<dd><p>Checks if last month's CrUX table already exists</p></dd>

**<dt>check_last_month()</dt>**
<dd><p>Checks if last month's CrUX data has already been inserted in your BigQuery's CrUX table</p></dd>

**<dt>get_domains()</dt>**
<dd><p>Gets list of URLs in the config.json file</p></dd>

**<dt>get_countries()</dt>**
<dd><p>Gets list of countries in the config.json file</p></dd>

**<dt>update_crux_table()</dt>**
<dd><p>Update your BigQuery's CrUX table</p></dd>

</dl>

# util_query.py

## Overview

<dl>

<dt><a href="#crux_query">crux_query(countries,domains,table_suffix)</a></dt>
<dd><p>Formats and executes query to retrieve data from CrUX's public dataset tables</p></dd>

</dl>

<a name="crux_query"></a>

## Parameters
## crux_query(countries,domains,table_suffix)

Formats and executes query to retrieve data from CrUX's public dataset tables

**Kind**: global function

| Param        | Type                | Description             |
| ------------ | ------------------- | ----------------------- |
| countries    | <code>List</code>   | List of countries       |
| domains      | <code>List</code>   | List of URLs            |
| table_suffix | <code>String</code> | Suffix of the CrUX table|
