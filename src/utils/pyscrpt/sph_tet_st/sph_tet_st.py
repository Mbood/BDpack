"""
Script to generate the initial configuration of polymers tethered to a sphere
for use in BDpack

Output files: q.st.dat, CoM.st.dat, rfin.st.dat

Written by: Tiras Y. Lin
Date: 7/13/18
"""

import numpy as np
import math
import sys

#reading in user inputs
mode = input("[1] Random (1 config) \n[2] Random (ensemble config) \n[3] Random (ensemble config with min distance) \n[4] Ideal \nYour selection: ")

if (mode == 1) or (mode == 2) or (mode == 3):
    nchain_pp = input("Number of chains per particle (nchain_pp): ")
elif mode == 4:
    shape = input("Platonic solid (1-5): ")
    if shape == 1:
        nchain_pp = 4
    elif shape == 2:
        nchain_pp = 6
    elif shape == 3:
        nchain_pp = 8
    elif shape == 4:
        nchain_pp = 12
    elif shape == 5:
        nchain_pp = 20
    else:
        print('There are only 5 platonic solids! :(')
        sys.exit()
else:
    print 'not an option :('
    sys.exit()

if (mode == 3):
    min_ang = input("Minimum angle: ")

nchain = input("Number of particles (nchain): ")
#nchain_pp = input("Number of chains per particle (nchain_pp): ")
nseg_ind = input("Number of segments per individual chain (nseg_ind): ")
a = input("Bead radius (a): ")
a_sph = input("Core sphere radius (a_sph): ")

#calculate chain properties
nseg = nseg_ind * nchain_pp
nbead_ind = nseg_ind+1
nbead = nbead_ind * nchain_pp

#printing out the user inputs
print '\n---------------------'
print 'Initial condition:'
print 'mode =      ', mode
print 'nchain =    ',nchain
print 'nchain_pp = ', nchain_pp
print 'nseg =      ', nseg
print 'nbead =     ', nbead
print 'nseg_ind =  ', nseg_ind
print 'nbead_ind = ', nbead_ind
print 'a =         ', a
print 'a_sph =     ', a_sph
print '---------------------'

#opening the output files
qst_file = open("q.st.dat","w")
CoMst_file = open("CoM.st.dat","w")
rfinst_file = open("rfin.st.dat","w")

#initialize numpy arrays
qstart = np.zeros((3,nseg_ind,nchain,nchain_pp))
rcmstart = np.zeros((3,nchain,nchain_pp))
rf_in = np.zeros((3,nchain,nchain_pp))
rf_in_unit = np.zeros((3,nchain,nchain_pp))
r_curr = np.zeros((3))

#first generate random points on the sphere of radius a+a_sph
if mode == 1:
    #first generate random tether points for first chain
    ichain = 0
    for ichain_pp in xrange(0,nchain_pp):
        x = np.zeros((3))
        #to ensure that no divisions by a number that is v small will occur
        #while ((np.linalg.norm(x) < .0001) or (x[2]>=0)):
        while np.linalg.norm(x) < .0001:
            x = np.random.normal(0,1,3)
        rf_in_unit[:,ichain,ichain_pp] = (x/np.linalg.norm(x))
        rf_in[:,ichain,ichain_pp] = rf_in_unit[:,ichain,ichain_pp] * (a+a_sph)
        np.savetxt(rfinst_file,rf_in[:,ichain,ichain_pp],delimiter=' ',newline=' ', fmt='%1.10f')
        rfinst_file.write('\n')
    #copy first set of random points nchain-1 times
    for ichain in xrange(1,nchain):
        for ichain_pp in xrange(0,nchain_pp):
            rf_in_unit[:,ichain,ichain_pp] = rf_in_unit[:,0,ichain_pp]
            rf_in[:,ichain,ichain_pp] = rf_in[:,0,ichain_pp]
            np.savetxt(rfinst_file,rf_in[:,ichain,ichain_pp],delimiter=' ',newline=' ', fmt='%1.10f')
            rfinst_file.write('\n')
elif mode == 2:
    for ichain in xrange(0,nchain):
        for ichain_pp in xrange(0,nchain_pp):
            x = np.zeros((3))
            #to ensure that no divisions by a number that is v small will occur
            #while ((np.linalg.norm(x) < .0001) or (x[2]>=0)):
            while np.linalg.norm(x) < .0001:
                x = np.random.normal(0,1,3)
            rf_in_unit[:,ichain,ichain_pp] = (x/np.linalg.norm(x))
            rf_in[:,ichain,ichain_pp] = rf_in_unit[:,ichain,ichain_pp] * (a+a_sph)
            np.savetxt(rfinst_file,rf_in[:,ichain,ichain_pp],delimiter=' ',newline=' ', fmt='%1.10f')
            rfinst_file.write('\n')
elif mode == 3:
    for ichain in xrange(0,nchain):
        for ichain_pp in xrange(0,nchain_pp):
            #print 'ichain_pp is ',ichain_pp

            #to ensure that no divisions by a number that is v small will occur

            accept = False
            while accept == False:
                accept = True
                x = np.zeros((3))
                while np.linalg.norm(x) < .0001:
                    x = np.random.normal(0,1,3)
                rf_in_unit[:,ichain,ichain_pp] = (x/np.linalg.norm(x))
                for jchain_pp in xrange(0,ichain_pp):
                    #print 'jchain_pp is ',jchain_pp
                    if (math.acos(np.dot(rf_in_unit[:,ichain,ichain_pp],rf_in_unit[:,ichain,jchain_pp]))<min_ang):
                        accept = False
            rf_in[:,ichain,ichain_pp] = rf_in_unit[:,ichain,ichain_pp] * (a+a_sph)
            np.savetxt(rfinst_file,rf_in[:,ichain,ichain_pp],delimiter=' ',newline=' ', fmt='%1.10f')
            rfinst_file.write('\n')
elif mode == 4:
    gr = (1+math.sqrt(5))/2
    for ichain in xrange(0,nchain):
        if shape == 1:
            rf_in_unit[:,ichain,0] = np.array([1,1,1])
            rf_in_unit[:,ichain,1] = np.array([1, -1, -1])
            rf_in_unit[:,ichain,2] = np.array([-1, 1, -1])
            rf_in_unit[:,ichain,3] = np.array([-1, -1, 1])
        elif shape == 2:
            rf_in_unit[:,ichain,0] = np.array([1, 0, 0])
            rf_in_unit[:,ichain,1] = np.array([-1, 0, 0])
            rf_in_unit[:,ichain,2] = np.array([0, 1, 0])
            rf_in_unit[:,ichain,3] = np.array([0, -1, 0])
            rf_in_unit[:,ichain,4] = np.array([0, 0, 1])
            rf_in_unit[:,ichain,5] = np.array([0, 0, -1])
        elif shape == 3:
            rf_in_unit[:,ichain,0] = np.array([1, 1, 1])
            rf_in_unit[:,ichain,1] = np.array([1, 1, -1])
            rf_in_unit[:,ichain,2] = np.array([1, -1, 1])
            rf_in_unit[:,ichain,3] = np.array([-1, 1, 1])
            rf_in_unit[:,ichain,4] = np.array([-1, -1, 1])
            rf_in_unit[:,ichain,5] = np.array([-1, 1, -1])
            rf_in_unit[:,ichain,6] = np.array([1, -1, -1])
            rf_in_unit[:,ichain,7] = np.array([-1, -1, -1])
        elif shape == 4:
            rf_in_unit[:,ichain,0] = np.array([0, 1, gr])
            rf_in_unit[:,ichain,1] = np.array([0, -1, gr])
            rf_in_unit[:,ichain,2] = np.array([0, 1, -gr])
            rf_in_unit[:,ichain,3] = np.array([0, -1, -gr])
            rf_in_unit[:,ichain,4] = np.array([1, gr, 0])
            rf_in_unit[:,ichain,5] = np.array([-1, gr, 0])
            rf_in_unit[:,ichain,6] = np.array([1, -gr, 0])
            rf_in_unit[:,ichain,7] = np.array([-1, -gr, 0])
            rf_in_unit[:,ichain,8] = np.array([gr, 0, 1])
            rf_in_unit[:,ichain,9] = np.array([gr, 0, -1])
            rf_in_unit[:,ichain,10] = np.array([-gr, 0, 1])
            rf_in_unit[:,ichain,11] = np.array([-gr, 0, -1])
        elif shape == 5:
            rf_in_unit[:,ichain,0] = np.array([1, 1, 1])
            rf_in_unit[:,ichain,1] = np.array([1, 1, -1])
            rf_in_unit[:,ichain,2] = np.array([1, -1, 1])
            rf_in_unit[:,ichain,3] = np.array([-1, 1, 1])
            rf_in_unit[:,ichain,4] = np.array([-1, -1, 1])
            rf_in_unit[:,ichain,5] = np.array([-1, 1, -1])
            rf_in_unit[:,ichain,6] = np.array([1, -1, -1])
            rf_in_unit[:,ichain,7] = np.array([-1, -1, -1])
            rf_in_unit[:,ichain,8] = np.array([0, 1/gr, gr])
            rf_in_unit[:,ichain,9] = np.array([0, -1/gr, gr])
            rf_in_unit[:,ichain,10] = np.array([0, 1/gr, -gr])
            rf_in_unit[:,ichain,11] = np.array([0, -1/gr, -gr])
            rf_in_unit[:,ichain,12] = np.array([1/gr, gr, 0])
            rf_in_unit[:,ichain,13] = np.array([-1/gr, gr, 0])
            rf_in_unit[:,ichain,14] = np.array([1/gr, -gr, 0])
            rf_in_unit[:,ichain,15] = np.array([-1/gr, -gr, 0])
            rf_in_unit[:,ichain,16] = np.array([gr, 0, 1/gr])
            rf_in_unit[:,ichain,17] = np.array([-gr, 0, 1/gr])
            rf_in_unit[:,ichain,18] = np.array([gr, 0, -1/gr])
            rf_in_unit[:,ichain,19] = np.array([-gr, 0, -1/gr])

        for ichain_pp in xrange(0,nchain_pp):
            rf_in_unit[:,ichain,ichain_pp] = (rf_in_unit[:,ichain,ichain_pp]/np.linalg.norm(rf_in_unit[:,ichain,ichain_pp]))
            rf_in[:,ichain,ichain_pp] = rf_in_unit[:,ichain,ichain_pp] * (a+a_sph)
            np.savetxt(rfinst_file,rf_in[:,ichain,ichain_pp],delimiter=' ',newline=' ', fmt='%1.10f')
            rfinst_file.write('\n')



# print rf_in_unit
# print rf_in
# sys.exit()


#generate spring vector and center of mass
for ichain in xrange(0,nchain):
    for ichain_pp in xrange(0,nchain_pp):

        r_curr = rf_in[:,ichain,ichain_pp].copy()
        rcmstart[:,ichain,ichain_pp] = r_curr[:].copy()

        for iseg in xrange(0,nseg_ind):
            #change to different magnitude of initial spring length if desired
            qstart[:,iseg,ichain,ichain_pp] = 1.0*rf_in_unit[:,ichain,ichain_pp].copy()

            r_curr[:] = r_curr[:] + qstart[:,iseg,ichain,ichain_pp]
            rcmstart[:,ichain,ichain_pp] = rcmstart[:,ichain,ichain_pp]+ r_curr[:]

            np.savetxt(qst_file,qstart[:,iseg,ichain,ichain_pp],delimiter=' ',newline=' ', fmt='%1.10f')
            qst_file.write('\n')

        rcmstart[:,ichain,ichain_pp] = rcmstart[:,ichain,ichain_pp]/nbead_ind
        np.savetxt(CoMst_file,rcmstart[:,ichain,ichain_pp],delimiter=' ',newline=' ', fmt='%1.10f')
        CoMst_file.write('\n')

#closing the output files
qst_file.close()
CoMst_file.close()
rfinst_file.close()
