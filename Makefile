.DELETE_ON_ERROR:

prefix ?= /usr/local
datadir ?= ${prefix}/share
dictdir ?= ${datadir}/hunspell
bdicdir ?= ${datadir}/qt/qtwebengine_dictionaries

dev: update data.json all

all: tok.dic

update: .gitmodules
	git submodule update --init --remote sona

sona/raw/words.json: .gitmodules
	git submodule sync sona

data.json: sona/raw/words.json filter_linku.jq
data.json: augment.json augment_languages.json augment_names.json augment_places.json augment_transliterations.json
	jq -s '{ words: .[0] } * .[1] * .[2] * .[3] * .[4]' \
	    ./sona/raw/words.json \
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
	-git submodule deinit -f sona
	rm -f tok.bdic tok.dic data.json

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
