PROGRAM PM_INVER
!===============================================================
!      INSTRUCTIONS
!---------------------------------------------------------------
!===============================================================
!      Definations
!---------------------------------------------------------------
IMPLICIT NONE
INTEGER, PARAMETER :: maxlat=200
INTEGER, PARAMETER :: maxlon=400
INTEGER, PARAMETER :: maxp=70000
INTEGER, PARAMETER :: maxpfile=4000
INTEGER, PARAMETER :: max_cell=200
INTEGER, PARAMETER :: layer=61
INTEGER, PARAMETER :: maxfile=5000
INTEGER, PARAMETER :: num_loop=10
! tomography model position and Vs velocity array
REAL, ALLOCATABLE, DIMENSION(:,:) :: gridlat,gridlon,griddvs,griddvs_original
REAL, ALLOCATABLE, DIMENSION(:,:,:) :: grid,finalgrid,grid_original,grid_mask,grid_diff,grid_tmp,grid_tmp2
REAL, ALLOCATABLE, DIMENSION(:,:,:) :: grid_mask_ScS
REAL, ALLOCATABLE, DIMENSION(:,:,:) :: grid_numpathseg_sample,grid_dvs_ave_change
REAL, ALLOCATABLE, DIMENSION(:,:,:) :: grid_pathlength,grid_dvs_change

REAL, DIMENSION(layer) :: layerdep,layerdepmin,layerdepmax
REAL, DIMENSION(max_cell) :: weight_depth_ScS,weight
INTEGER, DIMENSION(layer) :: layerpnum
REAL, DIMENSION(layer) :: gridlat_start,gridlon_start

CHARACTER(len=100), ALLOCATABLE, DIMENSION(:) :: tomofilename
REAL :: lat_min,lon_min,lat_max,lon_max,lat_step,lon_step
REAL :: dep_min,dep_max,real_tmp,weight_sum
INTEGER :: con_lon_sys,npts_lon,npts_lat,num_layer
! path
INTEGER :: num_path,num_path_layer_sample
CHARACTER(len=50), ALLOCATABLE, DIMENSION(:) :: mainpathfile,refpathfile
REAL, ALLOCATABLE, DIMENSION(:) :: dt,az,variance
REAL, ALLOCATABLE, DIMENSION(:) :: mainpath_bottdep,path_length,depth_prem,v_prem
INTEGER, DIMENSION(maxfile) :: npts_mainpath,npts_refpath,num_cell,con_S_ScS
REAL, ALLOCATABLE, DIMENSION(:,:) :: mainpathlat,mainpathlon,mainpathdep
INTEGER, ALLOCATABLE, DIMENSION(:,:) :: itomo_dep,itomo_latlow,itomo_lonlow,itomo_lonup,np_per_cell
REAL, ALLOCATABLE, DIMENSION(:,:) :: refpathlat,refpathlon,refpathdep
REAL, ALLOCATABLE, DIMENSION(:,:) :: pathseg_length,cell_lat_low,cell_lat_up,cell_lon_low,cell_lon_up
REAL, ALLOCATABLE, DIMENSION(:,:) :: cell_dep_low,cell_dep_up,cell_dvs_ave,vs_prem_cell,t_predict_S_cell
REAL, ALLOCATABLE, DIMENSION(:,:) :: dt_obs_pre_cell,cell_dvs_change,dt_obs_pre
! input filelist
CHARACTER(len=100) :: tomofilelist,pathfilelist,char_tmp,newtomofilename

! Other factor
REAL :: factor_min,factor_max,factor_step,factor,azmin,azmax,az_step
REAL :: depth_cutmin,depth_cutmax,factor_best,con_continue,az_uplimit,az_lowlimit
REAL, ALLOCATABLE,DIMENSION(:) :: t_predict_S,t_predict_S_SKS
INTEGER :: num_factor,num_tmp,int_tmp,npts_tmp,ifactor_best,num_az
REAL :: depthmin_correct_S,depthmin_correct_ScS,t_predict_SKS1,t_predict_SKS2,pathseg_tmp
REAL :: t_predict_SKS
! Read and write
INTEGER :: status_read,status_write,status_alloc,num_point,ipathseg
INTEGER :: i,j,k,l,m,n,ifactor,ipath,ipath_point,i_cell
INTEGER :: idepth,ilat,ilon,ibottom,idep_layer_start,ic,npts_prem

! Search
INTEGER :: idep,lat_low,lat_up,lon_low,lon_up,i_repeat,idep_layer,iaz,numpathseg
REAL :: dist_tmp,az_tmp,baz_tmp,R,X,Y,R0,length,dt_ave,depthmin_cut_ScS
INTEGER:: deplow,depup,latlow,latup,lonlow,lonup,iloop,np_per_cell_tmp,con
REAL :: dvs_tmp1,dvs_tmp2,dvs_tmp_down,dvs_tmp_up,dvs_min,dvs_max,path_thickness


n=IARGC()
IF(n<1) THEN
WRITE(*,*)"USAGE: PM_INVER tomofilelist pathfilelist"
ELSE
CALL GETARG(1,tomofilelist)
CALL GETARG(2,pathfilelist)
ENDIF

path_thickness=600 ! allowed raypath bottom hight whose sampled cells can be changed in tomography 
depthmin_cut_ScS=2291
!depth_cutmin = 1891 ! km

!==============Do not change this number========================
depth_cutmax = 2891 ! km
depthmin_correct_S=2291 ! above which tomography corrections applied to S, whole path correction to SKS, do not change this number!
depthmin_correct_ScS=2691 ! above which tomography corrections applied to ScS, whole path correction to S, do not change this number!

!===============================================================
!      Read in data 
!---------------------------------------------------------------
! Read in mainpath and referance path files
!---------------------------------------------------------------

OPEN(UNIT=11, FILE=pathfilelist, STATUS='OLD', ACTION='read', IOSTAT=status_read)
DO i=1,maxfile
!read(11,*,IOSTAT=status_read)mainpathfile(i),refpathfile(i),dt(i)
read(11,*,IOSTAT=status_read)char_tmp,char_tmp,real_tmp,real_tmp
IF(status_read /= 0 ) EXIT
END DO ! i loop
num_path=i-1
REWIND(UNIT=11)
ALLOCATE(mainpathfile(num_path),refpathfile(num_path),dt(num_path),az(num_path),STAT=status_alloc)
ALLOCATE(mainpath_bottdep(num_path),STAT=status_alloc)
READ(11,*)(mainpathfile(i),refpathfile(i),dt(i),az(i),con_S_ScS(i),i=1,num_path)
CLOSE(UNIT=11)

ALLOCATE(mainpathlat(num_path,maxpfile),mainpathlon(num_path,maxpfile),mainpathdep(num_path,maxpfile),STAT=status_alloc)
ALLOCATE(itomo_dep(num_path,maxpfile),itomo_latlow(num_path,maxpfile),itomo_lonlow(num_path,maxpfile),STAT=status_alloc)
ALLOCATE(itomo_lonup(num_path,maxpfile),STAT=status_alloc)
ALLOCATE(refpathlat(num_path,maxpfile),refpathlon(num_path,maxpfile),refpathdep(num_path,maxpfile),STAT=status_alloc)
DO i=1,num_path
OPEN(UNIT=12,FILE=mainpathfile(i),STATUS='OLD', ACTION='read', IOSTAT=status_read)
DO j=1,maxp
read(12,*,IOSTAT=status_read)mainpathlat(i,j),mainpathlon(i,j),mainpathdep(i,j)
IF(status_read /= 0 ) EXIT
END DO ! j loop
npts_mainpath(i)=j-1
mainpath_bottdep(i)=maxval(mainpathdep(i,1:npts_mainpath(i)),DIM=1)
CLOSE(UNIT=12)

OPEN(UNIT=12,FILE=refpathfile(i),STATUS='OLD', ACTION='read', IOSTAT=status_read)
DO j=1,maxp
read(12,*,IOSTAT=status_read)refpathlat(i,j),refpathlon(i,j),refpathdep(i,j)
IF(status_read /= 0 ) EXIT
END DO ! j loop
npts_refpath(i)=j-1
CLOSE(UNIT=12)
!write(*,*)i,npts_mainpath(i),npts_refpath(i),maxval(refpathdep(i,:),DIM=1)
END DO ! i loop

!===============================================================
!      Read in prem model
!---------------------------------------------------------------
OPEN(UNIT=11,FILE='prem_vs.txt',status='OLD',iostat=status_read)
DO i=1,maxp
read(11,*,IOSTAT=status_read)real_tmp,real_tmp
IF(status_read /= 0 ) EXIT
END DO
npts_prem=i-1
REWIND(UNIT=11)
ALLOCATE(depth_prem(npts_prem),v_prem(npts_prem),STAT=status_alloc)
READ(11,*)(depth_prem(i),v_prem(i),i=1,npts_prem)
CLOSE(UNIT=11)


!---------------------------------------------------------------
! Read in tomography files
!---------------------------------------------------------------
OPEN(UNIT=11, FILE=tomofilelist, STATUS='OLD', ACTION='read', IOSTAT=status_read)
DO i=1,layer
read(11,*,IOSTAT=status_read)char_tmp
IF(status_read /= 0 ) EXIT
END DO ! i loop
num_layer=i-1
REWIND(UNIT=11)
ALLOCATE(tomofilename(num_layer),STAT=status_alloc)
READ(11,*)(tomofilename(i),i=1,num_layer)
CLOSE(UNIT=11)

ALLOCATE(gridlat(num_layer,maxp),gridlon(num_layer,maxp),griddvs(num_layer,maxp),STAT=status_alloc)
DO i=1,num_layer
OPEN(11,FILE=tomofilename(i),STATUS='OLD',ACTION='read',IOSTAT=status_read)
  READ(11,*,IOSTAT=status_read)layerdepmin(i),layerdepmax(i)
  layerdep(i)=(layerdepmin(i)+layerdepmax(i))/2.0
  DO j=1,maxp
   READ(11,*,IOSTAT=status_read)gridlat(i,j),gridlon(i,j),griddvs(i,j)
   IF(griddvs(i,j)>900)griddvs(i,j)=0.0
!   IF(gridlon(i,j)<0)gridlon(i,j)=360.0+gridlon(i,j)
   IF(status_read /= 0 ) EXIT
  END DO
layerpnum(i)=j-1
!write(*,*)'layer:',i,'num points:',layerpnum(i), maxval(griddvs(i,:),DIM=1)
CLOSE(UNIT=11)
END DO ! i loop

!---------------------------------------------------------------
! Reorgnize tomography model to 3D array
!---------------------------------------------------------------
dep_min=MINVAL(layerdepmin(1:num_layer))
dep_max=MAXVAL(layerdepmax(1:num_layer))
lat_max=MAXVAL(gridlat(1,1:layerpnum(1)))
lat_min=MINVAL(gridlat(1,1:layerpnum(1)))
lon_max=MAXVAL(gridlon(1,1:layerpnum(1)))
lon_min=MINVAL(gridlon(1,1:layerpnum(1)))
!write(*,*)'Latitude extremes:',lat_max,lat_min,'Longitude extremes:',lon_max,lon_min
! Determine with longitude system:  0-360 or -180 - 180
con_lon_sys=0
IF(lon_max>185)con_lon_sys=1 ! This means it is 360 system

DO i=1,num_layer
 ! Find out the demension,assuming gridlat is the first repeating value
   npts_lon=0
   DO j=1,maxp
     IF(gridlat(i,j)==gridlat(i,j+1)) THEN
       npts_lon=npts_lon+1
     ELSE
       EXIT
     ENDIF
   END DO ! j loop
   npts_lon=npts_lon+1
   npts_lat=layerpnum(i)/npts_lon
   !IF(npts_lat*npts_lon < layerpnum(i))WRITE(*,*)'Warning:: Your matrix is not complete!',npts_lat,npts_lon,layerpnum(i)
END DO ! i loop
  ALLOCATE(grid(num_layer,npts_lat,npts_lon),STAT=status_alloc)
  ALLOCATE(grid_mask(num_layer,npts_lat,npts_lon),STAT=status_alloc)
  ALLOCATE(grid_mask_ScS(num_layer,npts_lat,npts_lon),STAT=status_alloc)
  ALLOCATE(finalgrid(num_layer,npts_lat,npts_lon),STAT=status_alloc)
  ALLOCATE(grid_original(num_layer,npts_lat,npts_lon),STAT=status_alloc)
  ALLOCATE(grid_diff(num_layer,npts_lat,npts_lon),STAT=status_alloc)
DO i=1,num_layer
 ! Transfer to 2D array 
   DO j=1,npts_lat
    DO k=1,npts_lon
     m=k+(j-1)*npts_lon
     grid(i,j,k)=griddvs(i,m)
     grid_original(i,j,k)=griddvs(i,m)
    ! write(*,*)grid(j,k),griddvs(i,m)
    END DO ! k loop
   END DO ! j loop
! So now latitude step is:
  lat_step = gridlat(i,1+npts_lon)-gridlat(i,1)
   gridlat_start(i)=gridlat(i,1)
! longitude step is: 
  lon_step = gridlon(i,2)-gridlon(i,1)
   gridlon_start(i)=gridlon(i,1)
! Initial value for the 2D layer is: gridlat(i,1),gridlon(i,1)
! So any grid(j,k)'s locations is: gridlat(i,1)+(j-1)*lat_step, gridlon(i,1)+(k-1)*lon_step
!write(*,*)'2D formed:',npts_lat,npts_lon,lat_step,lon_step
END DO ! i loop
DEALLOCATE(gridlat,gridlon,griddvs,STAT=status_alloc)

!-------------Do not change this!!!--------------------------------------------------------
idep_layer_start=minloc(abs(layerdepmin-depthmin_correct_S),DIM=1)
IF(layerdepmin(idep_layer_start)>depthmin_correct_S)idep_layer_start=idep_layer_start-1
grid_mask(1:idep_layer_start,:,:)=grid_original(1:idep_layer_start,:,:)
grid_mask(idep_layer_start+1:num_layer,:,:)=0.0
idep_layer_start=minloc(abs(layerdepmin-depthmin_correct_ScS),DIM=1)
IF(layerdepmin(idep_layer_start)>depthmin_correct_ScS)idep_layer_start=idep_layer_start-1
grid_mask_ScS(1:idep_layer_start,:,:)=grid_original(1:idep_layer_start,:,:)
grid_mask_ScS(idep_layer_start+1:num_layer,:,:)=0.0
!------------------------------------------------------------------------------------------

!write(*,*)idep_layer_start,layerdepmin(idep_layer_start),depthmin_correct_S

!===============================================================
! Change tomo cells along the raypath to calculate travel time      
!---------------------------------------------------------------
! initiating the new grid
ALLOCATE(cell_lat_low(num_path,max_cell),STAT=status_alloc)
ALLOCATE(cell_lat_up(num_path,max_cell),STAT=status_alloc)
ALLOCATE(cell_lon_low(num_path,max_cell),STAT=status_alloc)
ALLOCATE(cell_lon_up(num_path,max_cell),STAT=status_alloc)
ALLOCATE(cell_dep_low(num_path,max_cell),STAT=status_alloc)
ALLOCATE(cell_dep_up(num_path,max_cell),STAT=status_alloc)
ALLOCATE(pathseg_length(num_path,max_cell),STAT=status_alloc)
ALLOCATE(np_per_cell(num_path,max_cell),STAT=status_alloc)
ALLOCATE(path_length(num_path),STAT=status_alloc)
ALLOCATE(variance(0:num_loop),STAT=status_alloc)
ALLOCATE(t_predict_S(num_path),STAT=status_alloc)
ALLOCATE(t_predict_S_SKS(num_path),dt_obs_pre(num_path,num_loop),STAT=status_alloc)
ALLOCATE(t_predict_S_cell(num_path,max_cell),STAT=status_alloc)
ALLOCATE(cell_dvs_ave(num_path,max_cell),STAT=status_alloc)
ALLOCATE(dt_obs_pre_cell(num_path,max_cell),cell_dvs_change(num_path,max_cell),STAT=status_alloc)
ALLOCATE(vs_prem_cell(num_path,max_cell),STAT=status_alloc)
ALLOCATE(grid_numpathseg_sample(num_layer,npts_lat,npts_lon),STAT=status_alloc)
ALLOCATE(grid_tmp(num_layer,npts_lat,npts_lon),STAT=status_alloc)
ALLOCATE(grid_tmp2(num_layer,npts_lat,npts_lon),STAT=status_alloc)
ALLOCATE(grid_dvs_ave_change(num_layer,npts_lat,npts_lon),STAT=status_alloc)
ALLOCATE(grid_pathlength(num_layer,npts_lat,npts_lon),STAT=status_alloc)
grid_pathlength(:,:,:)=0.0
ALLOCATE(grid_dvs_change(num_layer,npts_lat,npts_lon),STAT=status_alloc)
grid_dvs_change(:,:,:)=0.0

! Searching through path points
! write process into a temporary file

OPEN(UNIT=12,FILE='PM_INVER.process',status='UNKNOWN',iostat=status_write) ! 4 debug

finalgrid=grid
iloop=1
con=1
variance(0)=10000000.0
DO WHILE ( iloop <= num_loop .AND. con == 1)
grid_tmp=grid
grid=finalgrid
grid_numpathseg_sample(:,:,:)=0.0
grid_pathlength(:,:,:)=0.0
grid_dvs_change(:,:,:)=0.0
path_length(1:num_path)=0.0
pathseg_length(:,:)=0.0
DO ipath=1,num_path
!--------------------- critical parameter-----------------------------
! Determines the cells that can be changed according to time residual
!---------------------------------------------------------------------
!depth_cutmin=mainpath_bottdep(ipath)-path_thickness
depth_cutmin=depthmin_correct_S
IF(con_S_ScS(ipath)==1.0)depth_cutmin=depthmin_cut_ScS
!---------------------------------------------------------------------
! For each path point, find out the tomo grid surrounding it.
num_point=0
i_cell=1
!np_per_cell(ipath,1:max_cell)=0.0
np_per_cell_tmp=1
!write(*,*)'Locate cells sampled by this path:'
 DO ipath_point=1,npts_mainpath(ipath)
      ! correct different longitude system so that they are the same
         IF(con_lon_sys==0 .AND. mainpathlon(ipath,ipath_point)>180) THEN
              mainpathlon(ipath,ipath_point)=mainpathlon(ipath,ipath_point)-360
         ENDIF
         IF(con_lon_sys==0 .AND. refpathlon(ipath,ipath_point)>180) THEN
              refpathlon(ipath,ipath_point)=refpathlon(ipath,ipath_point)-360
         ENDIF
  IF(mainpathdep(ipath,ipath_point)>=depth_cutmin .AND.&
mainpathdep(ipath,ipath_point)<=depth_cutmax) THEN
    ! Search for tomography grid around the path point and multiply the modify factor

       IF(mainpathlat(ipath,ipath_point) <= lat_max .AND. &
mainpathlat(ipath,ipath_point) >= lat_min .AND. &
mainpathdep(ipath,ipath_point)>=dep_min .AND. &
mainpathdep(ipath,ipath_point)<=dep_max) THEN
         num_point=num_point+1
         ! Determine the depth shell first
         idep=minloc(abs(layerdep-mainpathdep(ipath,ipath_point)),DIM=1)
         IF(layerdep(idep)>=mainpathdep(ipath,ipath_point))idep=idep-1
         itomo_dep(ipath,ipath_point)=idep
         lat_low=int((mainpathlat(ipath,ipath_point)-gridlat_start(idep))/&
lat_step)+1
         itomo_latlow(ipath,ipath_point)=lat_low
         lon_low=int((mainpathlon(ipath,ipath_point)-gridlon_start(idep))/&
lon_step)+1
         itomo_lonlow(ipath,ipath_point)=lon_low
         IF (mainpathlon(ipath,ipath_point)>=lon_max .OR. mainpathlon(ipath,ipath_point) < lon_min) THEN
          itomo_lonup(ipath,ipath_point)=1
          itomo_lonlow(ipath,ipath_point)=npts_lon
!          write(*,*)ipath,ipath_point,mainpathlon(ipath,ipath_point),itomo_lonup(ipath,ipath_point),itomo_lonlow(ipath,ipath_point)
         ELSE
          itomo_lonup(ipath,ipath_point)=itomo_lonlow(ipath,ipath_point)+1
         ! write(*,*)lon_min,lon_max,itomo_lonlow(ipath,ipath_point),itomo_lonup(ipath,ipath_point)
         ENDIF
        ELSE
           write(*,*)'latitude and depth extremes reached..'
        ENDIF
     !write(*,*)ipath_point,mainpathdep(ipath,ipath_point),itomo_dep(ipath,ipath_point),itomo_latlow(ipath,ipath_point),&
!itomo_lonlow(ipath,ipath_point)
      IF ( num_point > 1 ) THEN
!         write(*,*)ipath,ipath_point,npts_mainpath(ipath),i_cell
!         write(*,*)itomo_latlow(ipath,ipath_point),itomo_lonlow(ipath,ipath_point),itomo_dep(ipath,ipath_point)
!         write(*,*)itomo_latlow(ipath,ipath_point-1),itomo_lonlow(ipath,ipath_point-1),itomo_dep(ipath,ipath_point-1)

         call ydaz_func(mainpathlat(ipath,ipath_point),mainpathlon(ipath,ipath_point),mainpathlat(ipath,&
ipath_point-1),mainpathlon(ipath,ipath_point-1),dist_tmp,az_tmp,baz_tmp)

          IF(dist_tmp/=dist_tmp)dist_tmp=0.0

          ! calculate path segment length to km
         R=6371.0-mainpathdep(ipath,ipath_point)
         X=R*cos(dist_tmp/180.0*3.1415926)
         Y=R*sin(dist_tmp/180.0*3.1415926)
         R0=6371.0-mainpathdep(ipath,ipath_point-1)
         length=SQRT((R0-X)**2+Y**2)
          IF(length/=length)length=0.0
         pathseg_length(ipath,i_cell)=pathseg_length(ipath,i_cell)+length
         cell_lat_low(ipath,i_cell)=itomo_latlow(ipath,ipath_point)
         cell_lat_up(ipath,i_cell)=itomo_latlow(ipath,ipath_point)+1
         cell_lon_low(ipath,i_cell)=itomo_lonlow(ipath,ipath_point)
         cell_lon_up(ipath,i_cell)=itomo_lonup(ipath,ipath_point)
         cell_dep_low(ipath,i_cell)=itomo_dep(ipath,ipath_point)
         cell_dep_up(ipath,i_cell)=itomo_dep(ipath,ipath_point)+1

         np_per_cell_tmp=np_per_cell_tmp+1
         !np_per_cell(ipath,i_cell)=np_per_cell(ipath,i_cell)+1
!         write(*,*)ipath,ipath_point,npts_mainpath(ipath),i_cell,np_per_cell_tmp,length,&
!pathseg_length(ipath,i_cell),path_length(ipath)
!         write(*,*)itomo_latlow(ipath,ipath_point),itomo_lonlow(ipath,ipath_point),itomo_dep(ipath,ipath_point)
!         write(*,*)itomo_latlow(ipath,ipath_point-1),itomo_lonlow(ipath,ipath_point-1),itomo_dep(ipath,ipath_point-1)

            path_length(ipath)=path_length(ipath)+length
        IF ( abs(itomo_latlow(ipath,ipath_point)-itomo_latlow(ipath,ipath_point-1) ) >= 0.01 .OR. &
abs(itomo_lonlow(ipath,ipath_point)-itomo_lonlow(ipath,ipath_point-1)) >= 0.01 .OR. abs(itomo_dep(ipath,ipath_point)- &
itomo_dep(ipath,ipath_point-1)) >= 0.01 ) THEN
         np_per_cell_tmp=1
           !write(*,*)ipath,i_cell,pathseg_length(ipath,i_cell)
           IF(pathseg_length(ipath,i_cell)>0.0) THEN
             i_cell=i_cell+1
           ENDIF
        ENDIF

      ENDIF ! end if of( IF(num_point>1)
   END IF ! IF(mainpathdep(ipath,ipath_point)>=depth_cutmin .AND.mainpathdep(ipath,ipath_point)<=depth_cutmax) 
  END DO ! ipath_point
IF(pathseg_length(ipath,i_cell)==0.0)i_cell=i_cell-1
num_cell(ipath)=i_cell

IF(con_S_ScS(ipath)==0) THEN
! For S-SKS travel time calculation
depth_cutmin=mainpath_bottdep(ipath)-path_thickness
grid_diff=grid-grid_mask
  CALL time_tomo_prediction(grid_diff(:,:,:),gridlat_start,gridlon_start,num_layer,layerdep,npts_lat,&
npts_lon,lat_step,lon_step,mainpathlat(ipath,:),mainpathlon(ipath,:),mainpathdep(ipath,:),&
npts_mainpath(ipath),depth_cutmin,depth_cutmax,t_predict_S(ipath))
! Calculate SKS prediction 
ibottom=maxloc(refpathdep(ipath,1:npts_refpath(ipath)),DIM=1)
npts_tmp=ibottom
!write(*,*)ibottom,npts_tmp,depth_cutmin, maxval(grid_original),depth_cutmax
grid_diff=grid-grid_original
  CALL time_tomo_prediction(grid_diff(:,:,:),gridlat_start,gridlon_start,num_layer,layerdep,npts_lat,&
npts_lon,lat_step,lon_step,refpathlat(ipath,1:ibottom),refpathlon(ipath,1:ibottom),refpathdep(ipath,1:ibottom),&
npts_tmp,depth_cutmin,depth_cutmax,t_predict_SKS1)
  ! SKS post turning part
npts_tmp=npts_refpath(ipath)-ibottom+1
!write(*,*)npts_tmp,ibottom,refpathdep(ipath,ibottom)
  CALL time_tomo_prediction(grid_diff(:,:,:),gridlat_start,gridlon_start,num_layer,layerdep,npts_lat,&
npts_lon,lat_step,lon_step,refpathlat(ipath,ibottom:npts_refpath(ipath)),refpathlon(ipath,&
ibottom:npts_refpath(ipath)),refpathdep(ipath,ibottom:npts_refpath(ipath)),&
npts_tmp,depth_cutmin,depth_cutmax,t_predict_SKS2)

t_predict_SKS=t_predict_SKS1+t_predict_SKS2

ELSE
! For ScS-S
depth_cutmin=depthmin_cut_ScS
grid_diff=grid-grid_mask_ScS
  CALL time_tomo_prediction(grid_diff(:,:,:),gridlat_start,gridlon_start,num_layer,layerdep,npts_lat,&
npts_lon,lat_step,lon_step,mainpathlat(ipath,:),mainpathlon(ipath,:),mainpathdep(ipath,:),&
npts_mainpath(ipath),depth_cutmin,depth_cutmax,t_predict_S(ipath))
! Calculate ScS prediction 
grid_diff=grid-grid_original
  CALL time_tomo_prediction(grid_diff(:,:,:),gridlat_start,gridlon_start,num_layer,layerdep,npts_lat,&
npts_lon,lat_step,lon_step,refpathlat(ipath,:),refpathlon(ipath,:),refpathdep(ipath,:),&
npts_refpath(ipath),depth_cutmin,depth_cutmax,t_predict_SKS)
END IF

t_predict_S_SKS(ipath) = t_predict_S(ipath)-t_predict_SKS
dt_obs_pre(ipath,iloop)=t_predict_S_SKS(ipath)-dt(ipath)

write(12,*)iloop,'Path:',ipath,mainpathfile(ipath),'dt_predict:',t_predict_S(ipath),'dt_resi:',&
dt_obs_pre(ipath,iloop),'dt_main_pre:',t_predict_S(ipath),'dt_ref_pre:',t_predict_SKS,&
'num_cell:',num_cell(ipath),'Pathlength:',path_length(ipath)
write(*,*)iloop,'Path:',ipath,mainpathfile(ipath),'dt_predict:',t_predict_S(ipath),'dt_resi:',&
dt_obs_pre(ipath,iloop),'dt_main_pre:',t_predict_S(ipath),'dt_ref_pre:',t_predict_SKS,&
'num_cell:',num_cell(ipath),'Pathlength:',path_length(ipath)



! Calculate depth weighted function 
! such that cells at shallower depths have smaller velocity perturbation
! This is only for ScS
! I want 0.2 at the top and 1.2 at the bottom
weight_sum=0.0
weight_depth_ScS(:)=0.0
weight(:)=0.0
DO ic=1,i_cell
  deplow=cell_dep_low(ipath,ic)
  depup=cell_dep_up(ipath,ic)
  weight_depth_ScS(ic)=exp((((layerdep(deplow)+layerdep(depup))/2.0-depthmin_cut_ScS)/(2891-depthmin_cut_ScS))**2)-1
if(con_S_ScS(ipath)==1.0) then
  weight(ic)=weight_depth_ScS(ic)*pathseg_length(ipath,ic)
  weight_sum=weight_sum+weight_depth_ScS(ic)*pathseg_length(ipath,ic)
else
  weight(ic)=pathseg_length(ipath,ic)
  weight_sum=weight_sum+pathseg_length(ipath,ic)
endif
END DO ! end of ic

! Calculate travel time
!write(*,*)'Calculating dvs change for each cell'
t_predict_S_cell(ipath,:)=0.0
vs_prem_cell(ipath,:)=0.0
 DO ic=1,i_cell
      deplow=cell_dep_low(ipath,ic)
      depup=cell_dep_up(ipath,ic)
      latlow=cell_lat_low(ipath,ic)
      latup=cell_lat_up(ipath,ic)
      lonlow=cell_lon_low(ipath,ic)
      lonup=cell_lon_up(ipath,ic)
      dvs_tmp1=(grid(deplow,latlow,lonlow)+grid(deplow,latlow,lonup))/2.0
      dvs_tmp2=(grid(deplow,latup,lonlow)+grid(deplow,latup,lonup))/2.0
      dvs_tmp_down=(dvs_tmp1+dvs_tmp2)/2.0
      dvs_tmp1=(grid(depup,latlow,lonlow)+grid(depup,latlow,lonup))/2.0
      dvs_tmp2=(grid(depup,latup,lonlow)+grid(depup,latup,lonup))/2.0
      dvs_tmp_up=(dvs_tmp1+dvs_tmp2)/2.0
      cell_dvs_ave(ipath,ic)=(dvs_tmp_down+dvs_tmp_up)/2.0
!write(*,*)ic,deplow,latlow,lonlow,dvs_tmp_down,dvs_tmp_up,cell_dvs_ave(ipath,ic)

      vs_prem_cell(ipath,ic)=v_prem(minloc(abs(depth_prem(1:npts_prem)-(layerdep(deplow)+layerdep(depup))/2.0),DIM=1))

!write(*,*)vs_prem_cell(ipath,ic),minloc(abs(depth_prem(1:npts_prem)-(layerdep(deplow)+layerdep(depup))/2.0),DIM=1)

!  dt_obs_pre_cell(ipath,ic)=(pathseg_length(ipath,ic)/path_length(ipath))*dt_obs_pre(ipath,iloop)
!write(*,*)'before',ipath,layerdep(deplow),dt_obs_pre_cell(ipath,ic)
  dt_obs_pre_cell(ipath,ic)=(weight(ic)/weight_sum)*dt_obs_pre(ipath,iloop)
  t_predict_S_cell(ipath,ic)=pathseg_length(ipath,ic)/(vs_prem_cell(ipath,ic)*(1.0+cell_dvs_ave(ipath,ic)/100.0))
!  cell_dvs_change(ipath,ic)=(-1.0)*((pathseg_length(ipath,ic)/((t_predict_S_cell(ipath,ic)+dt_obs_pre_cell(ipath,ic))*&
!vs_prem_cell(ipath,ic))-1)*100.0-cell_dvs_ave(ipath,ic))
  cell_dvs_change(ipath,ic)=(pathseg_length(ipath,ic)/((t_predict_S_cell(ipath,ic)-dt_obs_pre_cell(ipath,ic))*&
vs_prem_cell(ipath,ic))-1)*100.0-cell_dvs_ave(ipath,ic)

IF(cell_dvs_change(ipath,ic) /= cell_dvs_change(ipath,ic) ) THEN
write(12,*)'Warning: Found one NAN value..'
write(*,*)ipath,ic,t_predict_S_cell(ipath,ic),dt_obs_pre_cell(ipath,ic),cell_dvs_ave(ipath,ic),pathseg_length(ipath,ic)
write(12,*)ipath,ic,t_predict_S_cell(ipath,ic),dt_obs_pre_cell(ipath,ic),cell_dvs_ave(ipath,ic),pathseg_length(ipath,ic)
cell_dvs_change(ipath,ic)=0.0
END IF
!write(*,*)ic,pathseg_length(ipath,ic),dt_obs_pre_cell(ipath,ic),cell_dvs_change(ipath,ic)
!write(*,*)t_predict_S_cell(ipath,ic)
!      deplow=cell_dep_low(ipath,ic)
!      depup=cell_dep_up(ipath,ic)
!      latlow=cell_lat_low(ipath,ic)
!      latup=cell_lat_up(ipath,ic)
!      lonlow=cell_lon_low(ipath,ic)
!      lonup=cell_lon_up(ipath,ic)
    DO idepth=deplow,depup
     DO ilat=latlow,latup
       ilon=lonlow
       grid_numpathseg_sample(idepth,ilat,ilon)=grid_numpathseg_sample(idepth,ilat,ilon)+1
       grid_pathlength(idepth,ilat,ilon)=pathseg_length(ipath,ic)+grid_pathlength(idepth,ilat,ilon)
       grid_dvs_change(idepth,ilat,ilon)=cell_dvs_change(ipath,ic)*pathseg_length(ipath,ic)+grid_dvs_change(idepth,ilat,ilon)

       ilon=lonup
       grid_numpathseg_sample(idepth,ilat,ilon)=grid_numpathseg_sample(idepth,ilat,ilon)+1
       grid_pathlength(idepth,ilat,ilon)=pathseg_length(ipath,ic)+grid_pathlength(idepth,ilat,ilon)
       grid_dvs_change(idepth,ilat,ilon)=cell_dvs_change(ipath,ic)*pathseg_length(ipath,ic)+grid_dvs_change(idepth,ilat,ilon)
     END DO ! ilat loop
    END DO ! idepth loop
 END DO ! end of ic
!write(*,*)'Done with dvs calculation..',minval(cell_dvs_change(ipath,:)),maxval(cell_dvs_change(ipath,:))
!write(*,*)'Done with dvs calculation..',minval(grid_dvs_change(:,:,:)),maxval(grid_dvs_change(:,:,:))

END DO ! ipath loop

! Perturb the tomography model
!write(*,*)'Update the tomography model'
DO ipath=1,num_path
 DO ic=1,num_cell(ipath)
      deplow=cell_dep_low(ipath,ic)
      depup=cell_dep_up(ipath,ic)
      latlow=cell_lat_low(ipath,ic)
      latup=cell_lat_up(ipath,ic)
      lonlow=cell_lon_low(ipath,ic)
      lonup=cell_lon_up(ipath,ic)
    DO idepth=deplow,depup
! Apply depth velocity restriction
        IF(layerdep(idepth) <= 2591 ) THEN
          dvs_min=-3.0
          dvs_max=7.0
        ELSE
          dvs_min=-10.0
          dvs_max=10.0
        END IF

     DO ilat=latlow,latup

       ilon=lonlow

        grid_dvs_ave_change(idepth,ilat,ilon)=grid_dvs_change(idepth,ilat,ilon)/grid_pathlength(idepth,ilat,ilon)

         IF(grid_dvs_ave_change(idepth,ilat,ilon) /= grid_dvs_ave_change(idepth,ilat,ilon)) THEN
          write(*,*)'NAN value:',pathseg_tmp,grid_numpathseg_sample(idepth,ilat,ilon),ipath,ic
          grid_dvs_ave_change(idepth,ilat,ilon)=0.0
         ENDIF
        finalgrid(idepth,ilat,ilon)=grid(idepth,ilat,ilon)+grid_dvs_ave_change(idepth,ilat,ilon)
        IF(finalgrid(idepth,ilat,ilon)<=dvs_min) then
             finalgrid(idepth,ilat,ilon)=dvs_min
             write(*,*)'Lower cut reached'
        ENDIF
        IF(finalgrid(idepth,ilat,ilon)>=dvs_max) then
             finalgrid(idepth,ilat,ilon)=dvs_max
             write(*,*)'Higher cut reached'
        ENDIF

       ilon=lonup

        grid_dvs_ave_change(idepth,ilat,ilon)=grid_dvs_change(idepth,ilat,ilon)/grid_pathlength(idepth,ilat,ilon)

         IF(grid_dvs_ave_change(idepth,ilat,ilon) /= grid_dvs_ave_change(idepth,ilat,ilon)) THEN
          write(*,*)'NAN Value:',pathseg_tmp,grid_numpathseg_sample(idepth,ilat,ilon),ipath,ic
          grid_dvs_ave_change(idepth,ilat,ilon)=0.0
         ENDIF
        finalgrid(idepth,ilat,ilon)=grid(idepth,ilat,ilon)+grid_dvs_ave_change(idepth,ilat,ilon)
! Apply depth velocity restriction
        IF(finalgrid(idepth,ilat,ilon)<=dvs_min)finalgrid(idepth,ilat,ilon)=dvs_min
        IF(finalgrid(idepth,ilat,ilon)>=dvs_max)finalgrid(idepth,ilat,ilon)=dvs_max

      END DO ! ilat loop
    END DO ! idepth loop

 END DO ! ic loop
END DO ! ipath loop

! Smooth the grid using gaussian cap and weighted by the num_sample
!write(*,*)'Smoothing using gaussian cap:'
call tomo_smooth(finalgrid,grid_numpathseg_sample,num_layer,npts_lat,npts_lon,lat_step,lon_step,grid_tmp2)
finalgrid=grid_tmp2
!write(*,*)'Done with smoothing ^-^'

!write(*,*)'Extremes:',maxval(grid_dvs_ave_change(:,:,:)),minval(grid_dvs_ave_change(:,:,:))
! Calculate variance
dt_ave=SUM(dt_obs_pre(1:num_path,iloop),DIM=1)/num_path
variance(iloop)=0.0
DO i=1,num_path
variance(iloop)=variance(iloop)+(dt_obs_pre(i,iloop)-dt_ave)**2
END DO
variance(iloop)=variance(iloop)/num_path
write(12,*)'Loop:',iloop,'variance:',variance(iloop)
write(*,*)'Loop:',iloop,'variance:',variance(iloop)
IF ( variance(iloop) > variance(iloop-1) ) con=0
iloop=iloop+1

! Output the debug tomography model
DO i=1,num_layer
newtomofilename='debug.'//tomofilename(i)
OPEN(UNIT=13,FILE=newtomofilename,status='UNKNOWN',iostat=status_write)
write(13,*)layerdepmin(i),layerdepmax(i)
 DO j=1,npts_lat
   DO k=1,npts_lon
    WRITE(13,*)gridlat_start(i)+(j-1)*lat_step,gridlon_start(i)+(k-1)*lon_step,finalgrid(i,j,k),&
grid_dvs_ave_change(i,j,k),grid_numpathseg_sample(i,j,k),grid_original(i,j,k)
   END DO
 END DO
CLOSE(UNIT=13)
END DO ! i loop

END DO ! iloop
CLOSE(UNIT=12)

iloop=iloop-1
IF(con==0)grid=grid_tmp
! Output the final tomography model
DO i=1,num_layer
newtomofilename='NEW.'//tomofilename(i)
OPEN(UNIT=13,FILE=newtomofilename,status='UNKNOWN',iostat=status_write)
write(13,*)layerdepmin(i),layerdepmax(i)
 DO j=1,npts_lat
   DO k=1,npts_lon
    WRITE(13,*)gridlat_start(i)+(j-1)*lat_step,gridlon_start(i)+(k-1)*lon_step,grid(i,j,k),&
grid_dvs_ave_change(i,j,k),grid_numpathseg_sample(i,j,k),grid_original(i,j,k)
   END DO
 END DO
CLOSE(UNIT=13) 
END DO ! i loop

! output the attributes to each raypath
OPEN(UNIT=14,FILE='PROCESS.'//pathfilelist,status='UNKNOWN',iostat=status_write)
WRITE(14,*)'1-filename/2-dt_obs/3-con_change/4-dt_prediction/5-dt_S_predict/6-dt_SKS_prediction/7-dt_error'
DO i=1,num_path
! calculate the travel time residuals asscociated with the final tomography model
! calculate the S wave
IF(con_S_ScS(i)==0) THEN
depth_cutmin=mainpath_bottdep(i)-path_thickness
grid_diff=grid-grid_mask
  CALL time_tomo_prediction(grid_diff(:,:,:),gridlat_start,gridlon_start,num_layer,layerdep,npts_lat,&
npts_lon,lat_step,lon_step,mainpathlat(i,:),mainpathlon(i,:),mainpathdep(i,:),&
npts_mainpath(i),depth_cutmin,depth_cutmax,t_predict_S(i))
! calculate the SKS wave
ibottom=maxloc(refpathdep(i,1:npts_refpath(i)),DIM=1)
npts_tmp=ibottom
grid_diff=grid-grid_original
  CALL time_tomo_prediction(grid_diff(:,:,:),gridlat_start,gridlon_start,num_layer,layerdep,npts_lat,&
npts_lon,lat_step,lon_step,refpathlat(i,1:ibottom),refpathlon(i,1:ibottom),refpathdep(i,1:ibottom),&
npts_tmp,depth_cutmin,depth_cutmax,t_predict_SKS1)

npts_tmp=npts_refpath(i)-ibottom+1
  CALL time_tomo_prediction(grid_diff(:,:,:),gridlat_start,gridlon_start,num_layer,layerdep,npts_lat,&
npts_lon,lat_step,lon_step,refpathlat(i,ibottom:npts_refpath(i)),refpathlon(i,&
ibottom:npts_refpath(i)),refpathdep(i,ibottom:npts_refpath(i)),&
npts_tmp,depth_cutmin,depth_cutmax,t_predict_SKS2)
t_predict_SKS=t_predict_SKS1+t_predict_SKS2
ELSE
depth_cutmin=depthmin_cut_ScS
grid_diff=grid-grid_mask_ScS
  CALL time_tomo_prediction(grid_diff(:,:,:),gridlat_start,gridlon_start,num_layer,layerdep,npts_lat,&
npts_lon,lat_step,lon_step,mainpathlat(i,:),mainpathlon(i,:),mainpathdep(i,:),&
npts_mainpath(i),depth_cutmin,depth_cutmax,t_predict_S(i))
! calculate the SKS wave
grid_diff=grid-grid_original
  CALL time_tomo_prediction(grid_diff(:,:,:),gridlat_start,gridlon_start,num_layer,layerdep,npts_lat,&
npts_lon,lat_step,lon_step,refpathlat(i,:),refpathlon(i,:),refpathdep(i,:),&
npts_refpath(i),depth_cutmin,depth_cutmax,t_predict_SKS)

ENDIF
t_predict_S_SKS(i) = t_predict_S(i)-t_predict_SKS
dt_obs_pre(i,iloop)=t_predict_S_SKS(i)-dt(i)

WRITE(14,*)mainpathfile(i),dt(i),1,t_predict_S_SKS(i),t_predict_S(i),&
t_predict_SKS,dt_obs_pre(i,iloop)
WRITE(*,*)mainpathfile(i),dt(i),1,t_predict_S_SKS(i),t_predict_S(i),&
t_predict_SKS,dt_obs_pre(i,iloop)
END DO ! i loop
CLOSE(UNIT=14)

! Deallocate
DEALLOCATE(mainpathfile,refpathfile,dt,STAT=status_alloc)
DEALLOCATE(mainpath_bottdep,STAT=status_alloc)
DEALLOCATE(refpathlat,refpathlon,refpathdep,STAT=status_alloc)
DEALLOCATE(mainpathlat,mainpathlon,mainpathdep,STAT=status_alloc)

DEALLOCATE(grid,griddvs_original,grid_mask,grid_tmp,grid_tmp2,grid_mask_ScS,STAT=status_alloc)
DEALLOCATE(tomofilename,STAT=status_alloc)
DEALLOCATE(itomo_dep,itomo_latlow,itomo_lonlow,itomo_lonup,variance,STAT=status_alloc)
DEALLOCATE(finalgrid,grid_original,np_per_cell,STAT=status_alloc)

DEALLOCATE(cell_lat_low,cell_lat_up,cell_lon_low,cell_lon_up,cell_dep_low,cell_dep_up,STAT=status_alloc)
DEALLOCATE(pathseg_length,path_length,t_predict_S,vs_prem_cell,cell_dvs_ave,t_predict_S_cell,STAT=status_alloc)
DEALLOCATE(t_predict_S_SKS,dt_obs_pre,dt_obs_pre_cell,cell_dvs_change,STAT=status_alloc)
DEALLOCATE(grid_numpathseg_sample,grid_pathlength,grid_dvs_change,grid_dvs_ave_change,STAT=status_alloc)

END PROGRAM PM_INVER

