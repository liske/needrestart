clean:
	

all:
	

install:
	mkdir -p "$(DESTDIR)/etc/needrestart"
	cp needrestart.conf "$(DESTDIR)/etc/needrestart/"
	cp -r hooks "$(DESTDIR)/etc/needrestart/hook.d"
	
	mkdir -p "$(DESTDIR)/usr/sbin"
	cp needrestart "$(DESTDIR)/usr/sbin/"
