submodule (intrn_mod) evbw_smod

  implicit none

  ! type :: evbw
  !   ! For Cubic
  !   real(wp) :: delw
  !   real(wp) :: prf
  !   real(wp) :: rmagmin
  !   ! For Reflc-bc
  !   real(wp) :: a
  !   integer,allocatable :: w_coll(:)
  !   integer,allocatable :: ia_time(:,:)
  ! contains
  !   procedure,pass(this) :: init => evbw_init
  !   procedure,pass(this) :: updt => evbw_updt
  !   procedure,pass(this) ::
  ! end type
  character(len=99),parameter :: fmt3xi="(1x,i3,1x,i3,1x,i7)"

contains

  module procedure init_evbw

    use :: inp_dlt, only: nseg,nbead,EV_bw,Aw,N_Ks,qmax,ntime,npchain,nchain,nbead_ind
    use :: cmn_io_mod, only: read_input

    ! Bead-wall excluded volume interaction
    select case (EV_bw)
    case ('Cubic')

      ! this%delw=0.5_wp*sqrt( (nseg**2-1._wp)/(2._wp*nseg) )
      this%delw=0.5_wp*sqrt( 3.0 )
      this%prf=Aw*N_Ks/(3*qmax*this%delw**2)
      this%rmagmin=1.e-7_wp ! The Minimum value accepted as the |rij|

    case ('Rflc_bc')

      this%delw=0.5_wp*sqrt( 3.0 )
      this%prf=Aw*N_Ks/(3*qmax*this%delw**2)


      call read_input('Bead-rad',0,this%a)
      call read_input('Wall-type',0,this%iwall)
      call read_input('hstar',0,this%hstar)
      allocate(this%w_coll(2:nbead_ind,npchain))
      allocate(this%w_coll_all(2:nbead_ind,npchain))
      allocate(this%ia_time(2:nbead_ind,500,npchain))

      ! Initializing the variables

      this%w_coll=0
      this%w_coll_all=0
      this%ia_time=1
      select case (this%iwall)
      case (1) !plane located at y=0
      case (2,3,4) !sphere
        call read_input('Sph-rad',0,this%a_sph)
      end select

      if (id == 0) then
        allocate(this%w_coll_t(2:nbead_ind,npchain))
        allocate(this%w_coll_all_t(2:nbead_ind,npchain))
        allocate(this%ia_time_t(2:nbead_ind,500,npchain))
        open(newunit=this%u_wc,file='data/w_coll.dat',status='replace',position='append')
        write(this%u_wc,*) "# chain index, bead index, Total number of collisions #"
        write(this%u_wc,*) "# --------------------------------------------------- #"
        open(newunit=this%u_wc_all,file='data/w_coll_all.dat',status='replace',position='append')
        write(this%u_wc_all,*) "# chain index, bead index, Total number of collisions #"
        write(this%u_wc_all,*) "# --------------------------------------------------- #"
        open(newunit=this%u_ia,file='data/ia_time.dat',status='replace',position='append')
        write(this%u_ia,*) "# chain index, bead index, Inter-arrival time unit #"
        write(this%u_ia,*) "# ------------------------------------------------ #"
      end if
      ! write(fnme,"(A,i0.2,'.dat')") 'data/ia_time',id

      ! allocate(this%ia_time_t(2:nbead))

      ! open(newunit=uarm(iarm),file=trim(adjustl(fnme)),&
      !      status='replace',position='append')
    end  select

  end procedure init_evbw

  module procedure calc_evbw

    use :: inp_dlt, only: EV_bw
    use :: arry_mod, only: print_vector, print_matrix

    !variables used inside calc_evbw
    integer :: osi
    real(wp),dimension(3) :: unit_beadsph
    real(wp) :: mag_beadsph,dist

    osi=3*(i-1)

    if (EV_bw == 'Cubic') then

      if (ry <= this%delw ) then
        Fev(osi+2)=Fev(osi+2)+3*this%prf*(ry-this%delw)**2
      end if

    elseif (EV_bw == 'Gaussian') then

    elseif (EV_bw == 'Rflc_bc') then
      ! call print_vector(Fev(osi+1:osi+3),'Fev before')
      ! call print_vector(Fev_sph(1:3),'Fev_sph before')

      ! unit_beadsph(1:3) = rjmrc(1:3) + rcmj(1:3) - r_sph(1:3)
      ! mag_beadsph = sqrt(unit_beadsph(1)**2 + unit_beadsph(2)**2 + unit_beadsph(3)**2)
      ! unit_beadsph(1) = unit_beadsph(1)/mag_beadsph
      ! unit_beadsph(2) = unit_beadsph(2)/mag_beadsph
      ! unit_beadsph(3) = unit_beadsph(3)/mag_beadsph
      ! dist = mag_beadsph - (this%a+this%a_sph)
      !
      !
      !
      ! if ((dist <= this%delw) .and. (dist>=0._wp)) then
      !   Fev(osi+1) = Fev(osi+1) + (3*this%prf*(dist-this%delw)**2) * unit_beadsph(1)
      !   Fev(osi+2) = Fev(osi+2) + (3*this%prf*(dist-this%delw)**2) * unit_beadsph(2)
      !   Fev(osi+3) = Fev(osi+3) + (3*this%prf*(dist-this%delw)**2) * unit_beadsph(3)
      !   Fev_sph(1) = Fev_sph(1) - (3*this%prf*(dist-this%delw)**2) * unit_beadsph(1)
      !   Fev_sph(2) = Fev_sph(2) - (3*this%prf*(dist-this%delw)**2) * unit_beadsph(2)
      !   Fev_sph(3) = Fev_sph(3) - (3*this%prf*(dist-this%delw)**2) * unit_beadsph(3)
      ! elseif (dist < 0._wp) then
      !   Fev(osi+1) = Fev(osi+1) + (3*this%prf*(0._wp-this%delw)**2) * unit_beadsph(1)
      !   Fev(osi+2) = Fev(osi+2) + (3*this%prf*(0._wp-this%delw)**2) * unit_beadsph(2)
      !   Fev(osi+3) = Fev(osi+3) + (3*this%prf*(0._wp-this%delw)**2) * unit_beadsph(3)
      !   Fev_sph(1) = Fev_sph(1) - (3*this%prf*(0._wp-this%delw)**2) * unit_beadsph(1)
      !   Fev_sph(2) = Fev_sph(2) - (3*this%prf*(0._wp-this%delw)**2) * unit_beadsph(2)
      !   Fev_sph(3) = Fev_sph(3) - (3*this%prf*(0._wp-this%delw)**2) * unit_beadsph(3)
      ! end if

      ! call print_vector(Fev(osi+1:osi+3),'Fev after')
      ! call print_vector(Fev_sph(1:3),'Fev_sph after')

    end if ! EV_bw

  end procedure calc_evbw

  module procedure wall_rflc_sph

    use :: inp_dlt, only: nchain_pp

    integer :: ichain_pp
    real(wp) :: r_mag_s_xz,R_pore,shift
    real(wp),dimension(3) :: dr_sph
    logical :: coll_detect_sw

    dr_sph(:) = 0._wp
    R_pore = 6.25_wp
    coll_detect_sw = .FALSE.

    if ((this%iwall == 3).or.(this%iwall == 4)) then
      r_mag_s_xz = sqrt(r_sph(1)**2 + r_sph(3)**2)
      coll_detect_sw = ((r_mag_s_xz + this%a_sph) > R_pore)
      !print *, 'r_mag_s_xz +this%a_sph = ', (this%a_sph)
      if (coll_detect_sw) then
        !print *, 'sphere wall collision!'
        !call print_vector(r_mag_s_xz - sqrt(rf0(1)**2 + rf0(3)**2),'diff (before) = ')
        shift = r_mag_s_xz - (R_pore - this%a_sph)
        dr_sph(1) = - 2._wp * shift * r_sph(1)/r_mag_s_xz
        dr_sph(3) = - 2._wp * shift * r_sph(3)/r_mag_s_xz

        r_sph(1) = r_sph(1) + dr_sph(1)
        r_sph(3) = r_sph(3) + dr_sph(3)

        !shouldn't this affect the first spring as well?
        do ichain_pp=1,nchain_pp
          rf0(1,ichain_pp) = rf0(1,ichain_pp) + dr_sph(1)
          rf0(3,ichain_pp) = rf0(3,ichain_pp) + dr_sph(3)
        end do
        !call print_vector(sqrt(r_sph(1)**2 + r_sph(3)**2) - sqrt(rf0(1)**2 + rf0(3)**2),'diff (after) = ')
      endif
    endif

  end procedure wall_rflc_sph

  module procedure wall_rflc

    use :: mpi
    use :: inp_dlt, only: nbead,qmax,tplgy,npchain,lambda,tss,nbead_ind,nchain_pp
    use :: arry_mod, only: print_vector

    integer :: ib,ierr,sz,sz_t
    integer,allocatable :: ia_tmp(:,:,:)
    logical :: coll_detect_bs,coll_detect_bw,coll_detect_sw
    real(wp) :: shift,r_mag_bs,r_mag_s_xz,r_mag_b_xz, R_pore
    real(wp),dimension(3) :: dr_sph
    real(wp),parameter :: PI=3.1415926535897958648_wp
    real(wp),parameter :: sqrtPI=sqrt(PI)
    real(wp) :: corr

    !dr_sph(:) = 0._wp
    R_pore = 6.25_wp
    coll_detect_bs = .FALSE.
    coll_detect_bw = .FALSE.
    !coll_detect_sw = .FALSE.
    if ((it == 1)) then
      this%w_coll(:,ich)=0
      this%w_coll_all(:,ich)=0
      this%ia_time(:,:,ich)=1
    endif

    ! To save memory, rcmy is added to Rvy to get rvy
    Rx=Rx+rcmx
    Ry=Ry+rcmy
    Rz=Rz+rcmz

    !this%w_coll=this%w_coll-floor( Ry(2:nbead)/qmax )
    ! do ib=2, nbead
    !   this%ia_time(ib,this%w_coll(ib)) = &
    !   this%ia_time(ib,this%w_coll(ib))+1+floor( Ry(ib)/qmax )
    ! end do

    !Ry=abs(Ry)-2*this%a*floor( Ry/qmax )

    ! ! Reflection of the first bead
    ! if (Ry(1) < this%a) then
    !   !Ry(1)=2*this%a - Ry(1)
    !   Ry(1)=rf_in(2)
    !   select case (tplgy)
    !   case ('Linear')
    !     qy(1)=Ry(2)-Ry(1)
    !   case ('Comb')
    !   end select
    ! endif

    ! !reflecting the center sphere
    ! if ((this%iwall == 3).or.(this%iwall == 4)) then
    !   r_mag_s_xz = sqrt(r_sph(1)**2 + r_sph(3)**2)
    !   coll_detect_sw = ((r_mag_s_xz + this%a_sph) > R_pore)
    !   !print *, 'r_mag_s_xz +this%a_sph = ', (this%a_sph)
    !   if (coll_detect_sw) then
    !     !print *, 'sphere wall collision!'
    !     !call print_vector(r_mag_s_xz - sqrt(rf0(1)**2 + rf0(3)**2),'diff (before) = ')
    !     shift = r_mag_s_xz - (R_pore - this%a_sph)
    !     dr_sph(1) = - 2._wp * shift * r_sph(1)/r_mag_s_xz
    !     dr_sph(3) = - 2._wp * shift * r_sph(3)/r_mag_s_xz
    !
    !     r_sph(1) = r_sph(1) + dr_sph(1)
    !     r_sph(3) = r_sph(3) + dr_sph(3)
    !
    !     rf0(1) = rf0(1) + dr_sph(1)
    !     rf0(3) = rf0(3) + dr_sph(3)
    !     !call print_vector(sqrt(r_sph(1)**2 + r_sph(3)**2) - sqrt(rf0(1)**2 + rf0(3)**2),'diff (after) = ')
    !   endif
    ! endif

    ! Reflection of the first bead
    Rx(1)=rf0(1)
    Ry(1)=rf0(2)
    Rz(1)=rf0(3)

    select case (tplgy)
    case ('Linear')
      qx(1)=Rx(2)-Rx(1)
      qy(1)=Ry(2)-Ry(1)
      qz(1)=Rz(2)-Rz(1)
    case ('Comb')
    end select

    rcmx=Rx(1)
    rcmy=Ry(1)
    rcmz=Rz(1)

    do ib=2, nbead_ind
      select case (this%iwall)
      case (1)
        coll_detect_bs = (Ry(ib) < this%a)
        !print *, 'plane wall'
      case (3,4)
        r_mag_b_xz = sqrt(Rx(ib)**2 + Rz(ib)**2)
        coll_detect_bw = ((r_mag_b_xz + this%a) > R_pore)
      end select

      if (coll_detect_bw) then
        if ((this%iwall == 3).or.(this%iwall == 4)) then
          shift = r_mag_b_xz - (R_pore - this%a)
          Rx(ib)=Rx(ib) - 2._wp * shift * Rx(ib)/r_mag_b_xz
          Rz(ib)=Rz(ib) - 2._wp * shift * Rz(ib)/r_mag_b_xz
          select case (tplgy)
            case ('Linear')
              qx(ib-1)=Rx(ib)-Rx(ib-1)
              qy(ib-1)=Ry(ib)-Ry(ib-1)
              qz(ib-1)=Rz(ib)-Rz(ib-1)
              if (ib < nbead_ind) then
                qx(ib)=Rx(ib+1)-Rx(ib)
                qy(ib)=Ry(ib+1)-Ry(ib)
                qz(ib)=Rz(ib+1)-Rz(ib)
              endif
            case ('Comb')
          end select

        end if
      end if

      select case (this%iwall)
      case (1)
        coll_detect_bs = (Ry(ib) < this%a)
        !print *, 'plane wall'
      case (2,3,4)
        r_mag_bs = sqrt((Rx(ib)-r_sph(1))**2+(Ry(ib)-r_sph(2))**2+(Rz(ib)-r_sph(3))**2)
        coll_detect_bs = (r_mag_bs < (this%a + this%a_sph))
      end select

      if (coll_detect_bs) then
        if (time>lambda*tss) then
          !all collisions are recorded here
          this%w_coll_all(ib,ich)=this%w_coll_all(ib,ich)+1

          !if ia time is less than some fraction of a relaxation time, record.
          !if (this%ia_time(ib,this%w_coll(ib,ich)+1,ich) > int(lambda/dt/100._wp)) then !Macromol paper
          if (this%ia_time(ib,this%w_coll(ib,ich)+1,ich) > int(lambda/dt/1._wp)) then
            this%w_coll(ib,ich)=this%w_coll(ib,ich)+1
          else
            this%ia_time(ib,this%w_coll(ib,ich)+1,ich) = 1
          endif
        endif

        select case (this%iwall)
        case (1)
          Ry(ib)=2*this%a - Ry(ib)
        case (2,3,4)
          shift = this%a + this%a_sph - r_mag_bs

          !print *, ''
          !print *, 'ibead = ',ib
          !print *, 'shift amount:', shift
          !print *, 'particle shift:',-((sqrtPI*this%hstar)/(this%a_sph+sqrtPI*this%hstar))*shift
          !print *, 'bead shift:',(this%a_sph/(this%a_sph+sqrtPI*this%hstar))*shift

          !collision approximately keeping center of hydrodynamic resistance constant
          !don't change R first, since that changes the unit vector length
          ! dr_sph_rflc(1)=dr_sph_rflc(1) - ((sqrtPI*this%hstar)/(this%a_sph+(nbead-nchain_pp)*sqrtPI*this%hstar))*&
          !   shift*(Rx(ib)-r_sph(1))/r_mag_bs
          ! dr_sph_rflc(2)=dr_sph_rflc(2) - ((sqrtPI*this%hstar)/(this%a_sph+(nbead-nchain_pp)*sqrtPI*this%hstar))*&
          !   shift*(Ry(ib)-r_sph(2))/r_mag_bs
          ! dr_sph_rflc(3)=dr_sph_rflc(3) - ((sqrtPI*this%hstar)/(this%a_sph+(nbead-nchain_pp)*sqrtPI*this%hstar))*&
          !   shift*(Rz(ib)-r_sph(3))/r_mag_bs
          ! Rx(ib)=Rx(ib) + (1._wp)*shift*(Rx(ib)-r_sph(1))/r_mag_bs
          ! Ry(ib)=Ry(ib) + (1._wp)*shift*(Ry(ib)-r_sph(2))/r_mag_bs
          ! Rz(ib)=Rz(ib) + (1._wp)*shift*(Rz(ib)-r_sph(3))/r_mag_bs


          ! if (ib == 2) then

          !corr = 0.278337291378604_wp
          corr = 1._wp
          !corr = 0.5_wp
          !print *, '(sqrtPI*this%hstar/corr)=',(sqrtPI*this%hstar/corr)
          !print *, '(this%a_sph+sqrtPI*this%hstar/corr)',(this%a_sph+sqrtPI*this%hstar/corr)



          ! print *, 'bead id = ', ib
          ! print *, 'shift = ',shift
          !
          ! print *, 'dRx = ', 2._wp*(this%a_sph/(this%a_sph+sqrtPI*this%hstar/corr))*shift*(Rx(ib)-r_sph(1))/r_mag_bs
          ! print *, 'dRy = ', 2._wp*(this%a_sph/(this%a_sph+sqrtPI*this%hstar/corr))*shift*(Ry(ib)-r_sph(2))/r_mag_bs
          ! print *, 'dRz = ', 2._wp*(this%a_sph/(this%a_sph+sqrtPI*this%hstar/corr))*shift*(Rz(ib)-r_sph(3))/r_mag_bs



          
          dr_sph_rflc(1)=dr_sph_rflc(1) - 1._wp*((sqrtPI*this%hstar/corr)/(this%a_sph+sqrtPI*this%hstar/corr))*&
            shift*(Rx(ib)-r_sph(1))/r_mag_bs
          dr_sph_rflc(2)=dr_sph_rflc(2) - 1._wp*((sqrtPI*this%hstar/corr)/(this%a_sph+sqrtPI*this%hstar/corr))*&
            shift*(Ry(ib)-r_sph(2))/r_mag_bs
          dr_sph_rflc(3)=dr_sph_rflc(3) - 1._wp*((sqrtPI*this%hstar/corr)/(this%a_sph+sqrtPI*this%hstar/corr))*&
            shift*(Rz(ib)-r_sph(3))/r_mag_bs
          Rx(ib)=Rx(ib) + 1._wp*(this%a_sph/(this%a_sph+sqrtPI*this%hstar/corr))*shift*(Rx(ib)-r_sph(1))/r_mag_bs
          Ry(ib)=Ry(ib) + 1._wp*(this%a_sph/(this%a_sph+sqrtPI*this%hstar/corr))*shift*(Ry(ib)-r_sph(2))/r_mag_bs
          Rz(ib)=Rz(ib) + 1._wp*(this%a_sph/(this%a_sph+sqrtPI*this%hstar/corr))*shift*(Rz(ib)-r_sph(3))/r_mag_bs

          !call print_vector(dr_sph_rflc(:),'dr_sph_rflc(:) = ')
          !print *, '------------------------------'

          ! else
          !   !elastic collision:
          !   Rx(ib)=Rx(ib) + 1*shift*(Rx(ib)-r_sph(1))/r_mag_bs
          !   Ry(ib)=Ry(ib) + 1*shift*(Ry(ib)-r_sph(2))/r_mag_bs
          !   Rz(ib)=Rz(ib) + 1*shift*(Rz(ib)-r_sph(3))/r_mag_bs
          ! end if

        end select

        select case (tplgy)
          case ('Linear')
            qx(ib-1)=Rx(ib)-Rx(ib-1)
            qy(ib-1)=Ry(ib)-Ry(ib-1)
            qz(ib-1)=Rz(ib)-Rz(ib-1)
            if (ib < nbead_ind) then
              qx(ib)=Rx(ib+1)-Rx(ib)
              qy(ib)=Ry(ib+1)-Ry(ib)
              qz(ib)=Rz(ib+1)-Rz(ib)
            endif
          case ('Comb')
        end select

      endif



      if ((coll_detect_bs==.false.)) then
        if (time>lambda*tss) then
          this%ia_time(ib,this%w_coll(ib,ich)+1,ich) = &
          this%ia_time(ib,this%w_coll(ib,ich)+1,ich) + 1
        end if
      end if


      sz=size(this%ia_time,dim=2)

      if ( this%w_coll(ib,ich)+1 > sz ) then
        print '(" Geometric resizing of ia_time array... in rank: ",i5)',id
        sz=2*size(this%ia_time,dim=2)
        allocate(ia_tmp(2:nbead_ind,sz,npchain))
        ia_tmp=1
        ia_tmp(:,1:sz/2,:)=this%ia_time(:,:,:)
        call move_alloc(from=ia_tmp,to=this%ia_time)
      endif

      call MPI_Reduce(sz,sz_t,1,MPI_INTEGER,MPI_MAX,0,MPI_COMM_WORLD,ierr)

      if (id == 0) then
        if ( sz_t > size(this%ia_time_t,dim=2) ) then
          print '(" Geometric resizing of ia_time_t array: ",i5)',id
          allocate(ia_tmp(2:nbead_ind,sz_t,npchain))
          ! ia_tmp=1
          ! ia_tmp(1:sz_t/2)=this%ia_time_t
          call move_alloc(from=ia_tmp,to=this%ia_time_t)
        endif
      endif

      rcmx=rcmx+Rx(ib)
      rcmy=rcmy+Ry(ib)
      rcmz=rcmz+Rz(ib)
    end do
    rcmx=rcmx/nbead_ind
    rcmy=rcmy/nbead_ind
    rcmz=rcmz/nbead_ind
    Rx=Rx-rcmx
    Ry=Ry-rcmy
    Rz=Rz-rcmz

  end procedure wall_rflc

  module procedure del_evbw

    use :: inp_dlt, only: EV_bw

    select case (EV_bw)
      case ('Cubic')
      case ('Rflc_bc')

        deallocate(this%w_coll)
        deallocate(this%ia_time)

        if (id == 0) then
          deallocate(this%w_coll_t)
          deallocate(this%ia_time_t)
        endif
    end  select

  end procedure del_evbw

  module procedure print_wcll

    use :: mpi
    use :: inp_dlt, only: nbead,npchain,ntime,tss,lambda,nbead_ind
    use :: arry_mod, only: print_vector

    integer :: ich,ib,iwc,osch,ierr,ncount_wc,ncount_ia,iproc,tag


    ncount_wc=(nbead_ind-1)*npchain
    ncount_ia=(nbead_ind-1)*size(this%ia_time,dim=2)*npchain

    if (id == 0) then

      write(this%u_wc,'(" TIME SINCE tss: ",f9.2)') time-lambda*tss
      write(this%u_wc_all,'(" TIME SINCE tss: ",f9.2)') time-lambda*tss
      write(this%u_ia,'(" TIME SINCE tss: ",f9.2)') time-lambda*tss

      do ich=1, npchain
        do ib=2,nbead_ind
          write(this%u_wc,fmt3xi) ich,ib,this%w_coll(ib,ich)
          write(this%u_wc_all,fmt3xi) ich,ib,this%w_coll_all(ib,ich)
          do iwc=1, this%w_coll(ib,ich)
            write(this%u_ia,fmt3xi) ich,ib,this%ia_time(ib,iwc,ich)
          enddo
        enddo
      enddo

      ncount_ia=(nbead_ind-1)*size(this%ia_time_t,dim=2)*npchain

      do iproc=1, nproc-1

        tag=1100+iproc

        call MPI_Recv(this%w_coll_t,ncount_wc,MPI_INTEGER,iproc,tag,&
          MPI_COMM_WORLD,MPI_STATUS_IGNORE,ierr)

        call MPI_Recv(this%w_coll_all_t,ncount_wc,MPI_INTEGER,iproc,tag,&
          MPI_COMM_WORLD,MPI_STATUS_IGNORE,ierr)

        call MPI_Recv(this%ia_time_t,ncount_ia,MPI_INTEGER,iproc,tag,&
          MPI_COMM_WORLD,MPI_STATUS_IGNORE,ierr)

        osch=iproc*npchain

        do ich=1, npchain
          do ib=2,nbead_ind
            write(this%u_wc,fmt3xi) osch+ich,ib,this%w_coll_t(ib,ich)
            write(this%u_wc_all,fmt3xi) osch+ich,ib,this%w_coll_all_t(ib,ich)
            do iwc=1, this%w_coll_t(ib,ich)
              write(this%u_ia,fmt3xi) osch+ich,ib,this%ia_time_t(ib,iwc,ich)
            enddo
          enddo
        enddo

      enddo

    else

      tag=1100+id

      call MPI_Send(this%w_coll,ncount_wc,MPI_INTEGER,0,tag,&
        MPI_COMM_WORLD,ierr)
      call MPI_Send(this%w_coll_all,ncount_wc,MPI_INTEGER,0,tag,&
        MPI_COMM_WORLD,ierr)
      call MPI_Send(this%ia_time,ncount_ia,MPI_INTEGER,0,tag,&
        MPI_COMM_WORLD,ierr)

    endif

    ! wait untill receiving all values
    call MPI_Barrier(MPI_COMM_WORLD,ierr)



    ! call MPI_Reduce(this%w_coll,this%w_coll_t,nbead-1,&
    !                   MPI_INTEGER,MPI_SUM,0,MPI_COMM_WORLD,ierr)



    ! call MPI_Reduce(this%w_coll,w_cll_tot,nbead-1,MPI_REAL_WP,&
    !   MPI_SUM,0,MPI_COMM_WORLD,ierr)
    ! if (id==0) then
    ! call print_vector(this%w_coll,'collisionsid0')
    ! else
    ! call print_vector(this%w_coll,'collisionsid1')
    ! endif
    ! if (id == 0) then
    !   write(this%u_wc,'(" TIME: ",f9.2)') time
    !   do ib=2,nbead
    !     write(this%u_wc,fmtii) ib,this%w_coll_t(ib)
    !   enddo
      ! call print_vector(this%w_coll_t,'total collisions')
    ! endif

  end procedure print_wcll


end submodule
