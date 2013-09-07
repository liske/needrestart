SUBDIRS = man perl

AUTOMAKE_OPTIONS = 
	1.9
	dist-bzip2

BUILT_SOURCES = perl

sbin_SCRIPTS = needrestart

install-exec-local:
	[ ! -f perl/Makefile ] || ( cd perl && $(MAKE) install )

clean-local:
	[ ! -f perl/Makefile ] || ( cd perl && $(MAKE) realclean )

perl: perl/Makefile
	cd perl && $(MAKE)

perl/Makefile: perl/Makefile.PL
	cd perl && perl Makefile.PL PREFIX=$(prefix) INSTALLDIRS=vendor

.PHONY: perl
