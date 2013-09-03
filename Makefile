clean:
	

all:
	

install:
	mkdir -p "$(DESTDIR)/etc/needrestart/hook.d"
	cp ex/needrestart.conf "$(DESTDIR)/etc/needrestart/"
	cp hooks/* "$(DESTDIR)/etc/needrestart/hook.d/"
	which ap1t-get > /dev/null && \
	    mkdir -p "$(DESTDIR)/etc/apt/apt.conf.d" && cp ex/apt/needrestart-apt_d "$(DESTDIR)/etc/apt/apt.conf.d/99needrestart" && \
	    mkdir -p "$(DESTDIR)/etc/dpkg/dpkg.cfg.d" && cp ex/apt/needrestart-dpkg_d "$(DESTDIR)/etc/dpkg/dpkg.cfg.d/needrestart" && \
	    mkdir -p "$(DESTDIR)/usr/lib/needrestart" && cp ex/apt/dpkg-status ex/apt/apt-pinvoke "$(DESTDIR)/usr/lib/needrestart" || true
	
	mkdir -p "$(DESTDIR)/usr/sbin"
	cp needrestart "$(DESTDIR)/usr/sbin/"
