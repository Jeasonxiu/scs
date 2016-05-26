SUBROUTINE tomo_smooth(grid,grid_sample,num_layer,npts_lat,npts_lon,lat_step,lon_step,newgrid)

! only do smoothing within a same depth layer
! Searching 10 degree radius surrouding the central location with poor sampling 

IMPLICIT NONE
! INPUT AND OUTPUT for this subroutine
INTEGER, INTENT(IN) :: num_layer,npts_lat,npts_lon
REAL, INTENT(IN) :: lon_step,lat_step
REAL, INTENT(IN), DIMENSION(num_layer,npts_lat,npts_lon) :: grid,grid_sample
REAL, DIMENSION(num_layer,npts_lat,npts_lon) :: grid_sample_local
REAL, INTENT(OUT), DIMENSION(num_layer,npts_lat,npts_lon) :: newgrid

REAL :: dist_tmp,az_tmp,baz_tmp,lat_tmp,lon_tmp,lat_center,lon_center,gweight
REAL :: radius,grid_sum_tmp,gweight_sum_tmp,real_tmp,count_weight
INTEGER :: lon_up,lon_low,lat_up,lat_low,sample_tmp
INTEGER :: status_read,status_alloc

INTEGER :: idep,ilat,ilon,nilat,nilon,j,k,l,m,n,iradius,new_ilat,new_ilon
INTEGER :: num_sample_satisfy

num_sample_satisfy=150
!=============================================================================
!    Smooth poorly sampled grid with adjacent cells 
!=============================================================================
newgrid=grid
lat_center=0.0
lon_center=0.0
grid_sample_local=grid_sample
DO idep=1,num_layer
  DO ilat=1,npts_lat
   DO ilon=1,npts_lon
     IF(grid_sample_local(idep,ilat,ilon)>=num_sample_satisfy)grid_sample_local(idep,ilat,ilon)=num_sample_satisfy
     IF(grid_sample_local(idep,ilat,ilon)<=num_sample_satisfy .AND. grid_sample_local(idep,ilat,ilon) > 0 ) THEN
      ! If the number of sample of this point is less than 10, search around it until sample sum is 10
      ! then smooth this point by gassian weight
        ! write(*,*)idep,ilat,ilon,grid_sample(idep,ilat,ilon)
        DO iradius=2,6,2
          sample_tmp=0.0
          grid_sum_tmp=0.0 
          gweight_sum_tmp=0.0 
           DO nilat=-iradius,iradius
            DO nilon=-iradius,iradius

              ! Band the latitude
              new_ilat=ilat+nilat 
               IF(new_ilat <= 0)new_ilat=1
               IF(new_ilat > npts_lat)new_ilat=npts_lat
              ! Wrap the longitude
              new_ilon=ilon+nilon
               IF(new_ilon <= 0 )new_ilon=npts_lon-new_ilon
               IF(new_ilon > npts_lon )new_ilon=new_ilon-npts_lon

              lat_tmp=lat_center+lat_step*nilat
              lon_tmp=lon_center+lon_step*nilon
            
              call ydaz_func(lat_center,lon_center,lat_tmp,lon_tmp,dist_tmp,az_tmp,baz_tmp)
               radius=real(iradius)
              IF(dist_tmp<=iradius) THEN
              call GAUSSIAN(dist_tmp,radius,gweight) 
                IF(grid_sample_local(idep,new_ilat,new_ilon)>=num_sample_satisfy)&
grid_sample_local(idep,new_ilat,new_ilon)=num_sample_satisfy
                IF(grid_sample_local(idep,new_ilat,new_ilon)>0) THEN
                  count_weight=grid_sample_local(idep,new_ilat,new_ilon)
                ELSE
                  count_weight=1
                ENDIF
                
                gweight_sum_tmp=gweight_sum_tmp+gweight*count_weight
                grid_sum_tmp=grid_sum_tmp+gweight*grid(idep,new_ilat,new_ilon)*count_weight
                sample_tmp=sample_tmp+grid_sample_local(idep,new_ilat,new_ilon)
              ENDIF
            END DO ! end of nilat
           END DO ! end of nilon
          IF(sample_tmp>=num_sample_satisfy)EXIT 
        END DO ! end of iradius
      real_tmp=newgrid(idep,ilat,ilon)
      newgrid(idep,ilat,ilon)=grid_sum_tmp/gweight_sum_tmp
      !write(*,*)newgrid(idep,ilat,ilon),real_tmp
     ENDIF ! endif of if (grid_sample)

   END DO ! end of ilon loop
  END DO ! end of ilat loop
END DO ! end of idep loop
END SUBROUTINE tomo_smooth

!%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
!          SUBROUTINE ZONE
!%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SUBROUTINE GAUSSIAN(dist,distbinsize,weight)
REAL :: dist,distbinsize,weight,FWHM,delta
FWHM=distbinsize
delta=FWHM/2.35482
weight=exp((-0.5)*(dist/delta)**2)
END SUBROUTINE GAUSSIAN

