! submodule (intrn_mod:hi_smod) hibw_smod
module hibw_smod

  use :: prcn_mod

  implicit none

  type :: hibw_t
    real(wp) :: a_sph
  end type hibw_t

contains


  ! ! module procedure init_hibw
  ! subroutine init_hibw(this)
  !   class(hibw_t),intent(inout) :: this
  !   !add later
  ! ! end procedure init_hibw
  ! end subroutine init_hibw

  subroutine init_hibw(this)

    use :: inp_dlt, only: HITens
    use :: cmn_io_mod, only: read_input

    class(hibw_t),intent(inout) :: this

    select case (HITens)
    case('Blake')
    case('Osph') !sphere
      call read_input('Sph-rad',0,this%a_sph)
    end select

  end subroutine init_hibw

  ! module procedure calc_hibw
  subroutine calc_hibw(this,i,j,rij,DiffTens)

    use :: inp_dlt, only: HITens, hstar
    use :: arry_mod, only: print_vector, print_matrix
    use :: cmn_tp_mod, only: dis

    class(hibw_t),intent(inout) :: this
    integer,intent(in) :: i,j
    type(dis),intent(in) :: rij
    real(wp),intent(inout) :: DiffTens(:,:)

    real(wp),parameter :: PI=3.1415926535897958648_wp
    real(wp),parameter :: sqrtPI=sqrt(PI)

    integer :: osi,osj
    real(wp) :: rijmag3im, rijmag5im, rijmag7im
    real(wp), dimension(3,3) :: Sij,Pij_D,Sij_D,Hij_PD,Hji_PD
    real(wp), dimension(3,3) :: Omega_PF,Omegaij_PD,Omegaji_PD,Omega_c, Omega_W
    real(wp), dimension(3,3) :: dpdx, G_sph

    osi=3*(i-1)
    osj=3*(j-1)

    select case (HITens)
    case('Blake')
      rijmag3im = rij%mag2im*rij%magim
      rijmag5im = rij%mag2im*rijmag3im
      rijmag7im = rij%mag2im*rijmag5im

      call Sij_calc(Sij,rij,rijmag3im,rijmag5im,rijmag7im)
      call Pij_D_calc(Pij_D,rij,rijmag3im,rijmag5im,rijmag7im)
      call Sij_D_calc(Sij_D,rij,rijmag3im,rijmag5im,rijmag7im)
      call H_PD_calc(Hij_PD,rij,rijmag3im,rijmag5im,rijmag7im,rij%x,rij%yim,rij%z,rij%rjy)
      call H_PD_calc(Hji_PD,rij,rijmag3im,rijmag5im,rijmag7im,-rij%x,rij%yim,-rij%z,rij%riy)

      Omega_PF = (3*sqrtPI*hstar/4)*(-Sij + 2*(rij%rjy**2)*Pij_D - 2*rij%rjy*Sij_D)
      Omegaij_PD = (3*sqrtPI*hstar/4)*Hij_PD
      Omegaji_PD = (3*sqrtPI*hstar/4)*Hji_PD
      Omega_c = (1._wp/2)*(Omegaij_PD+TRANSPOSE(Omegaji_PD))
      Omega_W = Omega_PF - (2*((sqrtPI*hstar)**2)/3)*Omega_c

      DiffTens(osi+1:osi+3,osj+1:osj+3) = DiffTens(osi+1:osi+3,osj+1:osj+3) &
                                        + Omega_W

    case('Osph')

      call G_sph_Calc(G_sph,dpdx,this%a_sph,rij)
      DiffTens(osi+1:osi+3,osj+1:osj+3) = DiffTens(osi+1:osi+3,osj+1:osj+3) + &
        (3*sqrtPI*hstar/4) * G_sph

      ! if ((i==j) .and. &
      !   ( (sqrt(rij%rjx**2+rij%rjy**2+rij%rjz**2)-this%a_sph) < (1.5_wp * sqrtPI*hstar) ) ) then
      !
      !   DiffTens(osi+1:osi+3,osj+1:osj+3) = 0.0_wp
      !
      ! else
      !   call G_sph_Calc(G_sph,dpdx,this%a_sph,rij)
      !   DiffTens(osi+1:osi+3,osj+1:osj+3) = DiffTens(osi+1:osi+3,osj+1:osj+3) + &
      !     (3*sqrtPI*hstar/4) * G_sph
      ! endif



      !print *, 'i=',i,' j=',j
      !print *, 'pt force (j): ', rij%rjx, rij%rjy, rij%rjz
      !print *, 'velocity (i): ', rij%rix, rij%riy, rij%riz
      !call print_matrix(DiffTens(osi+1:osi+3,osj+1:osj+3),'DiffTens')

      !call print_matrix(dpdx,'dpdx tensor')
      !call print_matrix(G_sph,'G_sph tensor')

    end select

  ! end procedure calc_hibw
  end subroutine calc_hibw


! below are helper functions ---------------------------------------------------

  !calculate the Green's function for point force outside of a sphere
  subroutine G_sph_Calc(G_sphTens,dpdxTens,a_sph,rij)

    use :: cmn_tp_mod, only: dis

    real(wp), intent(inout) :: G_sphTens(:,:),dpdxTens(:,:)
    type(dis), intent(in) :: rij
    real(wp), intent(in) :: a_sph

    integer :: i,j

    !variables where all three components are needed
    real(wp) :: x_x,x_y,x_z
    real(wp) :: xx_star_x,xx_star_y,xx_star_z
    real(wp) :: x_hat_star_x,x_hat_star_y,x_hat_star_z
    real(wp) :: rr,rr_star,r,r_star
    real(wp) :: x_mag

    !variables where only i and j components are needed
    real(wp) :: xx_i,xx_j
    real(wp) :: x_i,x_j
    real(wp) :: xx_star_i,xx_star_j
    real(wp) :: x_hat_i,x_hat_j
    real(wp) :: x_hat_star_i,x_hat_star_j
    real(wp) :: dij

    !calculate distances needed
    x_x = rij%rix
    x_y = rij%riy
    x_z = rij%riz

    rr = sqrt(rij%rjx**2 + rij%rjy**2 + rij%rjz**2)
    xx_star_x = (a_sph**2) * rij%rjx / (rr**2)
    xx_star_y = (a_sph**2) * rij%rjy / (rr**2)
    xx_star_z = (a_sph**2) * rij%rjz / (rr**2)
    rr_star = sqrt(xx_star_x**2 + xx_star_y**2 + xx_star_z**2)

    x_hat_star_x = rij%rix - xx_star_x
    x_hat_star_y = rij%riy - xx_star_y
    x_hat_star_z = rij%riz - xx_star_z
    r_star = sqrt(x_hat_star_x**2 + x_hat_star_y**2 + x_hat_star_z**2)

    r = rij%mag
    x_mag = sqrt(rij%rix**2 + rij%riy**2 + rij%riz**2)

    !using the language of Pozrikidis (Boundary Integral and Singularity Methods for Linearized Viscous Flow)
    !but there seems to be a typo in Pozrikidis, so the Green's function is implemented from
    !Jiang, H., Meneveau, C., & Osborn, T. (1999). Numerical study of the feeding current around a copepod. Journal of Plankton Research, 21(8), 1391–1421.
    !http://doi.org/10.1093/plankt/21.8.1391

    do i=1,3
      do j=1,3

        if (i==j) then
          dij = 1.0_wp
        else
          dij = 0.0_wp
        end if

        select case (i)
        case (1)
          xx_i = rij%rjx
          x_i = x_x
          xx_star_i = xx_star_x
          x_hat_i = rij%x
          x_hat_star_i = x_hat_star_x
        case (2)
          xx_i = rij%rjy
          x_i = x_y
          xx_star_i = xx_star_y
          x_hat_i = rij%y
          x_hat_star_i = x_hat_star_y
        case (3)
          xx_i = rij%rjz
          x_i = x_z
          xx_star_i = xx_star_z
          x_hat_i = rij%z
          x_hat_star_i = x_hat_star_z
        end select

        select case (j)
        case (1)
          xx_j = rij%rjx
          x_j = x_x
          xx_star_j = xx_star_x
          x_hat_j = rij%x
          x_hat_star_j = x_hat_star_x
        case (2)
          xx_j = rij%rjy
          x_j = x_y
          xx_star_j = xx_star_y
          x_hat_j = rij%y
          x_hat_star_j = x_hat_star_y
        case (3)
          xx_j = rij%rjz
          x_j = x_z
          xx_star_j = xx_star_z
          x_hat_j = rij%z
          x_hat_star_j = x_hat_star_z
        end select

        dpdxTens(i,j) = -3*xx_j*(x_hat_star_i/(a_sph*(r_star**3))) + &
            a_sph*dij/(r_star**3) - &
            3*a_sph*x_hat_star_i*x_hat_star_j / (r_star**5) - &
            2*xx_star_i*xx_j/(a_sph*r_star**3) + &
            6*xx_j*x_hat_star_i*(xx_star_x*x_hat_star_x + xx_star_y*x_hat_star_y + xx_star_z*x_hat_star_z)/(a_sph*r_star**5) + &
            (3*a_sph/rr_star)*(xx_star_j*x_hat_star_i*(r_star**2) + x_hat_star_i*x_hat_star_j*(rr_star**2) + (r_star-rr_star)*(r_star**2)*rr_star*dij)/ &
                ((r_star**3)*rr_star*(rr_star*r_star + x_x*xx_star_x + x_y*xx_star_y + x_z*xx_star_z - rr_star**2)) - &
            (3*a_sph/rr_star)*((rr_star*x_hat_star_i + r_star*xx_star_i)*(xx_star_j*(r_star**2) - x_hat_star_j*(rr_star**2) + (x_hat_star_j-xx_star_j)*r_star*rr_star))/ &
                ((r_star**2)*rr_star*((rr_star*r_star + x_x*xx_star_x + x_y*xx_star_y + x_z*xx_star_z - rr_star**2)**2)) - &
            3*a_sph* (x_i*xx_star_j + dij*x_mag*rr_star)/ (x_mag*(rr_star**2)*(x_mag*rr_star + x_x*xx_star_x + x_y*xx_star_y + x_z*xx_star_z)) + &
            3*a_sph* (rr_star*x_i + x_mag*xx_star_i)*(rr_star*x_j + x_mag*xx_star_j)/ &
                (x_mag*(rr_star**2)*((x_mag*rr_star + x_x*xx_star_x + x_y*xx_star_y + x_z*xx_star_z)**2))

        !the point force Stokeslet is already accounted for in hibb
        !(dij/r + x_hat_i*x_hat_j/r**3)
        G_sphTens(i,j) =  0.0_wp - &
            a_sph*dij/(rr*r_star) - &
            ((a_sph**3)/rr**3)*(x_hat_star_i*x_hat_star_j / (r_star**3)) - &
            ((rr**2-a_sph**2)/rr) * (xx_star_i*xx_star_j*(1/((a_sph**3) * r_star) + 2*(xx_star_x*x_hat_star_x + xx_star_y*x_hat_star_y + xx_star_z*x_hat_star_z)/((a_sph**3) * (r_star**3))) - &
                (a_sph/(rr**2))* (xx_star_j*x_hat_star_i + xx_star_i*x_hat_star_j)/(r_star**3)) - &
            ((x_mag**2 - a_sph**2)*(rr**2 - a_sph**2)/(2*(rr**3))*dpdxTens(i,j));

      end do
    end do
  end subroutine G_sph_Calc


  subroutine Sij_Calc(SijTens,rij,rijmag3im,rijmag5im,rijmag7im)

    !use :: arry_mod, only: print_vector, print_matrix
    use :: cmn_tp_mod, only: dis

    real(wp), intent(inout) :: SijTens(:,:)
    type(dis),intent(in) :: rij
    real(wp), intent(in) :: rijmag3im,rijmag5im,rijmag7im

    SijTens(1,1) = 1/rij%magim + rij%x * rij%x   / rijmag3im
    SijTens(1,2) = 0           + rij%x * rij%yim / rijmag3im
    SijTens(1,3) = 0           + rij%x * rij%z   / rijmag3im

    SijTens(2,1) = 0           + rij%x   * rij%yim / rijmag3im
    SijTens(2,2) = 1/rij%magim + rij%yim * rij%yim / rijmag3im
    SijTens(2,3) = 0           + rij%yim * rij%z   / rijmag3im

    SijTens(3,1) = 0           + rij%x   * rij%z / rijmag3im
    SijTens(3,2) = 0           + rij%yim * rij%z / rijmag3im
    SijTens(3,3) = 1/rij%magim + rij%z   * rij%z / rijmag3im
    !call print_matrix(SijTens,'Sij tensor')

  end subroutine Sij_Calc

  subroutine Pij_D_Calc(Pij_DTens,rij,rijmag3im,rijmag5im,rijmag7im)

    !use :: arry_mod, only: print_vector, print_matrix
    use :: cmn_tp_mod, only: dis

    real(wp), intent(inout) :: Pij_DTens(:,:)
    type(dis),intent(in) :: rij
    real(wp), intent(in) :: rijmag3im,rijmag5im,rijmag7im

    Pij_DTens(1,1) =   1/rijmag3im - 3*rij%x * rij%x  /rijmag5im
    Pij_DTens(1,2) = -(0           - 3*rij%x * rij%yim/rijmag5im)
    Pij_DTens(1,3) =   0           - 3*rij%x * rij%z  /rijmag5im

    Pij_DTens(2,1) =   0           - 3*rij%x   * rij%yim/rijmag5im
    Pij_DTens(2,2) = -(1/rijmag3im - 3*rij%yim * rij%yim/rijmag5im)
    Pij_DTens(2,3) =   0           - 3*rij%yim * rij%z  /rijmag5im

    Pij_DTens(3,1) =   0           - 3*rij%x   * rij%z/rijmag5im
    Pij_DTens(3,2) = -(0           - 3*rij%yim * rij%z/rijmag5im)
    Pij_DTens(3,3) =   1/rijmag3im - 3*rij%z   * rij%z/rijmag5im

    !call print_matrix(Pij_DTens,'Pij_D tensor')
  end subroutine Pij_D_Calc

  subroutine Sij_D_Calc(Sij_DTens,rij,rijmag3im,rijmag5im,rijmag7im)    

    !use :: arry_mod, only: print_vector, print_matrix
    use :: cmn_tp_mod, only: dis

    real(wp), intent(inout) :: Sij_DTens(:,:)
    type(dis),intent(in) :: rij
    real(wp), intent(in) :: rijmag3im,rijmag5im,rijmag7im

    call Pij_D_Calc(Sij_DTens,rij,rijmag3im,rijmag5im,rijmag7im)

    Sij_DTens = rij%yim * Sij_DTens

    Sij_DTens(1,1) = Sij_DTens(1,1)
    Sij_DTens(1,2) = Sij_DTens(1,2) - (rij%x /rijmag3im)
    Sij_DTens(1,3) = Sij_DTens(1,3)

    Sij_DTens(2,1) = Sij_DTens(2,1) + (-rij%x /rijmag3im)
    Sij_DTens(2,2) = Sij_DTens(2,2)
    Sij_DTens(2,3) = Sij_DTens(2,3) + (-rij%z /rijmag3im)

    Sij_DTens(3,1) = Sij_DTens(3,1)
    Sij_DTens(3,2) = Sij_DTens(3,2) - (rij%z /rijmag3im)
    Sij_DTens(3,3) = Sij_DTens(3,3)
    !call print_matrix(Sij_DTens,'Sij_D tensor')
  end subroutine Sij_D_Calc


  subroutine H_PD_Calc(HTens,rij,rijmag3im,rijmag5im,rijmag7im,x,yim,z,ry)

    !use :: arry_mod, only: print_vector, print_matrix
    use :: cmn_tp_mod, only: dis

    real(wp), intent(inout) :: HTens(:,:)
    type(dis),intent(in) :: rij
    real(wp), intent(in) :: rijmag3im,rijmag5im,rijmag7im
    real(wp), intent(in) :: x,yim,z,ry

    HTens(1,1) = (1/rijmag3im) &
                 - 3*(x**2)/rijmag5im &
                 - 6*(yim)*(yim - ry) / rijmag5im &
                 + 30*(x**2)*(yim)*(yim - ry)/rijmag7im

    HTens(1,3) = - 3* (x)* (z) / rijmag5im  &
                 + 30*(x)*(z)*(yim)*(yim - ry)/rijmag7im

    HTens(3,1) = HTens(1,3)

    HTens(1,2) = (x)*(9*(yim) - 6*(ry))/ rijmag5im &
                 -30*(x)*(yim**2)*(yim - ry) /rijmag7im

    HTens(3,3) = (1/rijmag3im) &
                 - 3*(z**2)/rijmag5im &
                 - 6*(yim)*(yim - ry) / rijmag5im &
                 + 30*(z**2)*(yim)*(yim - ry)/rijmag7im

    HTens(3,2) = (z)*(9*(yim) - 6*(ry))/ rijmag5im &
                 -30*(z)*(yim**2)*(yim - ry) /rijmag7im

    HTens(2,1) = -3*(x) * (yim - 2*ry) / rijmag5im &
                 +30*(x)*(yim**2)*(yim - ry) /rijmag7im

    HTens(2,3) = -3*(z) * (yim - 2*ry) / rijmag5im &
                 +30*(z)*(yim**2)*(yim - ry) /rijmag7im

    HTens(2,2) = (1/rijmag3im) &
                 + 3*(yim)*(5*yim - 6*ry) / rijmag5im &
                 - 30*(yim**3)*(yim - ry)/rijmag7im

    !call print_matrix(HTens,'H tensor')
  end subroutine H_PD_Calc


! end submodule hibw_smod
end module hibw_smod
