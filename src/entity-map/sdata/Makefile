SHELL= /bin/sh
SDATAFILES= \
 ISOlat1 ISOlat1.2ab ISOlat1.2as ISOlat1.2html ISOlat1.2l1b ISOlat1.2tex \
 ISOlat2 ISOlat2.2ab ISOlat2.2as ISOlat2.2rtf ISOlat2.2tex ISOlat2.2texi \
 ISOdia ISOdia.2ab ISOdia.2as ISOdia.2html ISOdia.2tex ISOdia.2tr \
 ISOnum ISOnum.2ab ISOnum.2as ISOnum.2html ISOnum.2l1b ISOnum.2l1s ISOnum.2rtf \
 ISOnum.2tex ISOnum.2texi ISOnum.2tr ISOnum.2l1tr \
 ISOpub ISOpub.2ab ISOpub.2as ISOpub.2html ISOpub.2l1b ISOpub.2rtf ISOpub.2l1s \
 ISOpub.2tex ISOpub.2texi ISOpub.2tr \
 ISOtech ISOtech.2ab ISOtech.2as ISOtech.2html ISOtech.2l1b ISOtech.2l1s \
 ISOtech.2rtf ISOtech.2tex ISOtech.2texi ISOtech.2tr \
 GFextra.2ab  GFextra.2as  GFextra.2tex   GFextra.2texi \
 LDextra.2tex LDextra.2tr LDextra.2html \
 greek.2html lat1.2sdata

install: 
	if [ ! -d $(LIBDIR) ]; then \
	  $(MKDIR) $(LIBDIR); \
	  chmod $(PERM_D) $(LIBDIR); \
	fi
	$(CP) $(SDATAFILES) $(LIBDIR)
	(cd $(LIBDIR); chmod $(PERM_F) $(SDATAFILES))
	(cd $(LIBDIR); \
	 rm -f ISOlat1.2rtf ISOlat1.2texi ISOlat1.2tr ISOlat1.2l1s ISOlat1.2l1tr \
	       ISOlat2.2l1b ISOlat2.2l1s \
	       ISOdia.2rtf ISOdia.2texi ISOdia.2l1b ISOdia.2l1s ISOdia.2l1tr \
	       ISOpub.2l1tr \
	       ISOtech.2l1tr \
	       GFextra.2l1b GFextra.2rtf \
	       LDextra.2l1tr; \
	ln -s ISOlat1.2ab ISOlat1.2rtf; \
	ln -s ISOlat1.2ab ISOlat1.2texi; \
	ln -s ISOlat1.2ab ISOlat1.2tr; \
	ln -s ISOlat1.2l1b ISOlat1.2l1s; \
	ln -s ISOlat1.2l1b ISOlat1.2l1tr; \
	ln -s ISOlat2.2ab ISOlat2.2l1b; \
	ln -s ISOlat2.2as ISOlat2.2l1s; \
	ln -s ISOdia.2ab ISOdia.2rtf; \
	ln -s ISOdia.2ab ISOdia.2texi; \
	ln -s ISOdia.2ab ISOdia.2l1b; \
	ln -s ISOdia.2as ISOdia.2l1s; \
	ln -s ISOdia.2tr ISOdia.2l1tr; \
	ln -s ISOpub.2tr ISOpub.2l1tr; \
	ln -s ISOtech.2tr ISOtech.2l1tr; \
	ln -s GFextra.2ab GFextra.2l1b; \
	ln -s GFextra.2ab GFextra.2rtf; \
	ln -s GFextra.2as GFextra.2l1s; \
	ln -s LDextra.2tr LDextra.2l1tr;)

clean:
	${RM} *~
