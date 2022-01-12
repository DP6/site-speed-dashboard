## Query responsible to retrieve CRUX data at bigquery public dataset.
def crux_query(countries,domains,table_suffix):
    country_list = ""
    for ind,c in enumerate(countries):
        c = "country_" + c if c != "all" else c    
        union_all = "union all \n" if(ind < (len(countries) - 1)) else ''
        country_list  = country_list + f"select _TABLE_SUFFIX as year_month , * from  `chrome-ux-report.{c}.*` \n where _TABLE_SUFFIX = '{table_suffix}' and origin in ({domains}) \n {union_all}" 

    return """
    with 
 
base_crux as (

{country_list}

),


lcp as (  --- LCP
SELECT 
year_month,
origin, 
bin.start start  , 
bin.end ended ,   
effective_connection_type.name AS connection,
form_factor.name AS form,
sum(bin.density) density

 FROM base_crux left join unnest(largest_contentful_paint.histogram.bin) as bin
 group by 1,2,3,4,5,6
 order by start
),
fcp as (        --- FCP
SELECT 
year_month,
origin, 
bin.start start  , 
bin.end ended ,   
effective_connection_type.name AS connection,
form_factor.name AS form,
sum(bin.density) density

 FROM base_crux left join unnest(first_contentful_paint.histogram.bin) as bin
 group by 1,2,3,4,5,6
 order by start
),
dcl as (          --- DCL
SELECT 
year_month,
origin, 
bin.start start  , 
bin.end ended ,   
effective_connection_type.name AS connection,
form_factor.name AS form,
sum(bin.density) density

 FROM base_crux left join unnest(dom_content_loaded.histogram.bin) as bin
 group by 1,2,3,4,5,6
 order by start
),
onload as (          --- ONLOAD
SELECT 
year_month,
origin, 
bin.start start  , 
bin.end ended,   
effective_connection_type.name AS connection,
form_factor.name AS form,
sum(bin.density) density

 FROM base_crux  left join unnest(onload.histogram.bin) as bin
 group by 1,2,3,4,5,6
 order by start
),
fp as (          --- FP
SELECT 
year_month,
origin, 
bin.start start  , 
bin.end ended ,   
effective_connection_type.name AS connection,
form_factor.name AS form,
sum(bin.density) density

 FROM base_crux left join unnest(first_paint.histogram.bin) as bin
 group by 1,2,3,4,5,6
 order by start
),

fid as (          --- FID
SELECT 
year_month,
origin, 
bin.start start  , 
bin.end ended ,   
effective_connection_type.name AS connection,
form_factor.name AS form,
sum(bin.density) density

 FROM base_crux left join unnest(first_input.delay.histogram.bin) as bin
 group by 1,2,3,4,5,6
 order by start
),


ttfb as (          --- TTFB
SELECT 
year_month,
origin, 
bin.start start  , 
bin.end ended ,   
effective_connection_type.name AS connection,
form_factor.name AS form,
sum(bin.density) density

 FROM base_crux left join unnest(experimental.time_to_first_byte.histogram.bin) as bin
 group by 1,2,3,4,5,6
 order by start
),

cls as (          --- CLS
SELECT 
year_month,
origin, 
bin.start start  , 
bin.end ended ,   
effective_connection_type.name AS connection,
form_factor.name AS form,
sum(bin.density) density

 FROM base_crux left join unnest(layout_instability.cumulative_layout_shift.histogram.bin) as bin
 group by 1,2,3,4,5,6
 order by start
), base_final as ( 



select 
coalesce(lcp.year_month,fcp.year_month,dcl.year_month,onload.year_month,fp.year_month,fid.year_month,ttfb.year_month,cls.year_month ) as year_month,
coalesce(lcp.start,fcp.start,dcl.start,onload.start,fp.start,fid.start,ttfb.start,cls.start) as start,
coalesce(lcp.ended,fcp.ended,dcl.ended,onload.ended,fp.ended,fid.ended,ttfb.ended,cls.ended) as ended,
coalesce(lcp.form,fcp.form,dcl.form,onload.form,fp.form,fid.form,ttfb.form,cls.form) as form,
coalesce(lcp.origin,fcp.origin,dcl.origin,onload.origin,fp.origin,fid.origin,ttfb.origin,cls.origin) as origin,
coalesce(lcp.connection,fcp.connection,dcl.connection,onload.connection,fp.connection,fid.connection,ttfb.connection,cls.connection) as connection,


coalesce(fcp.density,0) fcp_density,
coalesce(lcp.density,0) lcp_density,
coalesce(dcl.density,0) dcl_density,
coalesce(onload.density,0) onload_density,
coalesce(fp.density,0) fp_density,
coalesce(fid.density,0) fid_density,
coalesce(ttfb.density,0) ttfb_density,
coalesce(cls.density,0) cls_density

from lcp
full outer join 
fcp using(year_month,start,form,origin,connection,ended)
full outer join 
dcl using(year_month,start,form,origin,connection,ended)
full outer join 
onload using(year_month,start,form,origin,connection,ended)
full outer join 
fp using(year_month,start,form,origin,connection,ended)
full outer join 
fid using(year_month,start,form,origin,connection,ended)
full outer join 
ttfb using(year_month,start,form,origin,connection,ended)
full outer join 
cls using(year_month,start,form,origin,connection,ended)
),
 thresholds as (

select 

[
    struct("LCP" as metric, 2500 as min , 4000 as max ),
    struct("FID" as metric, 100 as min , 300 as max ),
    struct("CLS" as metric, 0.10 as min , 0.25 as max ),
    struct("FCP" as metric, 1500 as min , 2500 as max ),
    struct("TTFB" as metric, 500 as min , 1500 as max ),
    struct("FP" as metric, 1000 as min , 3000 as max ),
    struct("DCL" as metric, 1500 as min , 3500 as max ),
    struct("OL" as metric, 2500 as min , 6500 as max )

]
 as limits

)
select 
date(cast(regexp_extract(year_month,"^(....)") as INT64 ),cast(regexp_extract(year_month,"(..)$") as INT64),1) as data,
* except(limits),



if(start <  (select min from unnest(limits) where metric = "LCP") ,lcp_density,0) as good_lcp,
if(start >= (select max from unnest(limits) where metric = "LCP") ,lcp_density,0) as poor_lcp,
if(start >= (select min from unnest(limits) where metric = "LCP") and start < (select max from unnest(limits) where metric = "LCP") ,lcp_density,0) as average_lcp,

if(start <  (select min from unnest(limits) where metric = "FP") , fp_density,0) as good_fp,
if(start >= (select max from unnest(limits) where metric = "FP") ,fp_density,0) as poor_fp,
if(start >= (select min from unnest(limits) where metric = "FP") and start < (select max from unnest(limits) where metric = "FP") ,fp_density,0) as average_fp,

if(start <  (select min from unnest(limits) where metric = "OL") ,onload_density,0) as good_onload,
if(start >= (select max from unnest(limits) where metric = "OL") ,onload_density,0) as poor_onload,
if(start >= (select min from unnest(limits) where metric = "OL") and start < (select max from unnest(limits) where metric = "OL") ,onload_density,0) as average_onload,

if(start <  (select min from unnest(limits) where metric = "FCP") ,fcp_density,0) as good_fcp,
if(start >= (select max from unnest(limits) where metric = "FCP") ,fcp_density,0) as poor_fcp,
if(start >= (select min from unnest(limits) where metric = "FCP") and start < (select max from unnest(limits) where metric = "FCP") ,fcp_density,0) as average_fcp,

if(start <  (select min from unnest(limits) where metric = "DCL") ,dcl_density,0) as good_dcl,
if(start >= (select max from unnest(limits) where metric = "DCL") ,dcl_density,0) as poor_dcl,
if(start >= (select min from unnest(limits) where metric = "DCL") and start < (select max from unnest(limits) where metric = "DCL") ,dcl_density,0) as average_dcl,

if(start <  (select min from unnest(limits) where metric = "FID") ,fid_density,0) as good_fid,
if(start >= (select max from unnest(limits) where metric = "FID") ,fid_density,0) as poor_fid,
if(start >= (select min from unnest(limits) where metric = "FID") and start < (select max from unnest(limits) where metric = "FID") ,fid_density,0) as average_fid,

if(start <  (select min from unnest(limits) where metric = "CLS") ,cls_density,0) as good_cls,
if(start >= (select max from unnest(limits) where metric = "CLS") ,cls_density,0) as poor_cls,
if(start >= (select min from unnest(limits) where metric = "CLS") and start < (select max from unnest(limits) where metric = "CLS") ,cls_density,0) as average_cls,

if(start <  (select min from unnest(limits) where metric = "TTFB") ,ttfb_density,0) as good_ttfb,
if(start >= (select max from unnest(limits) where metric = "TTFB") ,ttfb_density,0) as poor_ttfb,
if(start >= (select min from unnest(limits) where metric = "TTFB") and start < (select max from unnest(limits) where metric = "TTFB") ,ttfb_density,0) as average_ttfb,



from base_final ,thresholds as t


""".format(domains = domains,table_suffix = table_suffix, country_list = country_list)