TEXTDOMAIN:=needrestart

all:
	for po in $(wildcard *.po); do \
	    lang=$$(basename -s .po $$po); \
	    mkdir -p ../.build/$$lang/LC_MESSAGES; \
	    msgfmt -o ../.build/$$lang/LC_MESSAGES/$(TEXTDOMAIN).mo $$po; \
	done

merge:
	for po in $(wildcard *.po); do \
	    msgmerge -U $$po messages.pot; \
	done
