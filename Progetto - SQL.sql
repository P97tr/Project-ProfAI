/* PROGETTO ANALISI CLIENTI DI UNA BANCA - Patric Scipione
Creare una tabella denormalizzata che contenga indicatori comportamentali sul cliente, calcolati sulla base delle transazioni e del possesso prodotti. 
Lo scopo è creare le feature per un possibile modello di machine learning supervisionato.

Ogni indicatore va riferito al singolo id_cliente:
1-Età
2-Numero di transazioni in uscita su tutti i conti
3-Numero di transazioni in entrata su tutti i conti
4-Importo transato in uscita su tutti i conti
5-Importo transato in entrata su tutti i conti
6-Numero totale di conti posseduti
7-Numero di conti posseduti per tipologia (un indicatore per tipo)
8-Numero di transazioni in uscita per tipologia (un indicatore per tipo)
9-Numero di transazioni in entrata per tipologia (un indicatore per tipo)
10-Importo transato in uscita per tipologia di conto (un indicatore per tipo)
11-Importo transato in entrata per tipologia di conto (un indicatore per tipo)
*/
SHOW DATABASES;
SELECT USER();
GRANT CREATE TEMPORARY TABLES ON banca.* TO 'root'@'localhost';
FLUSH PRIVILEGES;

use banca;

-- 1-calcolo dell'età
CREATE TEMPORARY TABLE temp_eta_cliente AS
select *, 
year(current_date()) - year(data_nascita) as eta_cliente
from banca.cliente;

SELECT * FROM temp_eta_cliente;

-- 2-numero transazioni in uscita su tutti i conti 
-- 8-Numero di transazioni in uscita per tipologia (un indicatore per tipo)
CREATE TEMPORARY TABLE temp_transazioni_uscita AS
SELECT cl.id_cliente,
       COALESCE(SUM(CASE WHEN t.id_tipo_trans = 3 THEN 1 ELSE 0 END), 0) AS acquisto_amazon,
       COALESCE(SUM(CASE WHEN t.id_tipo_trans = 4 THEN 1 ELSE 0 END), 0) AS rata_mutuo,
       COALESCE(SUM(CASE WHEN t.id_tipo_trans = 5 THEN 1 ELSE 0 END), 0) AS hotel,
       COALESCE(SUM(CASE WHEN t.id_tipo_trans = 6 THEN 1 ELSE 0 END), 0) AS biglietto_aereo,
       COALESCE(SUM(CASE WHEN t.id_tipo_trans = 7 THEN 1 ELSE 0 END), 0) AS supermercato,
       COALESCE(SUM(CASE WHEN t.id_tipo_trans IN (3,4,5,6,7) THEN 1 ELSE 0 END), 0) AS totale_uscite
FROM banca.cliente cl
LEFT JOIN banca.conto c ON cl.id_cliente = c.id_cliente
LEFT JOIN banca.transazioni t ON c.id_conto = t.id_conto
GROUP BY cl.id_cliente
ORDER BY cl.id_cliente ASC;

SELECT * FROM temp_transazioni_uscita;

-- 3-numero transazioni in entrata su tutti i conti 
-- 9-Numero di transazioni in entrata per tipologia (un indicatore per tipo)
CREATE TEMPORARY TABLE temp_transazioni_entrata AS
SELECT cl.id_cliente,
       COALESCE(SUM(CASE WHEN t.id_tipo_trans = 0 THEN 1 ELSE 0 END), 0) AS stipendio,
       COALESCE(SUM(CASE WHEN t.id_tipo_trans = 1 THEN 1 ELSE 0 END), 0) AS pensione,
       COALESCE(SUM(CASE WHEN t.id_tipo_trans = 2 THEN 1 ELSE 0 END), 0) AS dividendi,
       COALESCE(SUM(CASE WHEN t.id_tipo_trans IN (0,1,2) THEN 1 ELSE 0 END), 0) AS totale_entrate
FROM banca.cliente cl
LEFT JOIN banca.conto c ON cl.id_cliente = c.id_cliente
LEFT JOIN banca.transazioni t ON c.id_conto = t.id_conto
GROUP BY cl.id_cliente
ORDER BY cl.id_cliente ASC;

SELECT * FROM temp_transazioni_entrata;

-- 4-Importo transato in uscita su tutti i conti
CREATE TEMPORARY TABLE temp_transazioni_uscita_importo AS
SELECT cl.id_cliente,
       ROUND(COALESCE(SUM(CASE WHEN t.id_tipo_trans = 3 THEN t.importo ELSE 0 END), 0), 2) AS acquisto_amazon,
       ROUND(COALESCE(SUM(CASE WHEN t.id_tipo_trans = 4 THEN t.importo ELSE 0 END), 0), 2) AS rata_mutuo,
       ROUND(COALESCE(SUM(CASE WHEN t.id_tipo_trans = 5 THEN t.importo ELSE 0 END), 0), 2) AS hotel,
       ROUND(COALESCE(SUM(CASE WHEN t.id_tipo_trans = 6 THEN t.importo ELSE 0 END), 0), 2) AS biglietto_aereo,
       ROUND(COALESCE(SUM(CASE WHEN t.id_tipo_trans = 7 THEN t.importo ELSE 0 END), 0), 2) AS supermercato,
       ROUND(COALESCE(SUM(CASE WHEN t.id_tipo_trans IN (3,4,5,6,7) AND t.importo < 0 THEN t.importo ELSE 0 END), 0), 2) AS totale_uscite
FROM banca.cliente cl
LEFT JOIN banca.conto c ON cl.id_cliente = c.id_cliente
LEFT JOIN banca.transazioni t ON c.id_conto = t.id_conto
GROUP BY cl.id_cliente
ORDER BY cl.id_cliente ASC;

SELECT * FROM temp_transazioni_uscita_importo;

-- 5-Importo transato in entrata su tutti i conti
CREATE TEMPORARY TABLE temp_transazioni_entrata_importo AS
SELECT cl.id_cliente,
       ROUND(COALESCE(SUM(CASE WHEN t.id_tipo_trans = 0 THEN t.importo ELSE 0 END), 0), 2) AS stipendio,
       ROUND(COALESCE(SUM(CASE WHEN t.id_tipo_trans = 1 THEN t.importo ELSE 0 END), 0), 2) AS pensione,
       ROUND(COALESCE(SUM(CASE WHEN t.id_tipo_trans = 2 THEN t.importo ELSE 0 END), 0), 2) AS dividendi,
       ROUND(COALESCE(SUM(CASE WHEN t.id_tipo_trans IN (0,1,2) AND t.importo > 0 THEN t.importo ELSE 0 END), 0), 2) AS totale_entrate
FROM banca.cliente cl
LEFT JOIN banca.conto c ON cl.id_cliente = c.id_cliente
LEFT JOIN banca.transazioni t ON c.id_conto = t.id_conto
GROUP BY cl.id_cliente
ORDER BY cl.id_cliente ASC;

SELECT * FROM temp_transazioni_entrata_importo;

-- 6-Numero totale di conti posseduti
-- 7-Numero di conti posseduti per tipologia (un indicatore per tipo)
CREATE TEMPORARY TABLE temp_tipo_conto AS
SELECT cl.id_cliente,
       COALESCE(SUM(CASE WHEN c.id_tipo_conto = 0 THEN 1 ELSE 0 END), 0) AS conto_base,
       COALESCE(SUM(CASE WHEN c.id_tipo_conto = 1 THEN 1 ELSE 0 END), 0) AS conto_business,
       COALESCE(SUM(CASE WHEN c.id_tipo_conto = 2 THEN 1 ELSE 0 END), 0) AS conto_privati, 
       COALESCE(SUM(CASE WHEN c.id_tipo_conto = 3 THEN 1 ELSE 0 END), 0) AS conto_famiglie,
       COALESCE(COUNT(c.id_conto), 0) AS totale_conti
FROM banca.cliente cl
LEFT JOIN banca.conto c ON cl.id_cliente = c.id_cliente
GROUP BY cl.id_cliente
ORDER BY cl.id_cliente ASC;

SELECT * FROM temp_tipo_conto;

-- 10-Importo transato in uscita per tipologia di conto (un indicatore per tipo)
CREATE TEMPORARY TABLE temp_importo_uscita_per_cliente_tipo_conto AS
SELECT 
    cl.id_cliente,
    ROUND(SUM(CASE WHEN co.id_tipo_conto = 0 AND tr.importo IS NOT NULL THEN tr.importo ELSE 0 END), 2) AS conto_base,
    ROUND(SUM(CASE WHEN co.id_tipo_conto = 1 AND tr.importo IS NOT NULL THEN tr.importo ELSE 0 END), 2) AS conto_business,
    ROUND(SUM(CASE WHEN co.id_tipo_conto = 2 AND tr.importo IS NOT NULL THEN tr.importo ELSE 0 END), 2) AS conto_privati,
    ROUND(SUM(CASE WHEN co.id_tipo_conto = 3 AND tr.importo IS NOT NULL THEN tr.importo ELSE 0 END), 2) AS conto_famiglie,
    ROUND(SUM(CASE WHEN co.id_tipo_conto IN (0, 1, 2, 3) AND tr.importo IS NOT NULL THEN tr.importo ELSE 0 END), 2) AS totale_uscite_conti
FROM banca.cliente cl
LEFT JOIN banca.conto co ON cl.id_cliente = co.id_cliente
LEFT JOIN banca.transazioni tr ON co.id_conto = tr.id_conto AND tr.id_tipo_trans IN (3, 4, 5, 6, 7)
GROUP BY cl.id_cliente
ORDER BY cl.id_cliente ASC;    
    
SELECT * FROM temp_importo_uscita_per_cliente_tipo_conto;

-- 11-Importo transato in entrata per tipologia di conto (un indicatore per tipo)
CREATE TEMPORARY TABLE temp_importo_entrate_per_cliente_tipo_conto AS
SELECT 
    cl.id_cliente,
    ROUND(SUM(CASE WHEN co.id_tipo_conto = 0 AND tr.id_tipo_trans IN (0, 1, 2) AND tr.importo IS NOT NULL THEN tr.importo ELSE 0 END), 2) AS conto_base,
    ROUND(SUM(CASE WHEN co.id_tipo_conto = 1 AND tr.id_tipo_trans IN (0, 1, 2) AND tr.importo IS NOT NULL THEN tr.importo ELSE 0 END), 2) AS conto_business,
    ROUND(SUM(CASE WHEN co.id_tipo_conto = 2 AND tr.id_tipo_trans IN (0, 1, 2) AND tr.importo IS NOT NULL THEN tr.importo ELSE 0 END), 2) AS conto_privati,
    ROUND(SUM(CASE WHEN co.id_tipo_conto = 3 AND tr.id_tipo_trans IN (0, 1, 2) AND tr.importo IS NOT NULL THEN tr.importo ELSE 0 END), 2) AS conto_famiglie,
    ROUND(SUM(CASE WHEN co.id_tipo_conto IN (0, 1, 2, 3) AND tr.id_tipo_trans IN (0, 1, 2) AND tr.importo IS NOT NULL THEN tr.importo ELSE 0 END), 2) AS totale_entrate_conti
FROM banca.cliente cl
LEFT JOIN banca.conto co ON cl.id_cliente = co.id_cliente
LEFT JOIN banca.transazioni tr ON co.id_conto = tr.id_conto
GROUP BY cl.id_cliente
ORDER BY cl.id_cliente ASC;  
    
SELECT * FROM temp_importo_entrate_per_cliente_tipo_conto;

-- Creazione della tabella temporanea completa
CREATE TEMPORARY TABLE temp_unione AS
SELECT 
    e.id_cliente,
    e.eta_cliente,
    tu.acquisto_amazon AS num_acquisto_amazon,
    tu.rata_mutuo AS num_rata_mutuo,
    tu.hotel AS num_hotel,
    tu.biglietto_aereo AS num_biglietto_aereo,
    tu.supermercato AS num_supermercato,
    tu.totale_uscite AS num_totale_uscite,
    te.stipendio AS num_stipendio,
    te.pensione AS num_pensione,
    te.dividendi AS num_dividendi,
    te.totale_entrate AS num_totale_entrate,
    tui.acquisto_amazon AS importo_acquisto_amazon,
    tui.rata_mutuo AS importo_rata_mutuo,
    tui.hotel AS importo_hotel,
    tui.biglietto_aereo AS importo_biglietto_aereo,
    tui.supermercato AS importo_supermercato,
    tui.totale_uscite AS importo_totale_uscite,
    tei.stipendio AS importo_stipendio,
    tei.pensione AS importo_pensione,
    tei.dividendi AS importo_dividendi,
    tei.totale_entrate AS importo_totale_entrate,
    tc.conto_base AS num_conto_base,
    tc.conto_business AS num_conto_business,
    tc.conto_privati AS num_conto_privati,
    tc.conto_famiglie AS num_conto_famiglie,
    tc.totale_conti,
    iuc.conto_base AS importo_conto_base_uscite,
    iuc.conto_business AS importo_conto_business_uscite,
    iuc.conto_privati AS importo_conto_privati_uscite,
    iuc.conto_famiglie AS importo_conto_famiglie_uscite,
    iuc.totale_uscite_conti,
    iec.conto_base AS importo_conto_base_entrate,
    iec.conto_business AS importo_conto_business_entrate,
    iec.conto_privati AS importo_conto_privati_entrate,
    iec.conto_famiglie AS importo_conto_famiglie_entrate,
    iec.totale_entrate_conti
FROM 
    temp_eta_cliente e
LEFT JOIN 
    temp_transazioni_uscita tu ON e.id_cliente = tu.id_cliente
LEFT JOIN 
    temp_transazioni_entrata te ON e.id_cliente = te.id_cliente
LEFT JOIN 
    temp_transazioni_uscita_importo tui ON e.id_cliente = tui.id_cliente
LEFT JOIN 
    temp_transazioni_entrata_importo tei ON e.id_cliente = tei.id_cliente
LEFT JOIN 
    temp_tipo_conto tc ON e.id_cliente = tc.id_cliente
LEFT JOIN 
    temp_importo_uscita_per_cliente_tipo_conto iuc ON e.id_cliente = iuc.id_cliente
LEFT JOIN 
    temp_importo_entrate_per_cliente_tipo_conto iec ON e.id_cliente = iec.id_cliente
ORDER BY 
    e.id_cliente ASC;

SELECT * FROM temp_unione;

