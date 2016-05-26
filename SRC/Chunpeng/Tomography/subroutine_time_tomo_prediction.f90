SUBROUTINE time_tomo_prediction(newgrid,gridlat_start,gridlon_start,&
num_layer,layerdep,npts_lat,npts_lon,lat_step,lon_step,pathlat,pathlon,pathdep,&
npts_path,depth_cutmin,depth_cutmax,dt_relative)

IMPLICIT NONE
INTEGER, PARAMETER :: prem_maxp=100000
! INPUT AND OUTPUT for this subroutine
INTEGER, INTENT(IN) :: num_layer,npts_lat,npts_lon,npts_path
REAL, INTENT(IN) :: depth_cutmin,depth_cutmax,lon_step,lat_step
REAL, INTENT(OUT) :: dt_relative
REAL, INTENT(IN), DIMENSION(num_layer,npts_lat,npts_lon) :: newgrid
REAL, INTENT(IN), DIMENSION(num_layer) :: gridlat_start,gridlon_start
REAL, INTENT(IN), DIMENSION(num_layer) :: layerdep
REAL, INTENT(IN), DIMENSION(npts_path) :: pathlat,pathlon,pathdep
REAL, DIMENSION(npts_path) :: vs_prem_path,dvs_tomo_path

! INPUT OF PREM MODEL
CHARACTER(len=40) :: premfilename='prem_vs.txt'
REAL, ALLOCATABLE, DIMENSION(:) :: depth_prem,v_prem

REAL :: real_tmp,X,Y,X0,Y0,R,R0,t_prem,t_tomo
REAL :: dvs_tmp1,dvs_tmp2,dvs_tmp3,dvs_tmp4,dvs_tmp_up,dvs_tmp_down
REAL :: diff_depth,diff_lat,diff_lon,pathseg_length
REAL :: length,az_tmp,dist_tmp,baz_tmp
INTEGER :: lon_up,lon_low,lat_up,lat_low,con_lon_sys
INTEGER :: status_read,status_alloc,npts_prem,idep,idep_prem


INTEGER :: i,j,k,l,m,n

!=============================================================================
!    READ IN INTERPOLATED PREM MODEL
!=============================================================================
OPEN(UNIT=11,FILE=premfilename,status='OLD',iostat=status_read)
DO i=1,prem_maxp
read(11,*,IOSTAT=status_read)real_tmp,real_tmp
IF(status_read /= 0 ) EXIT
END DO
npts_prem=i-1
REWIND(UNIT=11)
ALLOCATE(depth_prem(npts_prem),v_prem(npts_prem),STAT=status_alloc)
READ(11,*)(depth_prem(i),v_prem(i),i=1,npts_prem)
CLOSE(UNIT=11)

!write(*,*)'Inputs are:',num_layer,npts_lat,npts_lon,lat_step,lon_step,npts_path,depth_cutmin,depth_cutmax,dt_relative

!=============================================================================
!    Calculate the tomography predicted differential travel time relative to
!    PREM
!=============================================================================
dt_relative=0.0
pathseg_length=0.0
DO i=1,npts_path
 IF(pathdep(i)>=depth_cutmin .AND. pathdep(i)<=depth_cutmax) THEN
  ! Find the depth layer in tomo
  idep=minloc(abs(layerdep-pathdep(i)),DIM=1)
  IF(layerdep(idep)>=pathdep(i))idep=idep-1
  IF(idep<=0)idep=1
   !DO idep=1,num_layer
   ! IF(pathdep(i)>=layerdep(idep) .AND. pathdep(i)<=layerdep(idep+1))EXIT
  ! END DO ! idep
  ! Find the prem velocity
   DO idep_prem=1,npts_prem
    IF(pathdep(i)>=depth_prem(idep_prem) .AND. pathdep(i)<=depth_prem(idep_prem+1))EXIT
   END DO ! idep_prem
   vs_prem_path(i)=v_prem(idep_prem)
   !write(*,*)i,npts_path,pathdep(i),'tomo:',layerdep(idep),'prem:',depth_prem(idep_prem),vs_prem_path(i)
  ! Find the lat lon
     lat_low=int((pathlat(i)-gridlat_start(idep))/lat_step)+1
     lat_up=lat_low+1
     lon_low=int((pathlon(i)-gridlon_start(idep))/lon_step)+1
     lon_up=lon_low+1
     diff_lat=pathlat(i)-(gridlat_start(idep)+lat_step*(lat_low-1))

      IF(lon_low>=npts_lon .OR. pathlon(i) < gridlon_start(idep) ) THEN ! longitude out of bound
         lon_low=npts_lon
         lon_up=1
         diff_lon=pathlon(i)-(gridlon_start(idep)+lon_step*(lon_low-1))
          IF(abs(diff_lon)>abs(lon_step))diff_lon=diff_lon+360.0
      ELSE
         diff_lon=pathlon(i)-(gridlon_start(idep)+lon_step*(lon_low-1))
      END IF

     diff_depth=pathdep(i)-layerdep(idep)
   !write(*,*)i,lat_low,lon_low,pathlat(i),pathlon(i),idep,gridlon_start(idep)
  ! Find the average velocity at this point
     dvs_tmp1=newgrid(idep,lat_low,lon_low)+(newgrid(idep,lat_up,lon_low)-newgrid(idep,lat_low,lon_low))/lat_step*diff_lat
     dvs_tmp2=newgrid(idep,lat_low,lon_up)+(newgrid(idep,lat_up,lon_up)-newgrid(idep,lat_low,lon_up))/lat_step*diff_lat
     dvs_tmp_down=dvs_tmp1+(dvs_tmp2-dvs_tmp1)*diff_lon/lon_step
     dvs_tmp3=newgrid(idep+1,lat_low,lon_low)+(newgrid(idep+1,lat_up,lon_low)-newgrid(idep+1,lat_low,lon_low))/lat_step*diff_lat
     dvs_tmp4=newgrid(idep+1,lat_low,lon_up)+(newgrid(idep+1,lat_up,lon_up)-newgrid(idep+1,lat_low,lon_up))/lat_step*diff_lat
     dvs_tmp_up=dvs_tmp3+(dvs_tmp4-dvs_tmp3)*diff_lon/lon_step
     dvs_tomo_path(i)=dvs_tmp_down+(dvs_tmp_up-dvs_tmp_down)*diff_depth/(layerdep(idep+1)-layerdep(idep))
   !write(*,*)dvs_tmp1,dvs_tmp2,dvs_tmp3,dvs_tmp4
   ! Calculate the path segment between this point and the one below it
    call ydaz_func(pathlat(i),pathlon(i),pathlat(i+1),pathlon(i+1),dist_tmp,az_tmp,baz_tmp)
    IF(dist_tmp/=dist_tmp)dist_tmp=0.0
    ! to km
     R=6371.0-pathdep(i+1)
     X=R*cos(dist_tmp/180*3.1415926)
     Y=R*sin(dist_tmp/180*3.1415926)
     R0=6371-pathdep(i)
     length=SQRT((R0-X)**2+Y**2)
     IF(length/=length)length=0.0
     t_prem=length/vs_prem_path(i)
     t_tomo=length/(vs_prem_path(i)*(1.0+dvs_tomo_path(i)/100.0))
      IF(t_tomo/=t_tomo) then
            t_tomo=0.0
!          write(*,*)dvs_tmp1,dvs_tmp2,dvs_tmp3,dvs_tmp4,lat_step,diff_lat,lon_step,diff_lon
!          write(*,*)newgrid(idep,lat_low,lon_up),newgrid(idep,lat_up,lon_up)
!          write(*,*)length,vs_prem_path(i),dvs_tomo_path(i),dvs_tmp_down,dvs_tmp_up,diff_depth,layerdep(idep+1),layerdep(idep)
      ENDIF
     dt_relative=dt_relative+t_tomo-t_prem
     pathseg_length=pathseg_length+length
    !  write(*,*)i,npts_path,pathlon(i),dt_relative,t_tomo,t_prem,length,pathseg_length,dist_tmp
    !      write(*,*)dvs_tmp1,dvs_tmp2,dvs_tmp3,dvs_tmp4,lat_step,diff_lat,lon_step,diff_lon
    !      write(*,*)newgrid(idep,lat_low,lon_up),newgrid(idep,lat_up,lon_up)
 ENDIF
END DO ! i loop
! Deallocate
DEALLOCATE(depth_prem,v_prem,STAT=status_alloc)
END SUBROUTINE time_tomo_prediction
