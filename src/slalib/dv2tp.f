      SUBROUTINE sla_DV2TP (V, V0, XI, ETA, J)
*+
*     - - - - - -
*      D V 2 T P
*     - - - - - -
*
*  Given the direction cosines of a star and of the tangent point,
*  determine the star's tangent-plane coordinates.
*
*  (double precision)
*
*  Given:
*     V         d(3)    direction cosines of star
*     V0        d(3)    direction cosines of tangent point
*
*  Returned:
*     XI,ETA    d       tangent plane coordinates of star
*     J         i       status:   0 = OK
*                                 1 = error, star too far from axis
*                                 2 = error, antistar on tangent plane
*                                 3 = error, antistar too far from axis
*
*  Notes:
*
*  1  If vector V0 is not of unit length, or if vector V is of zero
*     length, the results will be wrong.
*
*  2  If V0 points at a pole, the returned XI,ETA will be based on the
*     arbitrary assumption that the RA of the tangent point is zero.
*
*  3  This routine is the Cartesian equivalent of the routine sla_DS2TP.
*
*  P.T.Wallace   Starlink   27 November 1996
*
*  Copyright (C) 1996 Rutherford Appleton Laboratory
*-

      IMPLICIT NONE

      DOUBLE PRECISION V(3),V0(3),XI,ETA
      INTEGER J

      DOUBLE PRECISION X,Y,Z,X0,Y0,Z0,R2,R,W,D

      DOUBLE PRECISION TINY
      PARAMETER (TINY=1D-6)


      X=V(1)
      Y=V(2)
      Z=V(3)
      X0=V0(1)
      Y0=V0(2)
      Z0=V0(3)
      R2=X0*X0+Y0*Y0
      R=SQRT(R2)
      IF (R.EQ.0D0) THEN
         R=1D-20
         X0=R
      END IF
      W=X*X0+Y*Y0
      D=W+Z*Z0
      IF (D.GT.TINY) THEN
         J=0
      ELSE IF (D.GE.0D0) THEN
         J=1
         D=TINY
      ELSE IF (D.GT.-TINY) THEN
         J=2
         D=-TINY
      ELSE
         J=3
      END IF
      D=D*R
      XI=(Y*X0-X*Y0)/D
      ETA=(Z*R2-Z0*W)/D

      END
