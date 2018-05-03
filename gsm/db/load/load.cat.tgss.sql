DECLARE icatid INT;
DECLARE i_freq_eff DOUBLE;
DECLARE iband INT;
SET icatid = 7;

INSERT INTO catalogs
  (catid
  ,catname
  ,fullname
  ) 
VALUES 
  (icatid
  ,'TGSS'
  ,'The Alternative Data Release of the TGSS 150MHz, The TGSS Catalog, Version 2016-03-16'
  )
;

SET i_freq_eff = 147500000.0; 
/*SET iband = getBand(i_freq_eff, 2000000);*/
SET iband = getBand(i_freq_eff);

CREATE TABLE aux_catalogedsources
  (aorig_catsrcid INT 
  ,aname VARCHAR(25)
  ,aRAJ2000 DOUBLE
  ,ae_RAJ2000 DOUBLE
  ,aDEJ2000 DOUBLE
  ,ae_DEJ2000 DOUBLE
  ,aSi DOUBLE
  ,ae_Si DOUBLE
  ,aSp DOUBLE
  ,ae_Sp DOUBLE
  ,aMajAx DOUBLE
  ,ae_MajAx DOUBLE
  ,aMinAx DOUBLE
  ,ae_MinAx DOUBLE
  ,aPA DOUBLE
  ,ae_PA DOUBLE
  ,aRMSnoise DOUBLE
  ,aSourceCode VARCHAR(1)
  ,aField VARCHAR(6)
  )
;

COPY 623604 OFFSET 4 RECORDS
INTO aux_catalogedsources
FROM
/* Set absolute path to csv file */
'/path/to/tgss.csv'
USING DELIMITERS ';', '\n'
NULL AS ''
;

/* So we can put our FoV conditions in here...*/
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
  ,pa
  ,pa_err
  ,major
  ,major_err
  ,minor
  ,minor_err
  ,i_int_avg
  ,i_int_avg_err
  ,i_peak_avg
  ,i_peak_avg_err
  ,frame
  )
  SELECT aorig_catsrcid
        ,TRIM(aname)
        ,icatid
        ,iband
        ,aRAJ2000
        ,aDEJ2000
        ,CAST(FLOOR(aDEJ2000) AS INTEGER)
        ,15 * ae_RAJ2000 * COS(RADIANS(aDEJ2000))
        ,ae_DEJ2000 
        ,i_freq_eff
        ,COS(RADIANS(aDEJ2000)) * COS(RADIANS(aRAJ2000))
        ,COS(RADIANS(aDEJ2000)) * SIN(RADIANS(aRAJ2000))
        ,SIN(RADIANS(aDEJ2000))
        ,aPA
        ,ae_PA
        ,aMajAx
        ,ae_MajAx
        ,aMinAx
        ,ae_MinAx
        ,aSi / 1000
        ,ae_Si / 1000
        ,aSp / 1000
        ,ae_Sp / 1000
        ,aField
    FROM aux_catalogedsources
  ;

DROP TABLE aux_catalogedsources;

