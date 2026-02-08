program hello
    implicit none
    integer :: amount
    real :: pi,radius, height, area, volumn
    complex :: frequently
    character(len=5) :: initial
    logical :: isokay

    amount = 10
    pi = 3.14
    frequently = (1.0,-3.5)
    initial = "seher"
    isokay = .true.
    print *, "The value of amount (integer) is:", amount
    print *, "The value of amount (real) is:", pi 
    print *, "The value of amount (complex) is:", frequently
    print *, "The value of amount (character) is:", initial
    print *, "The value of amount (logical) is:", isokay
    print *, "enter radius"
    read(*,*) radius
    
    print *, "enter height"
    read (*,*) height
    area = pi * radius**2
    volumn = area * height
    print *, "calyder area is ", area
    print *, "cylinder volumn is ", volumn

    
end program hello