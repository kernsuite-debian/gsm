--DROP FUNCTION radians;

/**
 */
CREATE FUNCTION radians(d DOUBLE) RETURNS DOUBLE 
BEGIN
    RETURN d * PI() / 180;
END;