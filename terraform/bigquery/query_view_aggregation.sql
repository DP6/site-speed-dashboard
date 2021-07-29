SELECT
    PARSE_DATE('%Y%m%d', FORMAT_DATETIME('%Y%m%d', data)) as data,
    name,
    count(distinct data) as ocorrencias
FROM
    ${table_name}
WHERE
    DATE(data) = DATE_SUB(CURRENT_DATE("America/Sao_Paulo"), INTERVAL 1 DAY)
GROUP BY
    name
