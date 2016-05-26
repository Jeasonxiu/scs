!==============================================================================
!
!  ydaz_func        Written by Chuck Wicks, modified 6/27/07,  It is a 
!                   non-interactive function that returns the epicentral 
!                   distance "dist" in variable (for ellipsoidal earth) along 
!                   with the azimuth in variabel "az" (receiver to  source) 
!                   and backazimuth in variable "baz" (source to receiver).
!                   This is the seismic handler convention; most will want to
!                   reverse az and baz.
!                   The latitutde/longitude of the receiver (variable vector 
!                   lat1,lon1) and source (variable vector lat2,lon2) are fed 
!                   in the form:[18.9,145.2] for each, with East and North 
!                   positive.
!
!                   F90 by Nick Schmerr 6/27/07
!
!                   Variable tol is set to prevent irregularity at poles
!
!                   KIND_TYPE=8 is double precision in g95
!                   use the flag -kind=byte for f95 NagWare
!==============================================================================

          subroutine ydaz_func(lat1,lon1,lat2,lon2,dist,az,baz)


!         INTEGER k=8
!  REAL(KIND=k),PARAMETER :: ecc=1_k/297.0_k         ! International 1924 Ellipsoid
!  REAL(KIND=k),PARAMETER :: re=6378.388             ! International 1924 Ellipsoid
          REAL ecc
          REAL re
          REAL pi
          REAL tol

  ! Input/Output
          REAL lat1,lon1,lat2,lon2 ! 2 points on sphere
          REAL  dist,az,baz           ! Great circle distance,azimuth,back-azimuth

  ! Program variables
          REAL ec1,pib2,degr
          REAL lats,lons,latr,lonr
          REAL glats,glatr,sps,cps,spr,cpr
          REAL rs,rr,trs,prs,trr,prr
          REAL AS,BS,CS,DS,ES,GS,HS,KS
          REAL AR,BR,CR,DR,ER,GR,HR,KR
          REAL cosdr,deltar,epi_d,deltak,delta
          REAL szs,czs,szr,czr
          REAL azim,azima,bazim,cazim

          ecc=1/298.257223563 ! WGS 1984
           re=6378.137             ! WGS 1984
           pi=3.141592653589793  ! Pi
           tol= 0.0000010        ! Stabilizes values at poles

  ! Eccentricity
          ec1=(1.0-ecc)**2
          pib2=pi/2.0
          degr=pi/180.0

          ! Adjust for tol (rough fix)
          lats=(lat1+tol)*degr
          lons=(lon1+tol)*degr
          latr=(lat2-tol)*degr
          lonr=(lon2-tol)*degr
          !---Geocentric coordinates:
          glats=ATAN2(ec1*SIN(lats),COS(lats))
          glatr=ATAN2(ec1*SIN(latr),COS(latr))
          sps=SIN(glats)**2
          cps=COS(glats)**2
          spr=SIN(glatr)**2
          cpr=COS(glatr)**2

          !---radii at source, receiver sqrt((1.0-ecc)^2/((1.0-ecc*cps)^2+ecc*ecc*cps))
          rs=re*SQRT((1.0-ecc)**2/((1.0-ecc*cps)**2+ecc*ecc*cps))
          rr=re*SQRT((1.0-ecc)**2/((1.0-ecc*cpr)**2+ecc*ecc*cpr))

          trs=pib2-glats
          prs=lons
          trr=pib2-glatr
          prr=lonr
          !---direction cosines for source
          AS=     SIN(trs)*COS(prs)
          BS=     SIN(trs)*SIN(prs)
          CS=     COS(trs)
          DS=     SIN(prs)
          ES=-1*COS(prs)
          GS=   COS(trs)*COS(prs)
          HS=     COS(trs)*SIN(prs)
          KS=-1*SIN(trs)


          !---direction cosines for receiver
          AR=     SIN(trr)*COS(prr)
          BR=     SIN(trr)*SIN(prr)
          CR=     COS(trr)
          DR=     SIN(prr)
          ER=-1*COS(prr)
          GR=     COS(trr)*COS(prr)
          HR=     COS(trr)*SIN(prr)
          KR=-1*SIN(trr)

          !---distance:
          cosdr=AS*AR + BS*BR + CS*CR
          deltar=ACOS(cosdr)
          epi_d=deltar/degr

          deltak=deltar*0.50*(rr+rs)
          delta=deltar/degr

          szs=DS*AR + ES*BR
          czs=GS*AR + HS*BR + KS*CR
          szr=DR*AS + ER*BS
          czr=GR*AS + HR*BS + KR*CS
          !---azima is azimuth to source
          !---bazim is backazimuth from source
          !---cazim is azimuth of wavefront at array
          IF (NINT(szr*100000000) == 0) THEN
             azim=0.0
             azima=180.0
          ELSE
             bazim=ATAN2(-1*szs,-1*czs)/degr
             azima=ATAN2(-1*szr,-1*czr)/degr
          endif

          IF (bazim <= 0.0) THEN
             bazim=bazim+360.0
          endif

          IF (azima <= 0.0) THEN
             azima=azima+360.0
          endif

          cazim=azima+180.0

          IF (cazim >= 360.0) THEN
             cazim=cazim-360.0
          ELSE IF (cazim < 0.0) THEN
             cazim=cazim+360.0
          endif

          dist = epi_d
          az   = azima
          baz  = bazim


        END

