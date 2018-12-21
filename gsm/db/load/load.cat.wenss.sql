/*+-------------------------------------------------------------------+
 *| This script loads the external WENSS catalogue into the DB        |
 *| All WENSS data were subtracted from the csv file from the vizier  |
 *| website.The wenss-header.txt gives a description of the columns   |
 *| in the csv file.                                                  |
 *| The WENSS catalogue consists of two surveys:                      |
 *| (1) the main part, at 325 MHz, which contains the sources between |
 *|     28 < decl < 76                                                |
 *| (2) the polar part, at 352 MHz, which contains the sources with   |
 *|     decl > 72.                                                    |
 *| Therefore, we will create two separate WENSS catalogues, a main   |
 *| and polar part.                                                   |
 *+-------------------------------------------------------------------+
 *| Bart Scheers                                                      |
 *| 2011-02-16                                                        |
 *+-------------------------------------------------------------------+
 *| Open Questions/TODOs:                                             |
 *| (1) If we dump the default wenss data into a file, we can use that|
 *|     for even faster load.                                         |
 *+-------------------------------------------------------------------+
 *| Since Aug2018 the when statement in combination with a division   |
 *| causes an error in rel_optimizer.c:2755.                          |
 *| Until fix, we have a work-around. Note the rewrite of 1/sin^2 x as|
 *| 1 + cot^2 x and that the sqrt and a_I^2 division are now outside  |
 *| the when statement.                                               |
 *+-------------------------------------------------------------------+
 */
DECLARE icatid_main, icatid_pole INT;
DECLARE ifreq_eff_main, ifreq_eff_pole DOUBLE;
DECLARE iband_main, iband_pole INT;

/*see Rengelink et al.(1997) Eq.9*/
DECLARE C1_sq, C2_sq DOUBLE;
SET C1_sq = 0.0016;
SET C2_sq = 1.69;

SET icatid_main = 5;
SET icatid_pole = 6;

INSERT INTO catalogs
  (catid
  ,catname
  ,fullname
  ) VALUES 
  (icatid_main
  ,'WENSSm'
  ,'WEsterbork Nortern Sky Survey, Main Catalogue @ 325 MHz'
  )
  ,
  (icatid_pole
  ,'WENSSp'
  ,'WEsterbork Nortern Sky Survey, Polar Catalogue @ 352 MHz'
  )
;

SET ifreq_eff_main = 325000000.0;
/*SET iband_main = getBand(ifreq_eff_main, 10000000.0);*/
SET iband_main = getBand(ifreq_eff_main);
SET ifreq_eff_pole = 352000000.0;
/*SET iband_pole = getBand(ifreq_eff_pole, 10000000.0);*/
SET iband_pole = getBand(ifreq_eff_pole);


/*DROP TABLE aux_catalogedsources;*/

CREATE TABLE aux_catalogedsources
  (aviz_RAJ2000 DOUBLE
  ,aviz_DEJ2000 DOUBLE
  ,aorig_catsrcid INT
  ,aname VARCHAR(16)
  ,af_name VARCHAR(8)
  ,awsrt_RAB1950 VARCHAR(12)
  ,awsrt_DEB1950 VARCHAR(12)
  ,adummy1 VARCHAR(20)
  ,adummy2 VARCHAR(20)
  ,aflg1 VARCHAR(2)
  ,aflg2 VARCHAR(1)
  ,a_I DOUBLE
  ,a_S DOUBLE
  ,amajor DOUBLE
  ,aminor DOUBLE
  ,aPA DOUBLE
  ,arms DOUBLE
  ,aframe VARCHAR(20)
  )
;

COPY 229420 RECORDS 
INTO aux_catalogedsources 
FROM
/* Set absolute path to csv file */
'/path/to/wenss.csv'
USING DELIMITERS ';', '\n' 
;

INSERT INTO catalogedsources
  (orig_catsrcid
  ,catsrcname
  ,cat_id
  ,band
  ,ra
  ,decl
  ,zone
  ,ra_err
  ,decl_err
  ,freq_eff
  ,x
  ,y
  ,z
  ,src_type
  ,fit_probl
  ,pa
  ,major
  ,minor
  ,i_peak_avg
  ,i_peak_avg_err
  ,i_int_avg
  ,i_int_avg_err
  ,frame
  )
  SELECT orig_catsrcid
        ,catsrcname
        ,cat_id
        ,band
        ,ra
        ,decl
        ,zone
        ,SQRT(t.ra_err_inter / (t.a_I * t.a_I)) AS ra_err
        ,SQRT(t.decl_err_inter / (t.a_I * t.a_I)) AS decl_err
        ,freq_eff
        ,x
        ,y
        ,z
        ,src_type
        ,fit_probl
        ,pa
        ,major
        ,minor
        ,i_peak_avg
        ,i_peak_avg_err
        ,i_int_avg
        ,i_int_avg_err
        ,frame
    FROM (
  SELECT aorig_catsrcid AS orig_catsrcid
        ,CONCAT(TRIM(aname), af_name) AS catsrcname
        ,CASE WHEN aframe LIKE 'WNH%'
              THEN icatid_main
              ELSE icatid_pole
         END AS cat_id
        ,CASE WHEN aframe LIKE 'WNH%'
              THEN iband_main
              ELSE iband_pole
         END AS band
        ,aviz_RAJ2000 AS ra
        ,aviz_DEJ2000 AS decl
        ,CAST(FLOOR(aviz_DEJ2000) AS INTEGER) AS zone
        ,CASE WHEN a_I >= 10 * arms
                THEN 1.5 * a_I * a_I
              WHEN amajor <> 0
                THEN 2.25 + 0.592 * arms * arms * ( amajor * amajor * SIN(RADIANS(apa)) * SIN(RADIANS(apa))
                                                  + aminor * aminor * COS(RADIANS(apa)) * COS(RADIANS(apa)))
              ELSE 2.25 + arms * arms * 1725
         END AS ra_err_inter
        ,CASE WHEN a_I >= 10 * arms
                THEN 1.5 * a_I * a_I
              WHEN amajor <> 0
                THEN 2.25 + 0.592 * arms * arms * ( amajor * amajor * COS(RADIANS(apa)) * COS(RADIANS(apa))
                                                  + aminor * aminor * SIN(RADIANS(apa)) * SIN(RADIANS(apa)))
              ELSE 2.25 + arms * arms * 1725 * (1 + COT(RADIANS(aviz_DEJ2000)) * COT(RADIANS(aviz_DEJ2000)))
         END AS decl_err_inter
        ,CASE WHEN aframe LIKE 'WNH%'
              THEN ifreq_eff_main
              ELSE ifreq_eff_pole
         END AS freq_eff
        ,COS(RADIANS(aviz_DEJ2000)) * COS(RADIANS(aviz_RAJ2000)) AS x
        ,COS(RADIANS(aviz_DEJ2000)) * SIN(RADIANS(aviz_RAJ2000)) AS y
        ,SIN(RADIANS(aviz_DEJ2000)) AS z
        ,aflg1 AS src_type
        ,CASE WHEN aflg2 = '*'
              THEN aflg2
              ELSE NULL
         END AS fit_probl
        ,apa AS pa
        ,amajor AS major
        ,aminor AS minor
        ,a_I / 1000 AS i_peak_avg
        ,SQRT(C1_sq + C2_sq * (arms / a_I) * (arms / a_I)) * a_I / 1000 AS i_peak_avg_err
        ,a_S / 1000 AS i_int_avg
        ,SQRT(C1_sq + C2_sq * (arms / a_S) * (arms / a_S)) * a_S / 1000 AS i_int_avg_err
        ,aframe AS frame
        ,a_I
    FROM aux_catalogedsources
   WHERE a_S > 0
   ) t
;

DROP TABLE aux_catalogedsources;

