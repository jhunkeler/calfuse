      SUBROUTINE sla_DC62S (V, A, B, R, AD, BD, RD)
*+
*     - - - - - -
*      D C 6 2 S
*     - - - - - -
*
*  Conversion of position & velocity in Cartesian coordinates
*  to spherical coordinates (double precision)
*
*  Given:
*     V      d(6)   Cartesian position & velocity vector
*
*  Returned:
*     A      d      longitude (radians)
*     B      d      latitude (radians)
*     R      d      radial coordinate
*     AD     d      longitude derivative (radians per unit time)
*     BD     d      latitude derivative (radians per unit time)
*     RD     d      radial derivative
*
*  P.T.Wallace   Starlink   28 April 1996
*
*  Copyright (C) 1996 Rutherford Appleton Laboratory
*-

      IMPLICIT NONE

      DOUBLE PRECISION V(6),A,B,R,AD,BD,RD

      DOUBLE PRECISION X,Y,Z,XD,YD,ZD,RXY2,RXY,R2,XYP



*  Components of position/velocity vector
      X=V(1)
      Y=V(2)
      Z=V(3)
      XD=V(4)
      YD=V(5)
      ZD=V(6)

*  Component of R in XY plane squared
      RXY2=X*X+Y*Y

*  Modulus squared
      R2=RXY2+Z*Z

*  Protection against null vector
      IF (R2.EQ.0D0) THEN
         X=XD
         Y=YD
         Z=ZD
         RXY2=X*X+Y*Y
         R2=RXY2+Z*Z
      END IF

*  Position and velocity in spherical coordinates
      RXY=SQRT(RXY2)
      XYP=X*XD+Y*YD
      IF (RXY2.NE.0D0) THEN
         A=ATAN2(Y,X)
         B=ATAN2(Z,RXY)
         AD=(X*YD-Y*XD)/RXY2
         BD=(ZD*RXY2-Z*XYP)/(R2*RXY)
      ELSE
         A=0D0
         IF (Z.NE.0D0) THEN
            B=ATAN2(Z,RXY)
         ELSE
            B=0D0
         END IF
         AD=0D0
         BD=0D0
      END IF
      R=SQRT(R2)
      IF (R.NE.0D0) THEN
         RD=(XYP+Z*ZD)/R
      ELSE
         RD=0D0
      END IF

      END