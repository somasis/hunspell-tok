prefix ?= /usr/local
datadir ?= ${prefix}/share
dictdir ?= ${datadir}/hunspell
bdicdir ?= ${datadir}/qt/qtwebengine_dictionaries

all:

tok.bdic: tok.aff tok.dic
	qwebengine_convert_dict tok.aff tok.bdic

bdic: tok.bdic

install: tok.aff tok.dic
	install -d ${DESTDIR}${dictdir}
	install -m 0644 ./tok.aff ${DESTDIR}${dictdir}
	install -m 0644 ./tok.dic ${DESTDIR}${dictdir}

install-bdic: tok.bdic
	install -d ${DESTDIR}${bdicdir}
	install -m 0644 ./tok.bdic ${DESTDIR}${bdicdir}

uninstall:
	rm -f ${DESTDIR}${dictdir}/tok.aff
	rm -f ${DESTDIR}${dictdir}/tok.dic

uninstall-bdic:
	rm -f ${DESTDIR}${bdicdir}/tok.bdic
