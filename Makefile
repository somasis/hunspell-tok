.DELETE_ON_ERROR:

prefix ?= /usr/local
datadir ?= ${prefix}/share
dictdir ?= ${datadir}/hunspell
bdicdir ?= ${datadir}/qt/qtwebengine_dictionaries

linku ?= https://linku.la/jasima/data.json

dev: data.json all

all: tok.dic

linku.json:
	curl -Lf -o linku.json ${linku}

data.json: linku.json filter_linku.jq
data.json: augment.json augment_languages.json augment_names.json augment_places.json augment_transliterations.json
	jq -s '.[0] * .[1] * .[2] * .[3] * .[4]' \
	    ./linku.json \
	    ./augment.json \
	    ./augment_languages.json \
	    ./augment_names.json \
	    ./augment_places.json \
	    ./augment_transliterations.json \
	    | jq -cf ./filter_linku.jq > data.json

tok.dic: data.json generate_dic.jq
	jq -rf ./generate_dic.jq < data.json > tok.dic

tok.bdic: tok.aff tok.dic
	qwebengine_convert_dict tok.aff tok.bdic

dist: clean dev
	tag=$$(git rev-list --count --since=yesterday --until=tomorrow HEAD | wc -l); \
	[ "$$tag" -gt 1 ] && tag=".$$tag" || tag=; \
	tag="$$(date +%Y%m%d)$$tag"; \
	git tag -fs "$$tag"; \
	git archive \
	    --format=tar \
	    --prefix="hunspell-tok-$$tag"/ \
	    --add-file=./tok.dic \
	    HEAD \
	    | gzip -9 > "hunspell-tok-$$tag".tar.gz

clean:
	rm -f tok.bdic tok.dic linku.json data.json

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
