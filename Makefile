SHELL=/bin/bash

octothorpe := \#
sq := '
dq := "

otherinputs=Makefile bash_functions base.html.tmpl

quote-sh=$(sq)$(subst $(sq),$(sq)$(dq)$(sq)$(dq)$(sq),$1)$(sq)

contentroot=$(HOME)/public_html/content
renderedroot=$(HOME)/public_html/rendered
stateroot=$(HOME)/public_html/state
urlroot=/~krose
manifestfile=$(stateroot)/manifest.yaml

export contentroot renderedroot stateroot urlroot manifestfile

all_md=$(shell find $(contentroot) -name '*.md' | sort)
all_html=$(patsubst $(contentroot)/%.md,$(renderedroot)/%.html,$(all_md))

all: $(manifestfile) $(all_html)

index: $(manifestfile)

define TMP_RENAME
if [ ! -e $(call quote-sh,$@) ] || ! diff -q $(call quote-sh,$@).tmp $(call quote-sh,$@); then \
	mv -f $(call quote-sh,$@).tmp $(call quote-sh,$@); \
else \
	printf '%s\n' "$(@F) unchanged"; \
	rm -f $(call quote-sh,$@).tmp; \
	touch $(call quote-sh,$@); \
fi
endef

$(manifestfile): $(all_md) $(otherinputs)
	for md in $(foreach i,$(patsubst $(contentroot)/%,/%,$(filter %.md,$^)),$(call quote-sh,$i)); do \
		printf '%s:\n' "$${md%%.md}"; \
		awk '/^---$$/ { c++; next; }; c == 1 { print "    ", $$0; }; c >1 { exit }' $(call quote-sh,$(contentroot))"$$md"; \
	done >$(call quote-sh,$@).tmp
	@$(TMP_RENAME)

$(all_html): $(manifestfile) $(otherinputs)
$(all_html): $(renderedroot)/%.html: $(contentroot)/%.md
	. bash_functions && mkdir -p $(call quote-sh,$(@D)) && render-html-page >$(call quote-sh,$@).tmp
	@$(TMP_RENAME)

$(all_html): export thispage=$(patsubst $(contentroot)/%.md,/%,$<)

clean:
	-rm -f $(call quote-sh,$(manifestfile)) $(call quote-sh,$(manifestfile)).tmp

# noslashes=$${md//\//}; depth=$$(( $${$(octothorpe)md} - $${$(octothorpe)noslashes} )); \
