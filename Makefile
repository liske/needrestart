clean:
	

all:
	

install:
	mkdir -p "$(DESTDIR)/etc/needrestart"
	cp ex/needrestart.conf "$(DESTDIR)/etc/needrestart/"
	cp -r hooks "$(DESTDIR)/etc/needrestart/hook.d"
	which apt-get > /dev/null && mkdir -p "$(DESTDIR)/etc/apt/apt.conf.d" && cp ex/99needrestart "$(DESTDIR)/etc/apt/apt.conf.d/"
	
	mkdir -p "$(DESTDIR)/usr/sbin"
	cp needrestart "$(DESTDIR)/usr/sbin/"
