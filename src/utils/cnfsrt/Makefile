include ../../make.inc

GLBLIB  = ../../lib
GLBBIN  = ../../../bin

OBJS    = cnf_srt_main_final.o
EXE	= cnfsrt
INCS	= -I ../../common/inc
INCS   += -I ./inc
ifeq ($(FCOMP),gfortran)
MOD     = -J ./inc
else ifeq ($(FCOMP),ifort)
MOD     = -module ./inc
endif

CNFSRTLIBS = -L$(GLBLIB) -lcmn

all : makeinc cmnobjs CNFSRT

makeinc:
	if [ ! -d "./inc" ];then     \
                mkdir ./inc;         \
	fi

CNFSRT:	$(OBJS)
	$(COMP) $(GLBFLGS) $(GLBINCS) $(INCS) $(OBJS) -o $(EXE) $(CNFSRTLIBS) $(GLBLIBS)
	if [ ! -d "$(GLBBIN)" ];then     \
                mkdir $(GLBBIN);         \
        fi
#	$(MV) $(EXE) $(GLBBIN)

$(OBJS): %.o: %.$(FEXT)
	$(ECHO) compiling $< using $(COMP)
	$(COMP) $(GLBFLGS) $(GLBINCS) $(INCS) $(MOD) -c $< -o $@

cmnobjs : force_look
	$(ECHO) looking into common : $(MAKE) $(MFLAGS)
	cd ../../common; $(MAKE) $(MFLAGS)

clean :
	$(ECHO) cleaning up in CRRFCN
	$(RM) -f $(OBJS) $(GLBBIN)/crrfcn

force_look :
	true
