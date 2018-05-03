DROP FUNCTION getNeighborsInCats;

CREATE FUNCTION getNeighborsInCats(itheta DOUBLE
                                  ,icatsrcid INT
                                  ) RETURNS TABLE (catname STRING
                                                  ,catsrcid INT
                                                  ,distance_arcsec DOUBLE
                                                  )
BEGIN
  
  RETURN TABLE 
  (
    /*SELECT catname
          ,catsrcid
          ,0 AS distance_arcsec
      FROM catalogedsources 
          ,catalogs
     WHERE cat_id = catid
    UNION*/
    SELECT c.catname
          ,c2.catsrcid
          ,3600 * DEGREES(2 * ASIN(SQRT((c2.x - c1.x) * (c2.x - c1.x)
                                       + (c2.y - c1.y) * (c2.y - c1.y)
                                       + (c2.z - c1.z) * (c2.z - c1.z)
                                       ) / 2) 
                         ) AS distance_arcsec
      FROM catalogedsources c1
          ,catalogedsources c2
          ,catalogs c
     WHERE c1.catsrcid = icatsrcid
       AND c1.cat_id <> c2.cat_id
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

