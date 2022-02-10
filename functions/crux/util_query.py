## Query responsible to retrieve CRUX data at bigquery public dataset.
def crux_query(countries,domains,table_suffix):
    country_list = ""
    for ind,c in enumerate(countries):
        c = "country_" + c if c != "all" else c
        union_all = "union all \n" if(ind < (len(countries) - 1)) else ''
        country_list  = country_list + f"SELECT _TABLE_SUFFIX AS year_month, * from  `chrome-ux-report.{c}.*` \n WHERE _TABLE_SUFFIX = '{table_suffix}' AND origin in ({domains}) \n {union_all}"

    return f"""
        WITH base_crux AS 
        (
            {country_list}
        ),
        lcp AS
        (          --- LCP
            SELECT 
                year_month,
                origin, 
                bin.start start, 
                bin.end ended,   
                effective_connection_type.name AS connection,
                form_factor.name AS form,
                sum(bin.density) density
            FROM base_crux 
                LEFT JOIN UNNEST(largest_contentful_paint.histogram.bin) AS bin
            GROUP BY 1,2,3,4,5,6
            ORDER BY start
        ),
        fcp AS 
        (          --- FCP
            SELECT 
                year_month,
                origin, 
                bin.start start, 
                bin.end ended,   
                effective_connection_type.name AS connection,
                form_factor.name AS form,
                sum(bin.density) density
            FROM base_crux 
                LEFT JOIN UNNEST(first_contentful_paint.histogram.bin) AS bin
            GROUP BY 1,2,3,4,5,6
            ORDER BY start
        ),
        dcl AS 
        (          --- DCL
            SELECT 
                year_month,
                origin, 
                bin.start start, 
                bin.end ended,   
                effective_connection_type.name AS connection,
                form_factor.name AS form,
                sum(bin.density) density
            FROM base_crux 
                LEFT JOIN UNNEST(dom_content_loaded.histogram.bin) AS bin
            GROUP BY 1,2,3,4,5,6
            ORDER BY start
        ),
        onload AS 
        (          --- ONLOAD
            SELECT 
                year_month,
                origin, 
                bin.start start, 
                bin.end ended,   
                effective_connection_type.name AS connection,
                form_factor.name AS form,
                sum(bin.density) density
            FROM base_crux  
                LEFT JOIN UNNEST(onload.histogram.bin) AS bin
            GROUP BY 1,2,3,4,5,6
            ORDER BY start
        ),
        fp AS 
        (          --- FP
            SELECT 
                year_month,
                origin, 
                bin.start start, 
                bin.end ended,   
                effective_connection_type.name AS connection,
                form_factor.name AS form,
                sum(bin.density) density
            FROM base_crux 
                LEFT JOIN UNNEST(first_paint.histogram.bin) AS bin
            GROUP BY 1,2,3,4,5,6
            ORDER BY start
        ),
        fid AS 
        (          --- FID
            SELECT 
                year_month,
                origin, 
                bin.start start,
                bin.end ended,
                effective_connection_type.name AS connection,
                form_factor.name AS form,
                sum(bin.density) density
            FROM base_crux 
                LEFT JOIN UNNEST(first_input.delay.histogram.bin) AS bin
            GROUP BY 1,2,3,4,5,6
            ORDER BY start
        ),
        ttfb AS 
        (          --- TTFB
            SELECT 
                year_month,
                origin, 
                bin.start start,
                bin.end ended,
                effective_connection_type.name AS connection,
                form_factor.name AS form,
                sum(bin.density) density
            FROM base_crux 
                LEFT JOIN UNNEST(experimental.time_to_first_byte.histogram.bin) AS bin
            GROUP BY 1,2,3,4,5,6
            ORDER BY start
        ),
        cls AS
        (          --- CLS
            SELECT 
                year_month,
                origin, 
                bin.start start,
                bin.end ended,
                effective_connection_type.name AS connection,
                form_factor.name AS form,
                sum(bin.density) density
            FROM base_crux 
                LEFT JOIN UNNEST(layout_instability.cumulative_layout_shift.histogram.bin) AS bin
            GROUP BY 1,2,3,4,5,6
            ORDER BY start
        ), 
        base_final AS 
        ( 
            SELECT 
                COALESCE(lcp.year_month,fcp.year_month,dcl.year_month,onload.year_month,fp.year_month,fid.year_month,ttfb.year_month,cls.year_month ) AS year_month,
                COALESCE(lcp.start,fcp.start,dcl.start,onload.start,fp.start,fid.start,ttfb.start,cls.start) AS start,
                COALESCE(lcp.ended,fcp.ended,dcl.ended,onload.ended,fp.ended,fid.ended,ttfb.ended,cls.ended) AS ended,
                COALESCE(lcp.form,fcp.form,dcl.form,onload.form,fp.form,fid.form,ttfb.form,cls.form) AS form,
                COALESCE(lcp.origin,fcp.origin,dcl.origin,onload.origin,fp.origin,fid.origin,ttfb.origin,cls.origin) AS origin,
                COALESCE(lcp.connection,fcp.connection,dcl.connection,onload.connection,fp.connection,fid.connection,ttfb.connection,cls.connection) AS connection,

                COALESCE(fcp.density,0) fcp_density,
                COALESCE(lcp.density,0) lcp_density,
                COALESCE(dcl.density,0) dcl_density,
                COALESCE(onload.density,0) onload_density,
                COALESCE(fp.density,0) fp_density,
                COALESCE(fid.density,0) fid_density,
                COALESCE(ttfb.density,0) ttfb_density,
                COALESCE(cls.density,0) cls_density
            FROM lcp
                FULL OUTER JOIN fcp using(year_month,start,form,origin,connection,ended)
                FULL OUTER JOIN dcl using(year_month,start,form,origin,connection,ended)
                FULL OUTER JOIN onload using(year_month,start,form,origin,connection,ended)
                FULL OUTER JOIN fp using(year_month,start,form,origin,connection,ended)
                FULL OUTER JOIN fid using(year_month,start,form,origin,connection,ended)
                FULL OUTER JOIN ttfb using(year_month,start,form,origin,connection,ended)
                FULL OUTER JOIN cls using(year_month,start,form,origin,connection,ended)
        ),
        thresholds AS 
        (

            SELECT 
                [
                    STRUCT("LCP"  AS metric, 2500 AS min, 4000 AS max),
                    STRUCT("FID"  AS metric, 100  AS min, 300  AS max),
                    STRUCT("CLS"  AS metric, 0.10 AS min, 0.25 AS max),
                    STRUCT("FCP"  AS metric, 1500 AS min, 2500 AS max),
                    STRUCT("TTFB" AS metric, 500  AS min, 1500 AS max),
                    STRUCT("FP"   AS metric, 1000 AS min, 3000 AS max),
                    STRUCT("DCL"  AS metric, 1500 AS min, 3500 AS max),
                    STRUCT("OL"   AS metric, 2500 AS min, 6500 AS max)
                ] AS limits

        )

        SELECT 
            date(cast(regexp_extract(year_month,"^(....)") AS INT64 ),cast(regexp_extract(year_month,"(..)$") AS INT64),1) AS data,
            * except(limits),

            IF(start <  (SELECT min from UNNEST(limits) WHERE metric = "LCP") ,lcp_density,0) AS good_lcp,
            IF(start >= (SELECT max from UNNEST(limits) WHERE metric = "LCP") ,lcp_density,0) AS poor_lcp,
            IF(start >= (SELECT min from UNNEST(limits) WHERE metric = "LCP") and start < (SELECT max from UNNEST(limits) WHERE metric = "LCP") ,lcp_density,0) AS average_lcp,

            IF(start <  (SELECT min from UNNEST(limits) WHERE metric = "FP") , fp_density,0) AS good_fp,
            IF(start >= (SELECT max from UNNEST(limits) WHERE metric = "FP") ,fp_density,0) AS poor_fp,
            IF(start >= (SELECT min from UNNEST(limits) WHERE metric = "FP") and start < (SELECT max from UNNEST(limits) WHERE metric = "FP") ,fp_density,0) AS average_fp,

            IF(start <  (SELECT min from UNNEST(limits) WHERE metric = "OL") ,onload_density,0) AS good_onload,
            IF(start >= (SELECT max from UNNEST(limits) WHERE metric = "OL") ,onload_density,0) AS poor_onload,
            IF(start >= (SELECT min from UNNEST(limits) WHERE metric = "OL") and start < (SELECT max from UNNEST(limits) WHERE metric = "OL") ,onload_density,0) AS average_onload,

            IF(start <  (SELECT min from UNNEST(limits) WHERE metric = "FCP") ,fcp_density,0) AS good_fcp,
            IF(start >= (SELECT max from UNNEST(limits) WHERE metric = "FCP") ,fcp_density,0) AS poor_fcp,
            IF(start >= (SELECT min from UNNEST(limits) WHERE metric = "FCP") and start < (SELECT max from UNNEST(limits) WHERE metric = "FCP") ,fcp_density,0) AS average_fcp,

            IF(start <  (SELECT min from UNNEST(limits) WHERE metric = "DCL") ,dcl_density,0) AS good_dcl,
            IF(start >= (SELECT max from UNNEST(limits) WHERE metric = "DCL") ,dcl_density,0) AS poor_dcl,
            IF(start >= (SELECT min from UNNEST(limits) WHERE metric = "DCL") and start < (SELECT max from UNNEST(limits) WHERE metric = "DCL") ,dcl_density,0) AS average_dcl,

            IF(start <  (SELECT min from UNNEST(limits) WHERE metric = "FID") ,fid_density,0) AS good_fid,
            IF(start >= (SELECT max from UNNEST(limits) WHERE metric = "FID") ,fid_density,0) AS poor_fid,
            IF(start >= (SELECT min from UNNEST(limits) WHERE metric = "FID") and start < (SELECT max from UNNEST(limits) WHERE metric = "FID") ,fid_density,0) AS average_fid,

            IF(start <  (SELECT min from UNNEST(limits) WHERE metric = "CLS") ,cls_density,0) AS good_cls,
            IF(start >= (SELECT max from UNNEST(limits) WHERE metric = "CLS") ,cls_density,0) AS poor_cls,
            IF(start >= (SELECT min from UNNEST(limits) WHERE metric = "CLS") and start < (SELECT max from UNNEST(limits) WHERE metric = "CLS") ,cls_density,0) AS average_cls,

            IF(start <  (SELECT min from UNNEST(limits) WHERE metric = "TTFB") ,ttfb_density,0) AS good_ttfb,
            IF(start >= (SELECT max from UNNEST(limits) WHERE metric = "TTFB") ,ttfb_density,0) AS poor_ttfb,
            IF(start >= (SELECT min from UNNEST(limits) WHERE metric = "TTFB") and start < (SELECT max from UNNEST(limits) WHERE metric = "TTFB") ,ttfb_density,0) AS average_ttfb,

        FROM base_final, thresholds AS t
        """