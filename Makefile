# GoldenPod makefile

VERSION=$(shell ./puconfig --version|perl -p -e 's/^\D+//; chomp')

ifndef prefix
# This little trick ensures that make install will succeed both for a local
# user and for root. It will also succeed for distro installs as long as
# prefix is set by the builder.
prefix=$(shell perl -e 'if($$< == 0 or $$> == 0) { print "/usr" } else { print "$$ENV{HOME}/.local"}')

# Some additional magic here, what it does is set BINDIR to ~/bin IF we're not
# root AND ~/bin exists, if either of these checks fail, then it falls back to
# the standard $(prefix)/bin. This is also inside ifndef prefix, so if a
# prefix is supplied (for instance meaning this is a packaging), we won't run
# this at all
BINDIR ?= $(shell perl -e 'if(($$< > 0 && $$> > 0) and -e "$$ENV{HOME}/bin") { print "$$ENV{HOME}/bin";exit; } else { print "$(prefix)/bin"}')
endif

BINDIR ?= $(prefix)/bin
DATADIR ?= $(prefix)/share

# Note: manpage.pod gets build into puconfig.1 and embedded into puconfig itself for dists
DISTFILES = cpanfile Makefile puconfig README.md shell-footer.sh shell-header.sh puconfig.1 example

# Install puconfig
install: puconfig.1
	mkdir -p "$(BINDIR)" "$(DATADIR)/puconfig"
	cp puconfig shell-footer.sh shell-header.sh "$(DATADIR)/puconfig/"
	chmod 755 "$(DATADIR)/puconfig/puconfig"
	ln -s "$(DATADIR)/puconfig/puconfig" "$(BINDIR)"
	[ -e puconfig.1 ] && mkdir -p "$(DATADIR)/man/man1" && cp puconfig.1 "$(DATADIR)/man/man1" || true
localinstall:
	mkdir -p "$(BINDIR)"
	ln -sf $(shell pwd)/puconfig $(BINDIR)/
	[ -e puconfig.1 ] && mkdir -p "$(DATADIR)/man/man1" && ln -sf $(shell pwd)/puconfig.1 "$(DATADIR)/man/man1" || true
# Uninstall an installed puconfig
uninstall:
	rm -f "$(BINDIR)/puconfig" "$(DATADIR)/man/man1/puconfig.1"
	rm -rf "$(DATADIR)/puconfig"
# Clean up the tree
clean:
	rm -f `find|egrep '~$$'`
	rm -f puconfig-*.tar.bz2
	rm -rf puconfig-$(VERSION)
	rm -f puconfig.1
	rm -rf /tmp/puconfig.test
# Verify syntax
test:
	@perl -c puconfig
# Create a manpage from the POD
puconfig.1: man
man:
	pod2man --name "puconfig" --center "" --release "puconfig $(VERSION)" ./manpage.pod ./puconfig.1
# Create the tarball
distrib: clean test man
	mkdir -p puconfig-$(VERSION)
	cp $(DISTFILES) ./puconfig-$(VERSION)
	echo '__END__' >> ./puconfig-$(VERSION)/puconfig
	cat manpage.pod >> ./puconfig-$(VERSION)/puconfig
	tar -jcvf puconfig-$(VERSION).tar.bz2 ./puconfig-$(VERSION)
	rm -rf puconfig-$(VERSION)
	rm -f puconfig.1
