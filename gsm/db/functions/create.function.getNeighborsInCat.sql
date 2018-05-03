--DROP FUNCTION getNeighborsInCat;

CREATE FUNCTION getNeighborsInCat(icatname VARCHAR(50)
                                 ,itheta DOUBLE
                                 ,icatsrcid INT
                                 ) RETURNS TABLE (catsrcid INT
                                                 ,distance_arcsec DOUBLE
                                                 )
BEGIN
  
  RETURN TABLE 
  (
    SELECT c2.catsrcid
          ,3600 * DEGREES(2 * ASIN(SQRT((c2.x - c1.x) * (c2.x - c1.x)
                                       + (c2.y - c1.y) * (c2.y - c1.y)
                                       + (c2.z - c1.z) * (c2.z - c1.z)
                                       ) / 2) 
                         ) AS distance_arcsec
      FROM catalogedsources c1
          ,catalogedsources c2
          ,catalogs c
     WHERE c1.catsrcid = icatsrcid
       AND c.catname = icatname
       AND c2.cat_id = c.catid
       AND c1.x * c2.x + c1.y * c2.y + c1.z * c2.z > COS(RADIANS(itheta))
       AND c1.zone BETWEEN CAST(FLOOR(c2.decl - itheta) AS INTEGER)
                       AND CAST(FLOOR(c2.decl + itheta) AS INTEGER)
       AND c1.ra BETWEEN c2.ra - sys.alpha(c2.decl, itheta)
                     AND c2.ra + sys.alpha(c2.decl, itheta)
       AND c1.decl BETWEEN c2.decl - itheta
                       AND c2.decl + itheta
    ORDER BY distance_arcsec
  )
  ;

END
;

