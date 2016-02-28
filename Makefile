all:
	cd perl && perl Makefile.PL PREFIX=$(PREFIX) INSTALLDIRS=vendor 
	cd perl && $(MAKE)

install: all
	cd perl && $(MAKE) install
	
	mkdir -p "$(DESTDIR)/etc/needrestart/hook.d"
	cp hooks/* "$(DESTDIR)/etc/needrestart/hook.d/"
	cp ex/needrestart.conf "$(DESTDIR)/etc/needrestart/"
	cp ex/notify.conf "$(DESTDIR)/etc/needrestart/"
	mkdir -p "$(DESTDIR)/etc/needrestart/conf.d"
	cp ex/conf.d/* "$(DESTDIR)/etc/needrestart/conf.d/"
	mkdir -p "$(DESTDIR)/etc/needrestart/notify.d"
	cp ex/notify.d/* "$(DESTDIR)/etc/needrestart/notify.d/"
	
	which apt-get > /dev/null && \
	    mkdir -p "$(DESTDIR)/etc/apt/apt.conf.d" && cp ex/apt/needrestart-apt_d "$(DESTDIR)/etc/apt/apt.conf.d/99needrestart" && \
	    mkdir -p "$(DESTDIR)/etc/dpkg/dpkg.cfg.d" && cp ex/apt/needrestart-dpkg_d "$(DESTDIR)/etc/dpkg/dpkg.cfg.d/needrestart" && \
	    mkdir -p "$(DESTDIR)/usr/lib/needrestart" && cp ex/apt/dpkg-status ex/apt/apt-pinvoke "$(DESTDIR)/usr/lib/needrestart" || true
	
	which debconf > /dev/null && \
	    mkdir -p "$(DESTDIR)/usr/share/needrestart" && \
	    po2debconf ex/debconf/needrestart.templates > "$(DESTDIR)/usr/share/needrestart/needrestart.templates" || true
	
	mkdir -p "$(DESTDIR)/usr/share/polkit-1/actions"
	cp ex/polkit/net.fiasko-nw.needrestart.policy "$(DESTDIR)/usr/share/polkit-1/actions/"
	
	mkdir -p "$(DESTDIR)/usr/sbin"
	cp needrestart "$(DESTDIR)/usr/sbin/"
	
	mkdir -p "$(DESTDIR)/usr/lib/needrestart"
	cp lib/vmlinuz-get-version "$(DESTDIR)/usr/lib/needrestart/"
	cp lib/notify.d.sh "$(DESTDIR)/usr/lib/needrestart/"

clean:
	[ ! -f perl/Makefile ] || ( cd perl && $(MAKE) realclean ) 

pot: po/messages.pot

po/messages.pot: needrestart
	xgettext -o po/messages.pot --msgid-bugs-address=thomas@fiasko-nw.net \
	     --package-name=needrestart --package-version=2.7 \
	    --keyword --keyword='$$__' --keyword=__ --keyword=__x \
	    --keyword=__n:1,2 --keyword=__nx:1,2 --keyword=__xn \
	    --keyword=N__ --language=perl needrestart
