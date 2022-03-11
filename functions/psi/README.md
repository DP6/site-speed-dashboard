# Overview

<dl>

<dt><a href="#getUrls">getUrls(req, res)</a></dt>
<dd><p>Gets urls and processes data</p></dd>

<dt><a href="#getUrlsDesktop">getUrlsDesktop(strategy => 'desktop')</a></dt>
<dd><p>Gets all URLs with strategy = desktop</p></dd>

<dt><a href="#getUrlsMobile">getUrlsMobile(strategy => 'mobile')</a></dt>
<dd><p>Gets all URLs with strategy = mobile</p></dd>

<dt><a href="#makeRequest">makeRequest(urls, strategy)</a></dt>
<dd><p>Requests api results for the given urls and strategies</p></dd>

<dt><a href="#processPsiData">processPsiData()</a></dt>
<dd><p>Processes PSI API responses</p></dd>

<dt><a href="#insertRowsAsStream">insertRowsAsStream(data)</a></dt>
<dd><p>Persists data on BigQuery via Stream</p></dd>

<dt><a href="#loadProjectConfig">loadProjectConfig()</a></dt>
<dd><p>Loads configuration file stored into Google Cloud Storage</p></dd>

<dt><a href="#trace">trace(log)</a></dt>
<dd><p>Sends log into stdout only if the variable debugging = true</p></dd>

</dl>

# Parameters

<a name="getUrls"></a>

## getUrls(req, res)

Gets urls and processes data

**Kind**: global function

| Param | Type                | Description             |
| ----- | ------------------- | ----------------------- |
| req   | <code>String</code> | Request for the PSI API |
| res   | <code>String</code> | Response of the PSI API |

<a name="getUrlsDesktop"></a>

## getUrlsDesktop(strategy => 'desktop')

Gets all URLs with strategy = desktop

**Kind**: global function

<a name="getUrlsMobile"></a>

## getUrlsMobile(strategy => 'mobile')

Gets all URLs with strategy = mobile

**Kind**: global function

<a name="makeRequest"></a>

## makeRequest(urls, strategy)

Requests api results for the given urls and strategies

**Kind**: global function

| Param    | Type               | Description                                                 |
| -------- | ------------------ | ----------------------------------------------------------- |
| urls     | <code>Array</code> | URL base information (url, brand, page)                     |
| strategy | <code>Array</code> | Strategy that will be used in the request (desktop, mobile) |

<a name="processPsiData"></a>

## processPsiData()

Processes PSI API responses

**Kind**: global function

<a name="insertRowsAsStream"></a>

## insertRowsAsStream(data)

Persists data on BigQuery via Stream

**Kind**: global function

| Param | Type               | Description                                             |
| ----- | ------------------ | ------------------------------------------------------- |
| data  | <code>Array</code> | Structured data in the persistency standard of BigQuery |

<a name="loadProjectConfig"></a>

## loadProjectConfig()

Loads configuration file stored into Google Cloud Storage

**Kind**: global function  
<a name="trace"></a>

## trace(log)

Sends log into stdout only if the variable debugging = true

**Kind**: global function

| Param | Type                | Description                       |
| ----- | ------------------- | --------------------------------- |
| log   | <code>Object</code> | Text that will be shown in stdout |
